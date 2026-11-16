
import 'package:dio/dio.dart';

import '../models/study_group.dart';

import '../models/group_member.dart';


import '../models/group_invitation.dart';
import '../models/group_role.dart';



/*
 * Gestisce l'accesso alle API dei gruppi.
 * Utilizza il client Dio autenticato dell'applicazione.
 */
class GroupsRepository {
  final Dio _dio;

  GroupsRepository(this._dio);

  // Recupera tutti i gruppi dell'utente autenticato.
  Future<List<StudyGroup>> getAll() async {
    final response = await _dio.get<List<dynamic>>(
      '/groups',
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Risposta dei gruppi non valida.',
      );
    }

    return data
        .map(
          (item) => StudyGroup.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

  /*
   * Crea un gruppo.
   * Il backend assegna automaticamente al creatore
   * il ruolo OWNER.
   */
  Future<StudyGroup> create({
    required String name,
    String? description,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups',
      data: {
        'name': name,
        'description': description,
      },
    );

    return _parseGroup(response.data);
  }

  // Recupera le informazioni aggiornate di un gruppo.
  Future<StudyGroup> getById(int groupId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/groups/$groupId',
    );

    return _parseGroup(response.data);
  }

  // Modifica nome e descrizione del gruppo.
  Future<StudyGroup> update({
    required int groupId,
    required String name,
    String? description,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/groups/$groupId',
      data: {
        'name': name,
        'description': description,
      },
    );

    return _parseGroup(response.data);
  }

  // Verifica e converte la risposta del backend.
  StudyGroup _parseGroup(Map<String, dynamic>? data) {
    if (data == null) {
      throw const FormatException(
        'Risposta del gruppo non valida.',
      );
    }

    return StudyGroup.fromJson(data);
  }


// Recupera tutti i membri del gruppo.
  Future<List<GroupMember>> getMembers(int groupId) async {
    final response = await _dio.get<List<dynamic>>(
      '/groups/$groupId/members',
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Risposta dei membri non valida.',
      );
    }

    return data
        .map(
          (item) => GroupMember.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }

// Genera un invito utilizzabile una sola volta.
  Future<GroupInvitation> createInvitation(
      int groupId,
      ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/invitations',
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Risposta dell’invito non valida.',
      );
    }

    return GroupInvitation.fromJson(data);
  }

// Accetta un invito e restituisce il gruppo.
  Future<StudyGroup> acceptInvitation(
      String token,
      ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/group-invitations/accept',
      data: {
        'token': token,
      },
    );

    return _parseGroup(response.data);
  }

// Nomina o revoca un moderatore.
  Future<GroupMember> updateMemberRole({
    required int groupId,
    required int userId,
    required GroupRole role,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/groups/$groupId/members/$userId/role',
      data: {
        'role': role.name.toUpperCase(),
      },
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Risposta del membro non valida.',
      );
    }

    return GroupMember.fromJson(data);
  }

// Espelle un partecipante dal gruppo.
  Future<void> removeMember({
    required int groupId,
    required int userId,
  }) async {
    await _dio.delete<void>(
      '/groups/$groupId/members/$userId',
    );
  }

// Trasferisce la proprietà del gruppo.
  Future<void> transferOwnership({
    required int groupId,
    required int newOwnerUserId,
  }) async {
    await _dio.patch<void>(
      '/groups/$groupId/owner',
      data: {
        'newOwnerUserId': newOwnerUserId,
      },
    );
  }

// Abbandona il gruppo come utente corrente.
  Future<void> leaveGroup(int groupId) async {
    await _dio.post<void>(
      '/groups/$groupId/leave',
    );
  }


}
