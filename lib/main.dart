
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

import 'app/meevy_app.dart';
import 'app/network/api_client.dart';
import 'app/network/auth_token_interceptor.dart';
import 'app/session/session_view_model.dart';

import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/data/services/auth_api_service.dart';
import 'features/auth/data/services/token_storage.dart';

/*
 * Inizializza le dipendenze condivise dell'applicazione.
 *
 * Separa le API pubbliche di autenticazione
 * dalle richieste che richiedono un JWT.
 */
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Client per login, refresh e logout, senza interceptor.
  final authDio = createApiClient();

  // Client per gli endpoint protetti.
  final protectedDio = createApiClient();

  final authApiService = AuthApiService(authDio);

  final tokenStorage = TokenStorage(
    const FlutterSecureStorage(),
  );

  // Una sola istanza condivisa gestisce tutti i token.
  final authRepository = AuthRepository(
    authApiService,
    tokenStorage,
  );

  final sessionViewModel = SessionViewModel(
    authRepository,
  );

  // Aggiunge autenticazione e refresh alle API protette.
  protectedDio.interceptors.add(
    AuthTokenInterceptor(
      protectedDio,
      authRepository,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<Dio>.value(value: protectedDio),
        Provider<AuthRepository>.value(value: authRepository),
        ChangeNotifierProvider<SessionViewModel>.value(
          value: sessionViewModel,
        ),
      ],
      child: const MeevyApp(),
    ),
  );
}
