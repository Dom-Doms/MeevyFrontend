
import 'package:flutter/foundation.dart';

import '../../data/models/personal_flashcard.dart';
import '../../data/repositories/flashcards_repository.dart';

/*
 * Gestisce l'elenco e le operazioni delle flashcard personali.
 */
class SubjectFlashcardsViewModel extends ChangeNotifier {
  final FlashcardsRepository _repository;
  final int subjectId;

  List<PersonalFlashcard> _cards = [];
  bool _loading = false;
  bool _saving = false;
  bool _disposed = false;
  String? _error;
  String? _actionError;

  SubjectFlashcardsViewModel(
      this._repository,
      this.subjectId,
      );

  List<PersonalFlashcard> get cards =>
      List.unmodifiable(_cards);

  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get errorMessage => _error;
  String? get actionError => _actionError;

  // Recupera le flashcard dal server.
  Future<void> load() async {
    if (_loading || _saving || _disposed) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getBySubject(subjectId);
      if (_disposed) return;
      _cards = result;
    } catch (_) {
      if (!_disposed) {
        _error = 'Impossibile caricare le flashcard.';
      }
    } finally {
      if (!_disposed) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> create(String question, String answer) =>
      _mutate(() async {
        final created = await _repository.create(
          subjectId: subjectId,
          question: question.trim(),
          answer: answer.trim(),
        );

        if (!_disposed) {
          _cards = [..._cards, created];
        }
      });

  Future<bool> update(
      PersonalFlashcard card,
      String question,
      String answer,
      ) =>
      _mutate(() async {
        final updated = await _repository.update(
          id: card.id,
          question: question.trim(),
          answer: answer.trim(),
        );

        if (!_disposed) {
          _cards = _cards.map((item) {
            return item.id == updated.id ? updated : item;
          }).toList();
        }
      });

  Future<bool> duplicate(PersonalFlashcard card) =>
      _mutate(() async {
        final copy = await _repository.duplicate(card.id);

        if (!_disposed) {
          _cards = [..._cards, copy];
        }
      });

  Future<bool> delete(PersonalFlashcard card) =>
      _mutate(() async {
        await _repository.delete(card.id);

        if (!_disposed) {
          _cards = _cards
              .where((item) => item.id != card.id)
              .toList();
        }
      });

  /*
   * Centralizza lo stato delle operazioni di scrittura.
   * Non modifica la UI direttamente.
   */
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
        'Operazione non completata. '
            'Aggiorna le flashcard prima di riprovare.';
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
