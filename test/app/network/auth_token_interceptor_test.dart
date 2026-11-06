
import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meevy_app/app/network/auth_token_interceptor.dart';
import 'package:meevy_app/features/auth/data/repositories/auth_repository.dart';

import '../../support/auth_fakes.dart';

/*
 * Simula il trasporto HTTP di Dio.
 * Registra le richieste e restituisce risposte controllate.
 */
class FakeHttpAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions request) respond;

  final List<RequestOptions> requests = [];

  FakeHttpAdapter(this.respond);

  @override
  Future<ResponseBody> fetch(
      RequestOptions options,
      Stream<Uint8List>? requestStream,
      Future<void>? cancelFuture,
      ) async {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {}
}

// Crea una risposta HTTP con un corpo JSON.
ResponseBody httpResponse(int statusCode) {
  return ResponseBody.fromString(
    '{"ok":true}',
    statusCode,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
}

void main() {
  late FakeAuthApiService apiService;
  late FakeTokenStorage tokenStorage;
  late AuthRepository authRepository;
  late Dio dio;
  late FakeHttpAdapter adapter;

  setUp(() {
    apiService = FakeAuthApiService();
    tokenStorage = FakeTokenStorage();

    authRepository = AuthRepository(
      apiService,
      tokenStorage,
    );

    dio = Dio(
      BaseOptions(baseUrl: 'https://meevy.test'),
    );

    adapter = FakeHttpAdapter(
          (_) => httpResponse(200),
    );

    dio.httpClientAdapter = adapter;

    dio.interceptors.add(
      AuthTokenInterceptor(dio, authRepository),
    );
  });

  tearDown(() {
    authRepository.dispose();
    dio.close(force: true);
  });

  // Prepara una sessione autenticata per i test.
  Future<void> login({
    int expiresInSeconds = 3600,
  }) async {
    apiService.onLogin = (_, _) async {
      return fakeLoginResponse(
        accessToken: 'jwt-vecchio',
        refreshToken: 'refresh-vecchio',
        expiresInSeconds: expiresInSeconds,
      );
    };

    await authRepository.login(
      email: 'test@meevy.it',
      password: 'password123',
    );
  }

  test('aggiunge il Bearer token alla richiesta GET', () async {
    await login();

    final response = await dio.get('/subject');

    expect(response.statusCode, 200);
    expect(adapter.requests.length, 1);

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer jwt-vecchio',
    );

    expect(apiService.refreshCalls, 0);
  });

  test('rinnova il JWT prima di inviare la richiesta', () async {
    // Il JWT scade fra 10 secondi.
    await login(expiresInSeconds: 10);

    apiService.onRefresh = (token) async {
      expect(token, 'refresh-vecchio');

      return fakeLoginResponse(
        accessToken: 'jwt-nuovo',
        refreshToken: 'refresh-nuovo',
      );
    };

    final response = await dio.get('/subject');

    expect(response.statusCode, 200);
    expect(apiService.refreshCalls, 1);
    expect(adapter.requests.length, 1);

    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer jwt-nuovo',
    );
  });

  test('dopo un 401 rinnova il token e ripete la GET', () async {
    await login();

    apiService.onRefresh = (_) async {
      return fakeLoginResponse(
        accessToken: 'jwt-nuovo',
        refreshToken: 'refresh-nuovo',
      );
    };

    // Prima richiesta: 401. Seconda richiesta: 200.
    adapter.respond = (_) {
      if (adapter.requests.length == 1) {
        return httpResponse(401);
      }

      return httpResponse(200);
    };

    final response = await dio.get('/subject');

    expect(response.statusCode, 200);
    expect(apiService.refreshCalls, 1);
    expect(adapter.requests.length, 2);

    expect(
      adapter.requests[0].headers['Authorization'],
      'Bearer jwt-vecchio',
    );

    expect(
      adapter.requests[1].headers['Authorization'],
      'Bearer jwt-nuovo',
    );

    expect(
      adapter.requests[1].extra['authRetryPerformed'],
      isTrue,
    );
  });

  test('non ripete automaticamente una POST dopo il 401', () async {
    await login();

    adapter.respond = (_) => httpResponse(401);

    await expectLater(
      dio.post(
        '/subject',
        data: {'name': 'Analisi 1'},
      ),
      throwsA(isA<DioException>()),
    );

    expect(adapter.requests.length, 1);
    expect(apiService.refreshCalls, 0);
  });

  test('non ripete una GET più di una volta', () async {
    await login();

    apiService.onRefresh = (_) async {
      return fakeLoginResponse(
        accessToken: 'jwt-nuovo',
        refreshToken: 'refresh-nuovo',
      );
    };

    // Anche dopo il refresh, il server continua a rispondere 401.
    adapter.respond = (_) => httpResponse(401);

    await expectLater(
      dio.get('/subject'),
      throwsA(
        isA<DioException>().having(
              (error) => error.response?.statusCode,
          'statusCode',
          401,
        ),
      ),
    );

    // Richiesta originale + un solo tentativo aggiuntivo.
    expect(adapter.requests.length, 2);
    expect(apiService.refreshCalls, 1);
  });

  test('senza autenticazione blocca la richiesta protetta', () async {
    await expectLater(
      dio.get('/subject'),
      throwsA(isA<DioException>()),
    );

    // La richiesta non deve raggiungere il trasporto HTTP.
    expect(adapter.requests, isEmpty);
    expect(apiService.refreshCalls, 0);
  });
}
