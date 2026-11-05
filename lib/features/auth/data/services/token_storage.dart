
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/*
 * Gestisce il salvataggio sicuro del refresh token.
 *
 * L'access token verrà mantenuto in memoria
 * e non sarà salvato sul dispositivo.
 */
class TokenStorage {
  static const String _refreshTokenKey = 'meevy_refresh_token';

  final FlutterSecureStorage _storage;

  // Riceve lo storage dall'esterno per facilitarne il testing.
  TokenStorage(this._storage);

  // Salva il refresh token dopo l'autenticazione.
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: _refreshTokenKey,
      value: token,
    );
  }

  // Recupera il refresh token, se presente.
  Future<String?> readRefreshToken() async {
    return _storage.read(key: _refreshTokenKey);
  }

  // Elimina il refresh token durante il logout.
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }
}
