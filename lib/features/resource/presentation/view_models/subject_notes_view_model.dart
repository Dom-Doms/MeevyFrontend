
import 'package:flutter/foundation.dart';

import '../../data/models/personal_resource.dart';
import '../../data/repositories/resources_repository.dart';

/*
 * Gestisce gli appunti appartenenti a una materia.
 * Conserva elenco, caricamento ed eventuali errori.
 */
class SubjectNotesViewModel extends ChangeNotifier {
  final ResourcesRepository _repository;
  final int subjectId;

  List<PersonalResource> _resources = [];

  bool _isLoading = false;
  bool _disposed = false;

  String? _errorMessage;

  SubjectNotesViewModel(
      this._repository,
      this.subjectId,
      );

  List<PersonalResource> get resources =>
      List.unmodifiable(_resources);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Carica gli appunti della materia dal server.
  Future<void> load() async {
    if (_isLoading || _disposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getBySubject(
        subjectId,
      );

      if (_disposed) return;

      _resources = result;
    } catch (_) {
      if (_disposed) return;

      _errorMessage = 'Impossibile caricare gli appunti.';
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
