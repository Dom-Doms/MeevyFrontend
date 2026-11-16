
import 'package:dio/dio.dart';

import '../models/checklist_item.dart';

/*
 * Gestisce le API della checklist personale.
 * La logica di appartenenza alla materia resta nel backend.
 */
class ChecklistRepository {
  final Dio _dio;

  ChecklistRepository(this._dio);

  // Recupera l'identificativo della checklist di una materia.
  Future<int> getBySubject(int subjectId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/checklists/subject/$subjectId',
    );

    return response.data!['id'] as int;
  }

  // Crea la checklist per una materia che non ne possiede una.
  Future<int> create(int subjectId) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/checklists',
      data: {'subjectId': subjectId},
    );

    return response.data!['id'] as int;
  }

  // Recupera le attività appartenenti alla checklist.
  Future<List<ChecklistItem>> getItems(int checklistId) async {
    final response = await _dio.get<List<dynamic>>(
      '/checklists/$checklistId/items',
    );

    return (response.data ?? [])
        .map((json) => ChecklistItem.fromJson(
      json as Map<String, dynamic>,
    ))
        .toList();
  }

  Future<ChecklistItem> addItem(
      int checklistId,
      String text,
      ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/checklists/$checklistId/items',
      data: {'text': text},
    );

    return ChecklistItem.fromJson(response.data!);
  }

  Future<ChecklistItem> updateItem(
      int itemId,
      String text,
      ) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/checklists/items/$itemId',
      data: {'text': text},
    );

    return ChecklistItem.fromJson(response.data!);
  }

  Future<ChecklistItem> setCompleted(
      int itemId,
      bool completed,
      ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/checklists/items/$itemId/completed',
      data: {'completed': completed},
    );

    return ChecklistItem.fromJson(response.data!);
  }

  Future<void> deleteItem(int itemId) async {
    await _dio.delete<void>(
      '/checklists/items/$itemId',
    );
  }
}
