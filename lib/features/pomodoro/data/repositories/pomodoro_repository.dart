
import 'package:dio/dio.dart';

import '../models/pomodoro_session.dart';

/*
 * Gestisce le richieste HTTP relative
 * alle sessioni Pomodoro personali.
 */
class PomodoroRepository {
  final Dio _dio;

  PomodoroRepository(this._dio);

  /*
   * Recupera la sessione corrente.
   *
   * Restituisce null quando il backend risponde 204,
   * cioè quando non esiste una sessione attiva.
   */
  Future<PomodoroSession?> getCurrentSession() async {
    final response = await _dio.get<dynamic>(
      '/pomodoro-personal-sessions/current',
    );




    if (response.statusCode == 204) {
      return null;
    }

    final json = Map<String, dynamic>.from(
      response.data as Map,
    );

    return PomodoroSession.fromJson(json);
  }

  /*
 * Riprende una sessione sospesa manualmente.
 * Il backend restituisce la sessione aggiornata.
 */
  Future<PomodoroSession> resumeSession(int id) async {
    final response = await _dio.post<dynamic>(
      '/pomodoro-personal-sessions/$id/resume',
    );

    final json = Map<String, dynamic>.from(
      response.data as Map,
    );

    return PomodoroSession.fromJson(json);
  }

/*
 * Annulla una sessione.
 * Non contabilizza il tempo di studio.
 */
  Future<void> cancelSession(int id) async {
    await _dio.post<dynamic>(
      '/pomodoro-personal-sessions/$id/cancel',
    );
  }


}
