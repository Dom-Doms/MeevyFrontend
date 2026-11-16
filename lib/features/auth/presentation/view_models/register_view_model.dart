
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/register_request.dart';
import '../../data/repositories/auth_repository.dart';

// Gestisce lo stato e gli eventuali errori della registrazione.
class RegisterViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  RegisterViewModel(this._authRepository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Invia i dati al Repository e restituisce true se la registrazione riesce.
  Future<bool> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        email: email.trim(),
        password: password,
        firstName: _optionalText(firstName),
        lastName: _optionalText(lastName),
      );

      await _authRepository.register(request);

      return true;
    } on DioException catch (error) {
      final statusCode = error.response?.statusCode;

      if (statusCode == 409) {
        _errorMessage = 'Questa email è già registrata.';
      } else if (statusCode == 400) {
        _errorMessage = 'Controlla i dati inseriti.';
      } else if (error.response == null) {
        _errorMessage = 'Impossibile contattare il server.';
      } else {
        _errorMessage = 'Errore durante la registrazione.';
      }

      return false;
    } catch (_) {
      _errorMessage = 'Impossibile completare la registrazione.';
      return false;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Trasforma un campo facoltativo vuoto in null.
  String? _optionalText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
