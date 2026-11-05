
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/subject.dart';
import '../../data/repositories/subjects_repository.dart';

/*
 * Gestisce caricamento, dati ed errori
 * della schermata delle materie personali.
 */
class SubjectsViewModel extends ChangeNotifier {
  final SubjectsRepository _repository;

  List<Subject> _subjects = [];
  bool _isLoading = false;
  bool _disposed = false;
  String? _errorMessage;

  SubjectsViewModel(this._repository);

  List<Subject> get subjects => List.unmodifiable(_subjects);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Carica l'elenco aggiornato delle materie.
  Future<void> load() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getAll();

      if (_disposed) return;
      _subjects = result;
    } on DioException catch (_) {
      if (_disposed) return;
      _errorMessage = 'Impossibile caricare le materie.';
    } catch (_) {
      if (_disposed) return;
      _errorMessage = 'Risposta del server non valida.';
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
