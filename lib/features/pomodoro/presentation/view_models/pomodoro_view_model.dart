
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/pomodoro_session.dart';
import '../../data/repositories/pomodoro_repository.dart';

import 'dart:async';
import 'dart:math';

/*
 * Gestisce lo stato della schermata Pomodoro personale.
 *
 * La View osserva questo ViewModel, mentre le richieste
 * HTTP vengono delegate al Repository.
 */
class PomodoroViewModel extends ChangeNotifier {


  // SEZIONE PER IL TIMER DEL POMODORO IN LOCALE (il calcolo)


// Timer usato soltanto per aggiornare l'interfaccia.
  Timer? _ticker;

// Istante in cui abbiamo ricevuto l'ultima risposta del server.
  DateTime? _snapshotAt;

/*
 * Calcola il tempo totale rimanente.
 *
 * Se RUNNING, sottrae il tempo passato dall'ultima
 * sincronizzazione con il backend.
 *
 * In READY o PAUSED, il tempo rimane fermo.
 */
  int get displayRemainingSessionSeconds {
    final session = _currentSession;

    if (session == null) return 0;

    if (session.status != PomodoroStatus.running ||
        _snapshotAt == null) {
      return session.remainingSessionSeconds;
    }

    final elapsed = max(
      0,
      DateTime.now().difference(_snapshotAt!).inSeconds,
    );

    return max(0, session.remainingSessionSeconds - elapsed);
  }

/*
 * Determina se il timer sta mostrando STUDY oppure BREAK.
 */
  PomodoroPhase? get displayPhase {
    final session = _currentSession;

    if (session == null) return null;

    if (session.status != PomodoroStatus.running) {
      return session.phase;
    }

    final remaining = displayRemainingSessionSeconds;

    if (remaining == 0) return null;

    final elapsed = session.targetDurationSeconds - remaining;

    final cycleDuration =
        session.studyDurationSeconds + session.breakDurationSeconds;

    final position = elapsed % cycleDuration;

    return position < session.studyDurationSeconds
        ? PomodoroPhase.study
        : PomodoroPhase.breakTime;
  }

/*
 * Calcola i secondi rimanenti nella fase corrente.
 *
 * La fase non deve superare il tempo totale residuo,
 * come previsto dal calcolatore del backend.
 */
  int get displayRemainingPhaseSeconds {
    final session = _currentSession;

    if (session == null) return 0;

    if (session.status != PomodoroStatus.running) {
      return session.remainingPhaseSeconds;
    }

    final remaining = displayRemainingSessionSeconds;

    if (remaining == 0) return 0;

    final elapsed = session.targetDurationSeconds - remaining;

    final cycleDuration =
        session.studyDurationSeconds + session.breakDurationSeconds;

    final position = elapsed % cycleDuration;

    final phaseRemaining =
    position < session.studyDurationSeconds
        ? session.studyDurationSeconds - position
        : cycleDuration - position;

    return min(phaseRemaining, remaining);
  }
//FINE SEZIONE
  final PomodoroRepository _repository;

  PomodoroViewModel(this._repository);

  PomodoroSession? _currentSession;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  PomodoroSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /*
   * Recupera la sessione corrente dal backend.
   *
   * Se non esiste una sessione attiva, il Repository
   * restituisce null: non è un errore.
   */
  Future<void> loadCurrentSession() async {
    // Evita richieste duplicate mentre una GET è in corso.
    if (_isLoading || _disposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await _repository.getCurrentSession();

      if (_disposed) return;

      _currentSession = session;
      _syncTicker();
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        _errorMessage = 'Sessione non più valida.';
      } else if (error.response == null) {
        _errorMessage = 'Impossibile contattare il server.';
      } else {
        _errorMessage = 'Impossibile caricare il Pomodoro.';
      }
    } catch (_) {
      _errorMessage = 'Errore durante il caricamento.';
    } finally {
      _isLoading = false;

      // La schermata potrebbe essere stata chiusa
      // mentre la richiesta HTTP era ancora in corso.
      if (!_disposed) {
        notifyListeners();
      }
    }
  }

