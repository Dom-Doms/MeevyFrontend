
import 'package:flutter/foundation.dart';

import '../../data/models/group_member.dart';
import '../../data/repositories/groups_repository.dart';


import '../../data/models/group_invitation.dart';
import '../../data/models/group_role.dart';
import '../../data/models/study_group.dart';

import 'group_error_message.dart';


//Gestisce il caricamento dei membri di un gruppo

class GroupMembersViewModel extends ChangeNotifier {
  final GroupsRepository _repository;

  bool _isSaving = false;
  bool _hasLoaded = false;

  String? _actionError;


  StudyGroup _group;

// Notifica il ViewModel principale quando cambia il gruppo.
  final ValueChanged<StudyGroup> _onGroupUpdated;

  int get _groupId => _group.id;


  List<GroupMember> _members = [];
  bool _isLoading = false;
  bool _disposed = false;

  String? _errorMessage;


  GroupMembersViewModel(
      this._repository,
      this._group,
      this._onGroupUpdated,
      );


  bool get isSaving => _isSaving;

  String? get actionError => _actionError;

  GroupRole get myRole => _group.myRole;

// Le azioni sono consentite soltanto con dati caricati.
  bool get _canAct =>
      _hasLoaded &&
          !_disposed &&
          !_isLoading &&
          !_isSaving &&
          _errorMessage == null;

 // questi controlli servono a mostrare le operazioni corrette nell'interfaccia.
// Owner e Moderator possono generare inviti.
  bool get canInvite =>
      _canAct &&
          (myRole == GroupRole.owner ||
              myRole == GroupRole.moderator);

// Solo l'Owner può cambiare il ruolo degli altri membri.
  bool canChangeRole(GroupMember member) {
    return _canAct &&
        myRole == GroupRole.owner &&
        member.role != GroupRole.owner;
  }

// Verifica se il partecipante può essere espulso.
  bool canRemove(GroupMember member) {
    if (!_canAct) return false;

    // Il proprietario non può mai essere espulso.
    if (member.role == GroupRole.owner) {
      return false;
    }

    if (myRole == GroupRole.owner) {
      return true;
    }

    if (myRole == GroupRole.moderator) {
      return member.role == GroupRole.member;
    }

    return false;
  }

// Solo l'Owner può trasferire la proprietà.
  bool canTransferOwnership(GroupMember member) {
    return _canAct &&
        myRole == GroupRole.owner &&
        member.role != GroupRole.owner;
  }


