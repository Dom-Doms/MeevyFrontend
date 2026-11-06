
import 'package:flutter/foundation.dart';

import '../../features/auth/data/repositories/auth_repository.dart';

/*
 * Rappresenta i possibili stati della sessione utente.
 *
 * loading: verifica della sessione in corso.
 * authenticated: utente autenticato.
 * unauthenticated: login necessario.
 * error: impossibile verificare la sessione.
 */
enum SessionStatus {
  loading,
  authenticated,
  unauthenticated,
  error,
  guest,
}

/*
 * Gestisce lo stato di autenticazione dell'applicazione.
 *
 * collega il ripristino della sessione e il logout,
 * delegando la gestione dei token ad AuthRepository.
 */
class SessionViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  SessionStatus _status = SessionStatus.loading;
  //per evitare che ssesionViewModel mantega lo stato autenticato anche dopo il logout
  SessionViewModel(this._authRepository) {
    _authRepository.addListener(_onAuthChanged);
  }

  SessionStatus get status => _status;

  String? _logoutWarning;

  String? get logoutWarning => _logoutWarning;

  /*
   * Verifica se esiste una sessione recuperabile.
   *
   * Un errore di rete non comporta automaticamente
   * il logout: permette invece di riprovare.
   */
  Future<void> initialize() async {
    _setStatus(SessionStatus.loading);

    try {
      final restored = await _authRepository.restoreSession();

      _setStatus(
        restored
            ? SessionStatus.authenticated
            : SessionStatus.unauthenticated,
      );
    } catch (_) {
      _setStatus(SessionStatus.error);
    }
  }

  /*
   * Aggiorna lo stato dopo un login riuscito.
   * I token devono essere già stati salvati
   * da AuthRepository.
   */
  void onLoginSucceeded() {
    if (!_authRepository.isAuthenticated) {
      throw StateError('Nessuna sessione autenticata.');
    }

    _setStatus(SessionStatus.authenticated);
  }

  /*
   * Termina la sessione e aggiorna l'interfaccia.
   *
   * Anche se la revoca remota fallisce, il repository
   * rimuove le credenziali locali.
   */
  Future<void> logout() async {
    _logoutWarning = null;

    try {
      await _authRepository.logout();
    } catch (_) {
      _logoutWarning =
      'Impossibile confermare la revoca della sessione.';
      notifyListeners();
    } finally {
      _setStatus(SessionStatus.unauthenticated);
    }
  }

  // Notifica le schermate soltanto quando cambia lo stato.
  void _setStatus(SessionStatus newStatus) {
    if (_status == newStatus) return;

    _status = newStatus;
    notifyListeners();
  }


  // Aggiorna la sessione quando il repository perde le credenziali.
  void _onAuthChanged() {
    if (_status == SessionStatus.authenticated &&
        !_authRepository.isAuthenticated) {
      _logoutWarning = null;//Così un eventuale avviso di logout precedente non rimane visualizzato dopo un nuovo login.
      _setStatus(SessionStatus.unauthenticated);
    }
  }

  //Per evitare di lasciare un listner registrato quando il ViewModel non viene eliminato
  @override
  void dispose() {
    _authRepository.removeListener(_onAuthChanged);
    super.dispose();
  }

  // Entra nella modalità ospite senza effettuare il login.
  void enterGuestMode() {
    _setStatus(SessionStatus.guest);
  }

  // Esce dalla modalità ospite e torna al login.
  void exitGuestMode() {
    _setStatus(SessionStatus.unauthenticated);
  }
}
