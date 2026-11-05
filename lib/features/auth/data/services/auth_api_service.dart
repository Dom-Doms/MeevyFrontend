
import 'package:dio/dio.dart';

import '../models/login_response.dart';

/*
 * Gestisce le richieste HTTP per l'autenticazione.
 * Non conserva i token e non gestisce le schermate.
 */
class AuthApiService {
  final Dio _dio;

  AuthApiService(this._dio);

  // Autentica l'utente e restituisce i token ricevuti.
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );

    final json = response.data;
    if (json == null) {
      throw const FormatException('Risposta di login vuota.');
    }

    return LoginResponse.fromJson(json);
  }

  /*
   * Rinnova la sessione.
   * Il backend invalida il vecchio refresh token
   * e ne restituisce uno nuovo.
   */
  Future<LoginResponse> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final json = response.data;
    if (json == null) {
      throw const FormatException('Risposta di refresh vuota.');
    }

    return LoginResponse.fromJson(json);
  }

  // Chiede al backend di revocare il refresh token.
  Future<void> logout(String refreshToken) async {
    await _dio.post<void>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }
}
