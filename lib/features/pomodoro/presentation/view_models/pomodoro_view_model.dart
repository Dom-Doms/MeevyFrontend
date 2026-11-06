
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/pomodoro_session.dart';
import '../../data/repositories/pomodoro_repository.dart';

/*
 * Gestisce lo stato della schermata Pomodoro personale.
 *
 * La View osserva questo ViewModel, mentre le richieste
 * HTTP vengono delegate al Repository.
 */
class PomodoroViewModel extends ChangeNotifier {
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
      _currentSession = await _repository.getCurrentSession();
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
      _currentSession = await action();
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

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
