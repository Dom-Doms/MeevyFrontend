
/*
 * Rappresenta la risposta restituita dal backend
 * dopo un login o un refresh riuscito.
 */
class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInSeconds;

  // Crea un oggetto con i dati ricevuti dal server.
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInSeconds,
  });

  /*
   * Converte il JSON restituito dalle API
   * in un oggetto LoginResponse.
   */
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String,
      expiresInSeconds: json['expiresInSeconds'] as int,
    );
  }
}
