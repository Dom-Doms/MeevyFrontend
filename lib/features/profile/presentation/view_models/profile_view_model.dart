
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

/*
 * Gestisce lo stato della schermata Profilo.
 *
 * Mantiene separati i dati dell'utente,
 * il caricamento e gli eventuali errori HTTP.
 */
class ProfileViewModel extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileViewModel(this._repository);

  UserProfile? _profile;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Recupera i dati del profilo dal server.

  Future<void> loadProfile() async {
    if (_isLoading || _disposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getMe();

      if (_disposed) return;

      _profile = result;
    } on DioException catch (error) {
      if (_disposed) return;

      if (error.response?.statusCode == 401) {
        _errorMessage = 'Sessione scaduta. Accedi nuovamente.';
      } else if (error.response?.statusCode == 404) {
        _errorMessage = 'Profilo utente non trovato.';
      } else if (error.response == null) {
        _errorMessage = 'Impossibile contattare il server.';
      } else {
        _errorMessage = 'Impossibile caricare il profilo.';
      }
    } on FormatException {
      if (_disposed) return;

      _errorMessage = 'I dati del profilo non sono validi.';
    } catch (_) {
      if (_disposed) return;

      _errorMessage = 'Errore durante il caricamento del profilo.';
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