  List<GroupMember> get members =>
      List.unmodifiable(_members);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;


// Carica le informazioni aggiornate e i membri del gruppo.
  Future<void> load() async {
    if (_isLoading || _isSaving || _disposed) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _actionError = null;
    notifyListeners();

    try {
      await _reloadData();
    } catch (error) {
      if (!_disposed) {
        _errorMessage = groupErrorMessage(
          error,
          fallback: 'Impossibile caricare i membri.',
        );
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

// Recupera dal server sia il gruppo sia i partecipanti.
  Future<void> _reloadData() async {
    final group = await _repository.getById(
      _groupId,
    );

    if (_disposed) return;

    _group = group;

    // Aggiorna anche l'elenco principale e la dashboard.
    _onGroupUpdated(group);

    final members = await _repository.getMembers(
      _groupId,
    );

    if (_disposed) return;

    _members = members;
    _hasLoaded = true;
    _errorMessage = null;
  }


/*
 * Esegue un'operazione sui partecipanti.
 * Impedisce operazioni simultanee dalla stessa schermata.
 */
  Future<T?> _execute<T>({
    required Future<T> Function() operation,
    required String fallback,
    bool refreshAfter = false,
  }) async {
    if (!_canAct) return null;

    _isSaving = true;
    _actionError = null;
    notifyListeners();

    try {
      final result = await operation();

      if (_disposed) return result;

      // Dopo una modifica recupera lo stato autorevole.
      if (refreshAfter) {
        try {
          await _reloadData();
        } catch (_) {
          if (!_disposed) {
            _errorMessage =
            'Operazione completata, ma non è stato '
                'possibile aggiornare i dati. Riprova.';
          }
        }
      }

      return result;
    } catch (error) {
      if (!_disposed) {
        _actionError = groupErrorMessage(
          error,
          fallback: fallback,
        );

        // Una modifica fallita potrebbe dipendere da dati
        // non aggiornati o da una risposta persa.
        if (refreshAfter) {
          _errorMessage =
          'Aggiorna i partecipanti prima di riprovare.';
        }
      }

      return null;
    } finally {
      if (!_disposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }


// Genera un nuovo codice di invito.
  Future<GroupInvitation?> createInvitation() {
    if (!canInvite) {
      return Future.value(null);
    }

    return _execute<GroupInvitation>(
      operation: () {
        return _repository.createInvitation(
          _groupId,
        );
      },
      fallback: 'Impossibile generare l’invito.',
    );
  }


// Promuove un membro o revoca il ruolo di moderatore.
  Future<bool> changeRole(
      GroupMember member,
      GroupRole newRole,
      ) async {
    if (!canChangeRole(member) ||
        newRole == GroupRole.owner ||
        newRole == member.role) {
      return false;
    }

    final result = await _execute<bool>(
      operation: () async {
        final updated = await _repository.updateMemberRole(
          groupId: _groupId,
          userId: member.userId,
          role: newRole,
        );

        // Usa il DTO restituito dal server.
        _members = _members.map((item) {
          return item.userId == updated.userId
              ? updated
              : item;
        }).toList();

        return true;
      },
      fallback: 'Impossibile modificare il ruolo.',
      refreshAfter: true,
    );

    return result == true;
  }


// Espelle un partecipante rispettando i permessi.
  Future<bool> removeMember(
      GroupMember member,
      ) async {
    if (!canRemove(member)) return false;

    final result = await _execute<bool>(
      operation: () async {
        await _repository.removeMember(
          groupId: _groupId,
          userId: member.userId,
        );

        _members.removeWhere(
              (item) => item.userId == member.userId,
        );

        // Aggiorna subito il riepilogo della dashboard.
        _updateMembership(
          memberCount: _group.memberCount > 0
              ? _group.memberCount - 1
              : 0,
        );

        return true;
      },
      fallback: 'Impossibile rimuovere il membro.',
      refreshAfter: true,
    );

    return result == true;
  }


// Trasferisce la proprietà a un altro partecipante.
  Future<bool> transferOwnership(
      GroupMember member,
      ) async {
    if (!canTransferOwnership(member)) {
      return false;
    }

    final result = await _execute<bool>(
      operation: () async {
        await _repository.transferOwnership(
          groupId: _groupId,
          newOwnerUserId: member.userId,
        );

        /*
       * Il backend ha confermato il trasferimento.
       * Il precedente Owner diventa MEMBER.
       *
       * Aggiorniamo immediatamente i permessi locali,
       * senza attendere il successivo caricamento.
       */
        _updateMembership(
          role: GroupRole.member,
        );

        _members = _members.map((item) {
          final GroupRole updatedRole;

          if (item.userId == member.userId) {
            updatedRole = GroupRole.owner;
          } else if (item.role == GroupRole.owner) {
            updatedRole = GroupRole.member;
          } else {
            updatedRole = item.role;
          }

          return GroupMember(
            userId: item.userId,
            firstName: item.firstName,
            lastName: item.lastName,
            role: updatedRole,
            joinedAt: item.joinedAt,
          );
        }).toList();

        return true;
      },
      fallback: 'Impossibile trasferire la proprietà.',
      refreshAfter: true,
    );

    return result == true;
  }


/*
 * Aggiorna la rappresentazione locale del gruppo
 * dopo un'operazione confermata dal backend.
 */
  void _updateMembership({
    GroupRole? role,
    int? memberCount,
  }) {
    _group = StudyGroup(
      id: _group.id,
      name: _group.name,
      description: _group.description,
      createdAt: _group.createdAt,
      myRole: role ?? _group.myRole,
      memberCount: memberCount ?? _group.memberCount,
    );

    _onGroupUpdated(_group);
  }


  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
