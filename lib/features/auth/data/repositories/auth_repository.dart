
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/login_response.dart';
import '../services/auth_api_service.dart';
import '../services/token_storage.dart';

/*
 * Gestisce i token e il ciclo di vita dell'autenticazione.
 *
 * L'access token rimane in memoria, mentre il refresh token
 * viene conservato nello storage sicuro del dispositivo.
 */
class AuthRepository extends ChangeNotifier {
  final AuthApiService _apiService;
  final TokenStorage _tokenStorage;

  String? _accessToken;
  DateTime? _expiresAt;
  Future<bool>? _refreshInProgress;
  bool _loggingOut = false;
  int _sessionVersion = 0;

  AuthRepository(this._apiService, this._tokenStorage);

  String? get accessToken => _loggingOut ? null : _accessToken;

  bool get isAuthenticated => accessToken != null;

  int get sessionVersion => _sessionVersion;

  // Autentica l'utente e memorizza i token ricevuti.
  Future<void> login({
    required String email,
    required String password,
  }) async {
    if (_loggingOut) {
      throw StateError('Logout in corso.');
    }

    final response = await _apiService.login(
      email: email,
      password: password,
    );

    _sessionVersion++;
    await _saveSession(response);
  }

  /*
   * Ripristina la sessione quando l'app viene riaperta.
   * Utilizza il refresh token precedentemente salvato.
   */
  Future<bool> restoreSession() {
    return refreshAccessToken();
  }

  /*
   * Controlla la scadenza dell'access token.
   * Se mancano meno di 30 secondi, lo rinnova
   * prima di inviare la richiesta HTTP.
   */
  Future<bool> ensureValidAccessToken() async {
    if (!isAuthenticated) return false;

    final expiration = _expiresAt;

    if (expiration != null &&
        DateTime.now().isBefore(
          expiration.subtract(const Duration(seconds: 30)),
        )) {
      return true;
    }

    return refreshAccessToken();
  }

  /*
   * Evita refresh contemporanei.
   * Le richieste che arrivano durante un rinnovo
   * attendono tutte lo stesso Future.
   */
  Future<bool> refreshAccessToken() {
    if (_loggingOut) return Future.value(false);

    return _refreshInProgress ??=
        _performRefresh().whenComplete(() {
          _refreshInProgress = null;
        });
  }

  // Effettua realmente il rinnovo tramite il backend.
  Future<bool> _performRefresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();

    if (refreshToken == null) {
      _clearAccessToken();
      return false;
    }

    try {
      final response = await _apiService.refresh(refreshToken);

      await _saveSession(response);
      return true;
    } on DioException catch (error) {
      /*
       * Un 401 indica un refresh token non più valido.
       * Un errore di rete, invece, non cancella la sessione.
       */
      if (error.response?.statusCode == 401) {
        _clearAccessToken();
        await _tokenStorage.deleteRefreshToken();
        return false;
      }

      rethrow;
    }
  }

  // Memorizza il nuovo refresh token e aggiorna il JWT.
  Future<void> _saveSession(LoginResponse response) async {
    await _tokenStorage.saveRefreshToken(response.refreshToken);

    _accessToken = response.accessToken;
    _expiresAt = DateTime.now().add(
      Duration(seconds: response.expiresInSeconds),
    );

    notifyListeners();
  }

  /*
   * Revoca il refresh token e termina la sessione.
   * Se esiste un rinnovo in corso, ne attende il termine.
   */
  Future<void> logout() async {
    if (_loggingOut) return;

    _loggingOut = true;
    _sessionVersion++;
    notifyListeners();

    try {
      final pendingRefresh = _refreshInProgress;

      if (pendingRefresh != null) {
        try {
          await pendingRefresh;
        } catch (_) {
          // Il logout deve proseguire anche se il refresh fallisce.
        }
      }

      final refreshToken = await _tokenStorage.readRefreshToken();

      if (refreshToken != null) {
        await _apiService.logout(refreshToken);
      }
    } finally {
      _clearAccessToken();

      try {
        await _tokenStorage.deleteRefreshToken();
      } finally {
        _loggingOut = false;
        notifyListeners();
      }
    }
  }

  // Elimina dalla memoria l'access token corrente.
  void _clearAccessToken() {
    _accessToken = null;
    _expiresAt = null;
    notifyListeners();
  }
}
