
import 'package:dio/dio.dart';

import '../models/personal_resource.dart';

/*
 * Gestisce le API relative ai file personali.
 * Utilizza il client HTTP autenticato di Meevy.
 */
class ResourcesRepository {
  final Dio _dio;

  ResourcesRepository(this._dio);

  // Recupera esclusivamente i file della materia indicata.
  Future<List<PersonalResource>> getBySubject(
      int subjectId,
      ) async {
    final response = await _dio.get<List<dynamic>>(
      '/resources',
      queryParameters: {
        'subjectId': subjectId,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Risposta degli appunti non valida.',
      );
    }

    return data.map((item) {
      return PersonalResource.fromJson(
        item as Map<String, dynamic>,
      );
    }).toList();
  }
}
