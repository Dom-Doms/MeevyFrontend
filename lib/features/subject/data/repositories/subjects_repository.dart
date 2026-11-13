
import 'package:dio/dio.dart';

import '../models/subject.dart';

/*
 * Recupera le materie dal backend.
 * Utilizza il client Dio autenticato dell'applicazione.
 */
class SubjectsRepository {
  final Dio _dio;

  SubjectsRepository(this._dio);

  Future<List<Subject>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/subject');

    final data = response.data ?? [];

    return data
        .map(
          (item) => Subject.fromJson(
        item as Map<String, dynamic>,
      ),
    )
        .toList();
  }


// Crea una nuova materia personale.
  Future<Subject> create(String name) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/subject',
      data: {'name': name},
    );

    return _parseSubject(response.data);
  }

// Modifica il nome di una materia esistente.
  Future<Subject> update(int subjectId, String name) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/subject/$subjectId',
      data: {'name': name},
    );

    return _parseSubject(response.data);
  }

// Elimina una materia appartenente all'utente.
  Future<void> delete(int subjectId) async {
    await _dio.delete<void>('/subject/$subjectId');
  }

// Converte la risposta del server nel modello Dart.
  Subject _parseSubject(Map<String, dynamic>? data) {
    if (data == null) {
      throw const FormatException(
        'Risposta della materia non valida.',
      );
    }

    return Subject.fromJson(data);
  }

}