/*
 * Crea una sessione Pomodoro con la configurazione
 * selezionata dall'utente.
 *
 * Non permette di creare una seconda sessione
 * mentre ne esiste già una corrente.
 */
  Future<void> createSession({
    required int subjectId,
    required int studyMinutes,
    required int breakMinutes,
    required int targetMinutes,
  }) async {
    if (_currentSession != null || _isLoading || _disposed) {
      return;
    }

    await _executeAction(
          () => _repository.createSession(
        subjectId: subjectId,
        studyMinutes: studyMinutes,
        breakMinutes: breakMinutes,
        targetMinutes: targetMinutes,
      ),
    );
  }

/*
 * Riprende una sessione PAUSED.
 */
  Future<void> resumeSession() async {
    final session = _currentSession;

    if (session == null ||
        session.status != PomodoroStatus.paused) {
      return;
    }

    await _executeAction(
          () => _repository.resumeSession(session.id),
    );
  }



/*
 * Avvia una sessione configurata ma non ancora iniziata.
 */
  Future<void> startSession() async {
    final session = _currentSession;

    if (session == null ||
        session.status != PomodoroStatus.ready) {
      return;
    }

    await _executeAction(
          () => _repository.startSession(session.id),
    );
  }

/*
 * Mette in pausa una sessione in esecuzione.
 */
  Future<void> pauseSession() async {
    final session = _currentSession;

    if (session == null ||
        session.status != PomodoroStatus.running) {
      return;
    }

    await _executeAction(
          () => _repository.pauseSession(session.id),
    );
  }


/*
 * Annulla una sessione attiva.
 *
 * Dopo l'annullamento torniamo allo stato
 * senza sessione corrente.
 */
  Future<void> cancelSession() async {
    final session = _currentSession;

    if (session == null ||
        session.status == PomodoroStatus.completed ||
        session.status == PomodoroStatus.cancelled) {
      return;
    }

    await _executeAction(() async {
      await _repository.cancelSession(session.id);
      return null;
    });
  }

/*
 * Gestisce le operazioni sul Pomodoro.
 * Evita richieste duplicate e aggiorna la schermata.
 */
  Future<void> _executeAction(
      Future<PomodoroSession?> Function() action,
      ) async {
    if (_isLoading || _disposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final session = await action();

      if (_disposed) return;

      _currentSession = session;
      _syncTicker();
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        _errorMessage = 'Sessione non più valida.';
      } else if (error.response == null) {
        _errorMessage = 'Impossibile contattare il server.';
      } else {
        _errorMessage = 'Operazione non riuscita. Riprova.';
      }
    } catch (_) {
      _errorMessage = 'Errore durante l’operazione.';
    } finally {
      _isLoading = false;

      if (!_disposed) {
        notifyListeners();
      }
    }
  }

  //Sempre per il calcolo del pomodoro il locale

/*
 * Sincronizza il timer locale con l'ultima
 * sessione ricevuta dal backend.
 */
  void _syncTicker() {
    // Ferma un eventuale timer precedente.
    _ticker?.cancel();
    _ticker = null;
    _snapshotAt = null;

    final session = _currentSession;

    // Il countdown funziona soltanto in RUNNING.
    if (_disposed ||
        session == null ||
        session.status != PomodoroStatus.running) {
      return;
    }

    _snapshotAt = DateTime.now();

    _ticker = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (_disposed) return;

        // Il tempo totale è terminato.
        if (displayRemainingSessionSeconds == 0) {
          _ticker?.cancel();
          _ticker = null;

          // Chiediamo al backend di riconciliare
          // l'eventuale completamento della sessione.
          unawaited(loadCurrentSession());
          return;
        }

        // Aggiorna il countdown sullo schermo.
        notifyListeners();
      },
    );
  }



  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    super.dispose();
  }
}
