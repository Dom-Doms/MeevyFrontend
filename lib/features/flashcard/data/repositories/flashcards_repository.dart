
import 'package:dio/dio.dart';

import '../models/personal_flashcard.dart';

/*
 * Gestisce le API delle flashcard personali.
 */
class FlashcardsRepository {
  final Dio _dio;

  FlashcardsRepository(this._dio);

  // Recupera le flashcard associate alla materia.
  Future<List<PersonalFlashcard>> getBySubject(
      int subjectId,
      ) async {
    final response = await _dio.get<List<dynamic>>(
      '/flashcards/subject/$subjectId',
    );

    return (response.data ?? [])
        .map((json) => PersonalFlashcard.fromJson(
      json as Map<String, dynamic>,
    ))
        .toList();
  }

  Future<PersonalFlashcard> create({
    required int subjectId,
    required String question,
    required String answer,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/flashcards',
      data: {
        'subjectId': subjectId,
        'question': question,
        'answer': answer,
      },
    );

    return PersonalFlashcard.fromJson(response.data!);
  }

  Future<PersonalFlashcard> update({
    required int id,
    required String question,
    required String answer,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/flashcards/$id',
      data: {
        'question': question,
        'answer': answer,
      },
    );

    return PersonalFlashcard.fromJson(response.data!);
  }

  Future<PersonalFlashcard> duplicate(int id) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/flashcards/$id/duplicate',
    );

    return PersonalFlashcard.fromJson(response.data!);
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/flashcards/$id');
  }
}
