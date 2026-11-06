
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:meevy_app/features/auth/data/models/login_response.dart';
import 'package:meevy_app/features/auth/data/services/auth_api_service.dart';
import 'package:meevy_app/features/auth/data/services/token_storage.dart';

// Simula le API di autenticazione senza chiamare il server reale.
class FakeAuthApiService extends AuthApiService {
  FakeAuthApiService() : super(Dio());

  Future<LoginResponse> Function(String email, String password)? onLogin;
  Future<LoginResponse> Function(String token)? onRefresh;
  Future<void> Function(String token)? onLogout;

  int loginCalls = 0;
  int refreshCalls = 0;
  int logoutCalls = 0;

  @override
  Future<LoginResponse> login({
    required String email,
    required String password,
  }) {
    loginCalls++;
    return onLogin!(email, password);
  }

  @override
  Future<LoginResponse> refresh(String refreshToken) {
    refreshCalls++;
    return onRefresh!(refreshToken);
  }

  @override
  Future<void> logout(String refreshToken) async {
    logoutCalls++;

    if (onLogout != null) {
      await onLogout!(refreshToken);
    }
  }
}

// Simula lo storage del telefono usando una variabile in memoria.
class FakeTokenStorage extends TokenStorage {
  FakeTokenStorage({this.storedToken})
      : super(const FlutterSecureStorage());

  String? storedToken;

  @override
  Future<void> saveRefreshToken(String token) async {
    storedToken = token;
  }

  @override
  Future<String?> readRefreshToken() async {
    return storedToken;
  }

  @override
  Future<void> deleteRefreshToken() async {
    storedToken = null;
  }
}

// Crea una risposta di autenticazione configurabile per i test.
LoginResponse fakeLoginResponse({
  String accessToken = 'access-123',
  String refreshToken = 'refresh-123',
  int expiresInSeconds = 3600,
}) {
  return LoginResponse(
    accessToken: accessToken,
    refreshToken: refreshToken,
    tokenType: 'Bearer',
    expiresInSeconds: expiresInSeconds,
  );
}

// Simula una risposta HTTP di errore del backend.
DioException fakeHttpError(int statusCode) {
  final request = RequestOptions(path: '/auth/refresh');

  return DioException(
    requestOptions: request,
    response: Response(
      requestOptions: request,
      statusCode: statusCode,
    ),
  );
}
