
import 'package:dio/dio.dart';


import 'dart:typed_data';

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


// Carica un file personale associandolo alla materia.Usa multipart/form-data


  Future<PersonalResource> upload({
    required int subjectId,
    required String filePath,
    required String filename,
  }) async {
    final formData = FormData.fromMap({
      'subjectId': subjectId,
      'file': await MultipartFile.fromFile(
        filePath,
        filename: filename,
      ),
    });

    final response = await _dio.post<Map<String, dynamic>>(
      '/resources',
      data: formData,
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Risposta del caricamento non valida.',
      );
    }

    return PersonalResource.fromJson(data);
  }


/*
 * Scarica il contenuto di un documento personale.
 *
 * Dio utilizza il JWT tramite l'interceptor già configurato.
 * ResponseType.bytes evita di interpretare PDF, immagini
 * o altri file binari come testo o JSON.
 */
  Future<Uint8List> download(int resourceId) async {
    final response = await _dio.get<List<int>>(
      '/resources/$resourceId/download',
      options: Options(
        responseType: ResponseType.bytes,
      ),
    );

    final data = response.data;

    if (data == null || data.isEmpty) {
      throw const FormatException(
        'Il documento scaricato è vuoto.',
      );
    }

    return data is Uint8List
        ? data
        : Uint8List.fromList(data);
  }


}
