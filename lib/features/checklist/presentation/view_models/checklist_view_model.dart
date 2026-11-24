
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/checklist_item.dart';
import '../../data/repositories/checklist_repository.dart';

/*
 * Gestisce lo stato della checklist associata a una materia.
 * Le operazioni vengono confermate dal backend prima
 * di aggiornare l'elenco locale.
 */
class ChecklistViewModel extends ChangeNotifier {
  final ChecklistRepository _repository;
  final int subjectId;

  int? _checklistId;
  List<ChecklistItem> _items = [];
  bool _loading = false;
  bool _saving = false;
  bool _disposed = false;
  String? _error;

  String? _actionError;

// Gli errori delle operazioni non nascondono l'intera checklist.
  String? get actionError => _actionError;


  ChecklistViewModel(this._repository, this.subjectId);

  List<ChecklistItem> get items => List.unmodifiable(_items);
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  bool get hasChecklist => _checklistId != null;
  String? get errorMessage => _error;

  // Carica la checklist e le relative attività.
  Future<void> load() async {
    if (_loading || _saving || _disposed) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _repository.getBySubject(subjectId);
      final items = await _repository.getItems(id);

      if (_disposed) return;

      _checklistId = id;
      _items = items;
    } on DioException catch (error) {
      if (_disposed) return;

      final data = error.response?.data;
      final code = data is Map ? data['code'] : null;

      if (code == 'CHECKLIST_NOT_FOUND') {
        _checklistId = null;
        _items = [];
      } else {
        _error = 'Impossibile caricare la checklist.';
      }
    } catch (_) {
      if (!_disposed) {
        _error = 'Impossibile caricare la checklist.';
      }
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  // Crea la checklist soltanto quando manca.

/*
 * Recupera la checklist già presente o la crea
 * automaticamente al primo inserimento.
 *
 * Se la risposta di creazione viene persa,
 * prova a recuperare la checklist dal server
 * anziché inviare immediatamente un'altra POST.
 */
  Future<int> _ensureChecklist() async {
    if (_checklistId != null) {
      return _checklistId!;
    }

   int checklistId;

    try {
      checklistId = await _repository.create(subjectId);
    } catch (_) {
      // Verifica se il server ha già creato la checklist.
      checklistId = await _repository.getBySubject(subjectId);

      // Riconcilia anche eventuali attività già presenti.
      final existingItems = await _repository.getItems(
        checklistId,
      );

      if (!_disposed) {
        _items = existingItems;
      }
    }

    if (!_disposed) {
      _checklistId = checklistId;
    }

    return checklistId;
  }



/*
 * Aggiunge un'attività alla materia.
 * Se necessario, crea automaticamente la checklist.
 */
  Future<bool> add(String text) => _mutate(() async {
    final normalizedText = text.trim();

    if (normalizedText.isEmpty) {
      throw const FormatException(
        'Il testo dell’attività non può essere vuoto.',
      );
    }

    // La prima aggiunta crea anche la checklist.
    final checklistId = await _ensureChecklist();

    if (_disposed) return;

    final item = await _repository.addItem(
      checklistId,
      normalizedText,
    );

    if (_disposed) return;

    _items = [..._items, item];
  });


  Future<bool> rename(ChecklistItem item, String text) =>
      _mutate(() async {
        final updated = await _repository.updateItem(
          item.id,
          text.trim(),
        );

        _replace(updated);
      });

  Future<bool> toggle(ChecklistItem item) => _mutate(() async {
    final updated = await _repository.setCompleted(
      item.id,
      !item.completed,
    );

    _replace(updated);
  });

  Future<bool> remove(ChecklistItem item) => _mutate(() async {
    await _repository.deleteItem(item.id);

    _items = _items
        .where((current) => current.id != item.id)
        .toList();
  });

  // Aggiorna una singola attività usando la risposta REST.
  void _replace(ChecklistItem updated) {
    _items = _items.map((item) {
      return item.id == updated.id ? updated : item;
    }).toList();
  }

  Future<bool> _mutate(Future<void> Function() action) async {
    if (_loading || _saving || _disposed) return false;


    _saving = true;
    _actionError = null;
    notifyListeners();


    try {
      await action();
      return !_disposed;
    } catch (_) {
      if (!_disposed) {
        _actionError =
        'Operazione non confermata. '
            'Aggiorna la checklist prima di riprovare.';

      }

      return false;
    } finally {
      if (!_disposed) {
        _saving = false;
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
