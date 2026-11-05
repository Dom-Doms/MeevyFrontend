
import 'package:dio/dio.dart';

import '../services/auth_api_service.dart';
import '../services/token_storage.dart';

/*
 * Coordina autenticazione e gestione dei token.
 *
 * Mantiene l'access token in memoria e delega
 * il salvataggio del refresh token a TokenStorage.
 */
class AuthRepository {
  final AuthApiService _apiService;
  final TokenStorage _tokenStorage;

  String? _accessToken;

  AuthRepository(this._apiService, this._tokenStorage);

  String? get accessToken => _accessToken;

  bool get isAuthenticated => _accessToken != null;

  /*
   * Effettua il login e conserva i token.
   * L'access token viene assegnato soltanto dopo il salvataggio del refresh token.
   */
  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
    );

    await _tokenStorage.saveRefreshToken(response.refreshToken);
    _accessToken = response.accessToken;
  }

  /*
   * Prova a ripristinare la sessione all'avvio.
   *
   * Se il refresh token è scaduto o revocato, elimina le credenziali locali.
   * Gli errori di rete non cancellano la sessione.
   */
  Future<bool> restoreSession() async {
    final refreshToken = await _tokenStorage.readRefreshToken();

    if (refreshToken == null) {
      _accessToken = null;
      return false;
    }

    try {
      final response = await _apiService.refresh(refreshToken);

      // Il refresh token precedente non è più valido.
      await _tokenStorage.saveRefreshToken(response.refreshToken);
      _accessToken = response.accessToken;

      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _tokenStorage.deleteRefreshToken();
        _accessToken = null;
        return false;
      }

      rethrow;
    }
  }

  /*
   * Richiede il logout al backend.
   * Rimuove comunque i token locali anche
   * se la revoca remota non riesce.
   */
  Future<void> logout() async {
    try {
      final refreshToken = await _tokenStorage.readRefreshToken();

      if (refreshToken != null) {
        await _apiService.logout(refreshToken);
      }
    } finally {
      _accessToken = null;
      await _tokenStorage.deleteRefreshToken();
    }
  }
}
