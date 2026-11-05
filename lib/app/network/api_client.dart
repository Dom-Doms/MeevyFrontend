
import 'package:dio/dio.dart';

import '../config/app_config.dart';

Dio createApiClient() {
  final baseUrl = AppConfig.apiBaseUrl.trim();
  final uri = Uri.tryParse(baseUrl);

  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    throw StateError(
      'API_BASE_URL non configurata o non valida.',
    );
  }

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
}
