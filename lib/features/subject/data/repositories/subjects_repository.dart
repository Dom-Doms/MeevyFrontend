
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
}
