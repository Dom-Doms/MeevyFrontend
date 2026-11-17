
import 'package:dio/dio.dart';

import '../models/group_message.dart';

/*
 * Gestisce le operazioni REST della chat di gruppo.
 *
 * Utilizza il client Dio già autenticato di Meevy.
 * Non gestisce la connessione WebSocket.
 */
class GroupChatRepository {
  final Dio _dio;

  GroupChatRepository(this._dio);

  /*
   * Recupera la cronologia della chat.
   *
   * beforeId viene utilizzato per caricare i messaggi
   * precedenti senza utilizzare pagine basate su offset.
   *
   * Il backend restituisce i messaggi più recenti prima.
   */
  Future<List<GroupMessage>> getMessages({
    required int groupId,
    int? beforeId,
    int limit = 30,
  }) async {
    if (limit < 1 || limit > 100) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Il limite deve essere compreso tra 1 e 100.',
      );
    }

    if (beforeId != null && beforeId <= 0) {
      throw ArgumentError.value(
        beforeId,
        'beforeId',
        'Deve essere positivo.',
      );
    }

    final response = await _dio.get<List<dynamic>>(
      '/groups/$groupId/messages',
      queryParameters: {
        'limit': limit,
        if (beforeId != null) 'beforeId': beforeId,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Risposta della cronologia non valida.',
      );
    }

    return data.map((item) {
      return GroupMessage.fromJson(
        item as Map<String, dynamic>,
      );
    }).toList();
  }

  /*
   * Invia un messaggio tramite REST.
   *
   * Il mittente è identificato dal JWT sul backend:
   * non dobbiamo inviare senderUserId dal client.
   */
  Future<GroupMessage> sendMessage({
    required int groupId,
    required String content,
  }) async {
    final text = content.trim();

    if (text.isEmpty || text.length > 4000) {
      throw ArgumentError(
        'Il messaggio deve contenere da 1 a 4000 caratteri.',
      );
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/groups/$groupId/messages',
      data: {
        'content': text,
      },
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Risposta dell’invio non valida.',
      );
    }

    return GroupMessage.fromJson(data);
  }
}


