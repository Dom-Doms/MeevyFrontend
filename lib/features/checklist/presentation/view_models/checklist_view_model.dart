
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
  Future<bool> create() => _mutate(() async {
    if (_checklistId != null) return;

    _checklistId = await _repository.create(subjectId);
    _items = [];
  });

  Future<bool> add(String text) => _mutate(() async {
    final item = await _repository.addItem(
      _checklistId!,
      text.trim(),
    );

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
    _error = null;
    notifyListeners();

    try {
      await action();
      return !_disposed;
    } catch (_) {
      if (!_disposed) {
        _error = 'Operazione non completata. '
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
