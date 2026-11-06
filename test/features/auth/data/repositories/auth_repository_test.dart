
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meevy_app/features/auth/data/models/login_response.dart';

import 'package:meevy_app/features/auth/data/repositories/auth_repository.dart';

import '../../../../../test/support/auth_fakes.dart';

void main() {
  late FakeAuthApiService apiService;
  late FakeTokenStorage tokenStorage;
  late AuthRepository repository;

  setUp(() {
    apiService = FakeAuthApiService();
    tokenStorage = FakeTokenStorage();

    repository = AuthRepository(
      apiService,
      tokenStorage,
    );
  });

  tearDown(() {
    repository.dispose();
  });

  group('AuthRepository - Login', () {
    test('salva il refresh token e mantiene il JWT in memoria', () async {
      apiService.onLogin = (email, password) async {
        expect(email, 'test@meevy.it');
        expect(password, 'password123');

        return fakeLoginResponse();
      };

      await repository.login(
        email: 'test@meevy.it',
        password: 'password123',
      );

      expect(repository.isAuthenticated, isTrue);
      expect(repository.accessToken, 'access-123');
      expect(tokenStorage.storedToken, 'refresh-123');
      expect(apiService.loginCalls, 1);
    });
  });

  group('AuthRepository - Ripristino', () {
    test('senza refresh token non ripristina la sessione', () async {
      final restored = await repository.restoreSession();

      expect(restored, isFalse);
      expect(repository.isAuthenticated, isFalse);
      expect(apiService.refreshCalls, 0);
    });

    test('con refresh valido ripristina la sessione', () async {
      tokenStorage.storedToken = 'refresh-vecchio';

      apiService.onRefresh = (token) async {
        expect(token, 'refresh-vecchio');

        return fakeLoginResponse(
          accessToken: 'access-nuovo',
          refreshToken: 'refresh-nuovo',
        );
      };

      final restored = await repository.restoreSession();

      expect(restored, isTrue);
      expect(repository.accessToken, 'access-nuovo');
      expect(tokenStorage.storedToken, 'refresh-nuovo');
      expect(repository.isAuthenticated, isTrue);
    });
  });

  group('AuthRepository - Scadenza JWT', () {
    test('non rinnova un access token ancora valido', () async {
      apiService.onLogin = (_, _) async {
        return fakeLoginResponse(
          expiresInSeconds: 3600,
        );
      };

      await repository.login(
        email: 'test@meevy.it',
        password: 'password123',
      );

      final valid = await repository.ensureValidAccessToken();

      expect(valid, isTrue);
      expect(apiService.refreshCalls, 0);
    });

    test('rinnova un access token vicino alla scadenza', () async {
      apiService.onLogin = (_, _) async {
        return fakeLoginResponse(
          refreshToken: 'refresh-vecchio',
          expiresInSeconds: 10,
        );
      };

      apiService.onRefresh = (token) async {
        expect(token, 'refresh-vecchio');

        return fakeLoginResponse(
          accessToken: 'access-rinnovato',
          refreshToken: 'refresh-rinnovato',
        );
      };

      await repository.login(
        email: 'test@meevy.it',
        password: 'password123',
      );

      final valid = await repository.ensureValidAccessToken();

      expect(valid, isTrue);
      expect(apiService.refreshCalls, 1);
      expect(repository.accessToken, 'access-rinnovato');
      expect(tokenStorage.storedToken, 'refresh-rinnovato');
    });
  });

  group('AuthRepository - Errori refresh', () {
    test('un refresh con 401 elimina le credenziali', () async {
      tokenStorage.storedToken = 'refresh-scaduto';

      apiService.onRefresh = (_) async {
        throw fakeHttpError(401);
      };

      final restored = await repository.restoreSession();

      expect(restored, isFalse);
      expect(repository.accessToken, isNull);
      expect(tokenStorage.storedToken, isNull);
    });

    test('un errore di rete non elimina il refresh token', () async {
      tokenStorage.storedToken = 'refresh-valido';

      apiService.onRefresh = (_) async {
        throw DioException(
          requestOptions: RequestOptions(path: '/auth/refresh'),
          type: DioExceptionType.connectionError,
          error: 'Connessione assente',
        );
      };

      await expectLater(
        repository.restoreSession(),
        throwsA(isA<DioException>()),
      );

      expect(tokenStorage.storedToken, 'refresh-valido');
    });

    test('un errore 500 non cancella la sessione esistente', () async {
      apiService.onLogin = (_, _) async {
        return fakeLoginResponse();
      };

      await repository.login(
        email: 'test@meevy.it',
        password: 'password123',
      );

      apiService.onRefresh = (_) async {
        throw fakeHttpError(500);
      };

      await expectLater(
        repository.refreshAccessToken(),
        throwsA(isA<DioException>()),
      );

      expect(repository.accessToken, 'access-123');
      expect(tokenStorage.storedToken, 'refresh-123');
    });
  });

  group('AuthRepository - Concorrenza', () {
    test('tre refresh contemporanei fanno una sola chiamata HTTP', () async {
      tokenStorage.storedToken = 'refresh-vecchio';

      final completer = Completer<LoginResponse>();

      apiService.onRefresh = (token) {
        expect(token, 'refresh-vecchio');
        return completer.future;
      };

      // Tre richieste chiedono il rinnovo nello stesso momento.
      final first = repository.refreshAccessToken();
      final second = repository.refreshAccessToken();
      final third = repository.refreshAccessToken();

      // Consente alla prima richiesta asincrona di raggiungere il service.
      await Future<void>.delayed(Duration.zero);

      expect(apiService.refreshCalls, 1);

      // Simuliamo la risposta del backend.
      completer.complete(
        fakeLoginResponse(
          accessToken: 'access-nuovo',
          refreshToken: 'refresh-nuovo',
        ),
      );

      final results = await Future.wait([
        first,
        second,
        third,
      ]);

      expect(results, [true, true, true]);
      expect(apiService.refreshCalls, 1);
      expect(repository.accessToken, 'access-nuovo');
      expect(tokenStorage.storedToken, 'refresh-nuovo');
    });
  });

  group('AuthRepository - Logout', () {
    test('revoca la sessione e cancella i token locali', () async {
      apiService.onLogin = (_, _) async {
        return fakeLoginResponse();
      };

      await repository.login(
        email: 'test@meevy.it',
        password: 'password123',
      );

      apiService.onLogout = (token) async {
        expect(token, 'refresh-123');
      };

      await repository.logout();

      expect(apiService.logoutCalls, 1);
      expect(repository.isAuthenticated, isFalse);
      expect(tokenStorage.storedToken, isNull);
    });

    test('cancella i token anche se il logout remoto fallisce', () async {
      apiService.onLogin = (_, _) async {
        return fakeLoginResponse();
      };

      await repository.login(
        email: 'test@meevy.it',
        password: 'password123',
      );

      apiService.onLogout = (_) async {
        throw fakeHttpError(500);
      };

      await expectLater(
        repository.logout(),
        throwsA(isA<DioException>()),
      );

      expect(repository.isAuthenticated, isFalse);
      expect(tokenStorage.storedToken, isNull);
    });
  });
}
