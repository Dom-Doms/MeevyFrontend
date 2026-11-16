
import 'package:dio/dio.dart';

import '../models/user_profile.dart';

/*
 * Gestisce la comunicazione con le API del profilo.
 *
 * Riceve il Dio autenticato, già configurato
 * con AuthTokenInterceptor.
 */
class ProfileRepository {
  final Dio _dio;

  ProfileRepository(this._dio);

  // Recupera il profilo dell'utente autenticato.

  Future<UserProfile> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/user/me',
    );

    final data = response.data;

    if (data == null) {
      throw const FormatException(
        'Risposta del profilo non valida.',
      );
    }

    return UserProfile.fromJson(data);
  }
}
