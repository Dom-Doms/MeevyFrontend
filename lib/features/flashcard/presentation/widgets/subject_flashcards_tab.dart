
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/personal_flashcard.dart';
import '../view_models/subject_flashcards_view_model.dart';

/*
 * Visualizza le flashcard come domande espandibili.
 * L'utente può creare, modificare, duplicare ed eliminare.
 */
class SubjectFlashcardsTab extends StatelessWidget {
  const SubjectFlashcardsTab({super.key});

  Future<void> _showForm(
      BuildContext context,
      SubjectFlashcardsViewModel viewModel, [
        PersonalFlashcard? card,
      ]) async {
    final questionController = TextEditingController(
      text: card?.question ?? '',
    );
    final answerController = TextEditingController(
      text: card?.answer ?? '',
    );

    final key = GlobalKey<FormState>();

    final result = await showDialog<
        ({String question, String answer})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          card == null ? 'Nuova flashcard' : 'Modifica flashcard',
        ),
        content: Form(
          key: key,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: questionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Domanda',
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Inserisci una domanda.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: answerController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Risposta',
                  ),
                  validator: (value) =>
                  value == null || value.trim().isEmpty
                      ? 'Inserisci una risposta.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(
                  dialogContext,
                  (
                  question: questionController.text.trim(),
                  answer: answerController.text.trim(),
                  ),
                );
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    questionController.dispose();
    answerController.dispose();

    if (result == null || !context.mounted) return;

    final success = card == null
        ? await viewModel.create(result.question, result.answer)
        : await viewModel.update(
      card,
      result.question,
      result.answer,
    );

    if (!success && context.mounted) {
      _showError(context, viewModel);
    }
  }

  Future<void> _delete(
      BuildContext context,
      SubjectFlashcardsViewModel viewModel,
      PersonalFlashcard card,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Elimina flashcard?'),
        content: Text(card.question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    if (!await viewModel.delete(card) && context.mounted) {
      _showError(context, viewModel);
    }
  }

  void _showError(
      BuildContext context,
      SubjectFlashcardsViewModel viewModel,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.actionError ?? 'Operazione non completata.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SubjectFlashcardsViewModel>();

    if (viewModel.isLoading && viewModel.cards.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.errorMessage != null) {
      return Center(
        child: FilledButton(
          onPressed: viewModel.load,
          child: const Text('Errore di caricamento · Riprova'),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Flashcard',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              FilledButton.icon(
                onPressed: viewModel.isSaving
                    ? null
                    : () => _showForm(context, viewModel),
                icon: const Icon(Icons.add),
                label: const Text('Crea'),
              ),
            ],
          ),
        ),

        if (viewModel.isSaving)
          const LinearProgressIndicator(),

        Expanded(
          child: RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: viewModel.cards.length,
              itemBuilder: (context, index) {
                final card = viewModel.cards[index];

                return Card(
                  child: ExpansionTile(
                    key: ValueKey(card.id),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(card.question),
                        ),
                        PopupMenuButton<String>(
                          enabled: !viewModel.isSaving,
                          tooltip: 'Gestisci flashcard',
                          onSelected: (action) async {
                            if (action == 'edit') {
                              await _showForm(context, viewModel, card);
                            } else if (action == 'duplicate') {
                              final success =
                              await viewModel.duplicate(card);

                              if (!success && context.mounted) {
                                _showError(context, viewModel);
                              }
                            } else {
                              await _delete(context, viewModel, card);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Modifica'),
                            ),
                            PopupMenuItem(
                              value: 'duplicate',
                              child: Text('Duplica'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Elimina'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16, 8, 16, 20,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(card.answer),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
