
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

/*
 * Gestisce lo stato della schermata di login.
 *
 * La View osserva loading ed errori, mentre
 * l'autenticazione viene delegata al Repository.
 */
class LoginViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;

  LoginViewModel(this._authRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /*
   * Richiede il login e aggiorna lo stato della View.
   * Restituisce true soltanto se l'accesso riesce.
   */
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepository.login(
        email: email,
        password: password,
      );

      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        _errorMessage = 'Email o password non valide.';
      } else if (error.response == null) {
        _errorMessage = 'Impossibile contattare il server.';
      } else {
        _errorMessage = 'Errore del server. Riprova.';
      }

      return false;
    } catch (_) {
      _errorMessage = 'Impossibile completare il login.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
