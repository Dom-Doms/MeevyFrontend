
import 'package:dio/dio.dart';

import '../../features/auth/data/repositories/auth_repository.dart';

/*
 * Aggiunge automaticamente l'access token JWT
 * alle richieste REST che richiedono autenticazione.
 *
 * Recupera il token da AuthRepository, senza
 * conservarne una seconda copia.
 */
class AuthTokenInterceptor extends Interceptor {
  final AuthRepository _authRepository;

  AuthTokenInterceptor(this._authRepository);

  // Endpoint pubblici che non richiedono l'access token.
  static const Set<String> _publicPaths = {
    '/auth/login',
    '/auth/refresh',
    '/auth/logout',
    '/user/register',
  };

  /*
   * Intercetta la richiesta prima dell'invio al server.
   * Se l'utente è autenticato, aggiunge l'header Bearer.
   */
  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) {
    final path = options.uri.path;

    if (!_publicPaths.contains(path)) {
      final accessToken = _authRepository.accessToken;

      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    // Permette a Dio di proseguire con la richiesta.
    handler.next(options);
  }
}
