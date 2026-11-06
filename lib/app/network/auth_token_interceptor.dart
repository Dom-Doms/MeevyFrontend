
import 'package:dio/dio.dart';

import '../../features/auth/data/repositories/auth_repository.dart';

/*
 * Gestisce l'autenticazione delle richieste HTTP protette.
 *
 * Aggiunge l'access token e tenta il refresh quando necessario.
 * Le richieste GET possono essere ripetute una sola volta dopo un 401.
 */
class AuthTokenInterceptor extends Interceptor {
  final Dio _dio;
  final AuthRepository _authRepository;

  static const String _retryKey = 'authRetryPerformed';
  static const String _sessionKey = 'sessionVersion';

  AuthTokenInterceptor(this._dio, this._authRepository);

  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    try {
      // Verifica il JWT ed eventualmente lo rinnova.
      final valid = await _authRepository.ensureValidAccessToken();
      final token = _authRepository.accessToken;

      if (!valid || token == null) {
        handler.reject(
          DioException(
            requestOptions: options,
            error: StateError('Sessione non autenticata.'),
          ),
        );
        return;
      }

      options.headers['Authorization'] = 'Bearer $token';
      options.extra[_sessionKey] = _authRepository.sessionVersion;

      handler.next(options);
    } catch (error, stackTrace) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  void onError(
      DioException err,
      ErrorInterceptorHandler handler,
      ) async {
    final request = err.requestOptions;

    // Non ripete richieste diverse da GET o già ripetute.
    if (err.response?.statusCode != 401 ||
        request.method.toUpperCase() != 'GET' ||
        request.extra[_retryKey] == true ||
        request.extra[_sessionKey] !=
            _authRepository.sessionVersion) {
      handler.next(err);
      return;
    }

    try {
      var token = _authRepository.accessToken;

      if (token == null) {
        handler.next(err);
        return;
      }

      /*
       * Se il token utilizzato è ancora quello corrente,
       * prova a rinnovarlo. Se è già cambiato, un'altra
       * richiesta ha effettuato il refresh.
       */
      if (request.headers['Authorization'] == 'Bearer $token') {
        final refreshed = await _authRepository.refreshAccessToken();

        if (!refreshed) {
          handler.next(err);
          return;
        }

        token = _authRepository.accessToken;
      }

      if (token == null) {
        handler.next(err);
        return;
      }

      // Ripete la GET con il nuovo JWT e impedisce ulteriori retry.
      final retryRequest = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer $token',
        },
        extra: {
          ...request.extra,
          _retryKey: true,
        },
      );

      final response = await _dio.fetch<dynamic>(retryRequest);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }
}
