
import 'package:dio/dio.dart';

import '../models/study_group.dart';

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
}
