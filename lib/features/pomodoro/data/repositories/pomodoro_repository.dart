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

    final json = Map<String, dynamic>.from(response.data as Map);

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

    final json = Map<String, dynamic>.from(response.data as Map);

    return PomodoroSession.fromJson(json);
  }

  /*
 * Avvia una sessione in stato READY.
 */
  Future<PomodoroSession> startSession(int id) async {
    final response = await _dio.post<dynamic>(
      '/pomodoro-personal-sessions/$id/start',
    );

    return PomodoroSession.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /*
 * Sospende manualmente una sessione RUNNING.
 */
  Future<PomodoroSession> pauseSession(int id) async {
    final response = await _dio.post<dynamic>(
      '/pomodoro-personal-sessions/$id/pause',
    );

    return PomodoroSession.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /*
 * Crea una nuova sessione Pomodoro personale.
 *
 * Le durate vengono ricevute in minuti dalla UI
 * e convertite in secondi per il backend.
 *
 * La sessione viene creata nello stato READY.
 */
  Future<PomodoroSession> createSession({
    required int subjectId,
    required int studyMinutes,
    required int breakMinutes,
    required int targetMinutes,
  }) async {
    final response = await _dio.post<dynamic>(
      '/pomodoro-personal-sessions',
      data: {
        'subjectId': subjectId,
        'studyDurationSeconds': studyMinutes * 60,
        'breakDurationSeconds': breakMinutes * 60,
        'targetDurationSeconds': targetMinutes * 60,
      },
    );

    final json = Map<String, dynamic>.from(response.data as Map);

    return PomodoroSession.fromJson(json);
  }

  /*
 * Annulla una sessione.
 * Non contabilizza il tempo di studio.
 */
  Future<void> cancelSession(int id) async {
    await _dio.post<dynamic>('/pomodoro-personal-sessions/$id/cancel');
  }
}
