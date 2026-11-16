
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';


import 'group_error_message.dart';


import '../../data/models/study_group.dart';
import '../../data/repositories/groups_repository.dart';

/*
 * Gestisce lo stato dei gruppi dell'utente:
 * caricamento, creazione, modifica ed errori.
 */
class GroupsViewModel extends ChangeNotifier {
  final GroupsRepository _repository;

  List<StudyGroup> _groups = [];

  bool _isLoading = false;
  bool _isSaving = false;
  bool _disposed = false;

  String? _errorMessage;
  String? _saveError;

  GroupsViewModel(this._repository);

  List<StudyGroup> get groups => List.unmodifiable(_groups);

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;
  String? get saveError => _saveError;

  // Cerca un gruppo nell'elenco già caricato.
  StudyGroup? findById(int id) {
    for (final group in _groups) {
      if (group.id == id) {
        return group;
      }
    }

    return null;
  }

  // Carica i gruppi dell'utente dal backend.
  Future<void> load() async {
    if (_isLoading || _isSaving || _disposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAll();

      if (_disposed) return;

      _groups = result;
    } on DioException {
      if (_disposed) return;

      _errorMessage = 'Impossibile caricare i gruppi.';
    } catch (_) {
      if (_disposed) return;

      _errorMessage = 'Risposta del server non valida.';
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /*
   * Crea un nuovo gruppo oppure modifica quello esistente.
   * Aggiorna l'elenco soltanto dopo la conferma del server.
   */
  Future<StudyGroup?> save({
    int? groupId,
    required String name,
    String? description,
  }) async {
    if (_isSaving || _isLoading || _disposed) {
      return null;
    }

    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      final StudyGroup result;

      if (groupId == null) {
        result = await _repository.create(
          name: name,
          description: description,
        );
      } else {
        result = await _repository.update(
          groupId: groupId,
          name: name,
          description: description,
        );
      }

      if (_disposed) return null;

      // Inserisce il nuovo gruppo o aggiorna quello esistente.
      _upsertGroup(result);

      return result;
    } on DioException catch (error) {
      if (_disposed) return null;

      if (error.response?.statusCode == 403) {
        _saveError = 'Non hai i permessi necessari.';
      } else if (error.response?.statusCode == 400) {
        _saveError = 'Controlla i dati inseriti.';
      } else {
        _saveError = 'Impossibile salvare il gruppo.';
      }

      return null;
    } catch (_) {
      if (!_disposed) {
        _saveError = 'Si è verificato un errore.';
      }

      return null;
    } finally {
      if (!_disposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }


// Accetta un invito e aggiunge il gruppo all'elenco.
  Future<StudyGroup?> acceptInvitation(
      String token,
      ) {
    return _performGroupAction<StudyGroup>(
      request: () => _repository.acceptInvitation(token),
      onSuccess: _upsertGroup,
      fallback: 'Impossibile accettare l’invito.',
    );
  }

// Abbandona il gruppo e lo rimuove dall'elenco.
  Future<bool> leaveGroup(int groupId) async {
    final result = await _performGroupAction<bool>(
      request: () async {
        await _repository.leaveGroup(groupId);
        return true;
      },
      onSuccess: (_) {
        _groups.removeWhere(
              (group) => group.id == groupId,
        );
      },
      fallback: 'Impossibile abbandonare il gruppo.',
    );

    return result == true;
  }

/*
 * Esegue un'operazione sui gruppi gestendo
 * salvataggio, errori e aggiornamento dell'interfaccia.
 */
  Future<T?> _performGroupAction<T>({
    required Future<T> Function() request,
    required void Function(T) onSuccess,
    required String fallback,
  }) async {
    if (_isSaving || _isLoading || _disposed) {
      return null;
    }

    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      final result = await request();

      if (_disposed) return null;

      onSuccess(result);

      return result;
    } catch (error) {
      if (!_disposed) {
        _saveError = groupErrorMessage(
          error,
          fallback: fallback,
        );
      }

      return null;
    } finally {
      if (!_disposed) {
        _isSaving = false;
        notifyListeners();
      }
    }
  }



// Inserisce o aggiorna un gruppo nell'elenco locale.
  void _upsertGroup(StudyGroup group) {
    final index = _groups.indexWhere(
          (item) => item.id == group.id,
    );

    if (index == -1) {
      _groups.add(group);
    } else {
      _groups[index] = group;
    }
  }

/*
 * Aggiorna un gruppo già presente nell'elenco
 * usando le informazioni ottenute dal ViewModel dei membri.
 */
  void syncGroup(StudyGroup group) {
    if (_disposed) return;

    final index = _groups.indexWhere(
          (item) => item.id == group.id,
    );

    // Non reinserisce gruppi eventualmente abbandonati.
    if (index == -1) return;

    _groups[index] = group;

    notifyListeners();
  }


  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
