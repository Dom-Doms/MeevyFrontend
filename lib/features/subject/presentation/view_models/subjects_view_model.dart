
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

  bool _isSaving = false;
  String? _saveError;

  bool get isSaving => _isSaving;
  String? get saveError => _saveError;

  SubjectsViewModel(this._repository);

  List<Subject> get subjects => List.unmodifiable(_subjects);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Carica l'elenco aggiornato delle materie.
  Future<void> load() async {
    if (_isLoading || _isSaving || _disposed) return;

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


// Cerca una materia già presente nell'elenco.
  Subject? findById(int subjectId) {
    for (final subject in _subjects) {
      if (subject.id == subjectId) {
        return subject;
      }
    }

    return null;
  }

// Crea una materia e aggiorna l'elenco locale.
  Future<bool> create(String name) {
    return _executeMutation(() async {
      final created = await _repository.create(name);

      if (_disposed) return;

      _subjects.add(created);
    });
  }

// Aggiorna una materia senza ricaricare tutto l'elenco.
  Future<bool> update(int subjectId, String name) {
    return _executeMutation(() async {
      final updated = await _repository.update(
        subjectId,
        name,
      );

      if (_disposed) return;

      final index = _subjects.indexWhere(
            (subject) => subject.id == subjectId,
      );

      if (index != -1) {
        _subjects[index] = updated;
      }
    });
  }

// Rimuove la materia soltanto dopo la conferma del server.
  Future<bool> delete(int subjectId) {
    return _executeMutation(() async {
      await _repository.delete(subjectId);

      if (_disposed) return;

      _subjects.removeWhere(
            (subject) => subject.id == subjectId,
      );
    });
  }

/*
 * Gestisce lo stato comune delle operazioni di modifica.
 * Impedisce salvataggi simultanei e centralizza gli errori.
 */
  Future<bool> _executeMutation(
      Future<void> Function() operation,
      ) async {
    if (_isSaving || _isLoading || _disposed) {
      return false;
    }

    _isSaving = true;
    _saveError = null;
    notifyListeners();

    try {
      await operation();
      return !_disposed;
    } on DioException catch (error) {
      if (_disposed) return false;

      final statusCode = error.response?.statusCode;

      if (statusCode == 400) {
        _saveError = 'Controlla il nome della materia.';
      } else if (statusCode == 404) {
        _saveError = 'Materia non trovata.';
      } else {
        _saveError = 'Impossibile completare l’operazione.';
      }

      return false;
    } catch (_) {
      if (!_disposed) {
        _saveError = 'Si è verificato un errore.';
      }

      return false;
    } finally {
      if (!_disposed) {
        _isSaving = false;
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
