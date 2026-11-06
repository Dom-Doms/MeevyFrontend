
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meevy_app/app/session/session_view_model.dart';
import 'package:meevy_app/features/auth/data/repositories/auth_repository.dart';

import '../../../test/support/auth_fakes.dart';

void main() {
  late FakeAuthApiService apiService;
  late FakeTokenStorage tokenStorage;
  late AuthRepository authRepository;
  late SessionViewModel sessionViewModel;

  setUp(() {
    apiService = FakeAuthApiService();
    tokenStorage = FakeTokenStorage();

    authRepository = AuthRepository(
      apiService,
      tokenStorage,
    );

    sessionViewModel = SessionViewModel(authRepository);
  });

  tearDown(() {
    sessionViewModel.dispose();
    authRepository.dispose();
  });

  test('lo stato iniziale è loading', () {
    expect(
      sessionViewModel.status,
      SessionStatus.loading,
    );
  });

  test('senza refresh token passa a unauthenticated', () async {
    await sessionViewModel.initialize();

    expect(
      sessionViewModel.status,
      SessionStatus.unauthenticated,
    );
  });

  test('con refresh valido passa ad authenticated', () async {
    tokenStorage.storedToken = 'refresh-valido';

    apiService.onRefresh = (_) async {
      return fakeLoginResponse();
    };

    await sessionViewModel.initialize();

    expect(
      sessionViewModel.status,
      SessionStatus.authenticated,
    );
  });

  test('un errore di rete durante il ripristino porta a error', () async {
    tokenStorage.storedToken = 'refresh-valido';

    apiService.onRefresh = (_) async {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/refresh'),
        type: DioExceptionType.connectionError,
      );
    };

    await sessionViewModel.initialize();

    expect(
      sessionViewModel.status,
      SessionStatus.error,
    );

    // Il refresh token deve rimanere salvato.
    expect(tokenStorage.storedToken, 'refresh-valido');
  });

  test('dopo un login riuscito passa ad authenticated', () async {
    apiService.onLogin = (_, _) async {
      return fakeLoginResponse();
    };

    await authRepository.login(
      email: 'test@meevy.it',
      password: 'password123',
    );

    sessionViewModel.onLoginSucceeded();

    expect(
      sessionViewModel.status,
      SessionStatus.authenticated,
    );
  });

  test('quando il refresh viene rifiutato perde la sessione', () async {
    apiService.onLogin = (_, _) async {
      return fakeLoginResponse();
    };

    await authRepository.login(
      email: 'test@meevy.it',
      password: 'password123',
    );

    sessionViewModel.onLoginSucceeded();

    expect(
      sessionViewModel.status,
      SessionStatus.authenticated,
    );

    // Il server revoca o rifiuta il refresh token.
    apiService.onRefresh = (_) async {
      throw fakeHttpError(401);
    };

    final refreshed = await authRepository.refreshAccessToken();

    expect(refreshed, isFalse);

    // Verifica il listener aggiunto a SessionViewModel.
    expect(
      sessionViewModel.status,
      SessionStatus.unauthenticated,
    );
  });

  test('il logout termina la sessione', () async {
    apiService.onLogin = (_, _) async {
      return fakeLoginResponse();
    };

    await authRepository.login(
      email: 'test@meevy.it',
      password: 'password123',
    );

    sessionViewModel.onLoginSucceeded();

    await sessionViewModel.logout();

    expect(
      sessionViewModel.status,
      SessionStatus.unauthenticated,
    );

    expect(authRepository.isAuthenticated, isFalse);
    expect(tokenStorage.storedToken, isNull);
  });

  test('un errore nel logout produce un avviso', () async {
    apiService.onLogin = (_, _) async {
      return fakeLoginResponse();
    };

    await authRepository.login(
      email: 'test@meevy.it',
      password: 'password123',
    );

    sessionViewModel.onLoginSucceeded();

    apiService.onLogout = (_) async {
      throw fakeHttpError(500);
    };

    await sessionViewModel.logout();

    expect(
      sessionViewModel.status,
      SessionStatus.unauthenticated,
    );

    expect(sessionViewModel.logoutWarning, isNotNull);
    expect(tokenStorage.storedToken, isNull);
  });
}
