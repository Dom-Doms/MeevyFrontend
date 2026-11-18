
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/personal_flashcard.dart';
import '../view_models/subject_flashcards_view_model.dart';


import '../screens/flashcard_detail_screen.dart';


/*
 * Visualizza le flashcard come domande espandibili.
 * L'utente può creare, modificare, duplicare ed eliminare.
 */
class SubjectFlashcardsTab extends StatelessWidget {

  final String subjectName;

  const SubjectFlashcardsTab({
    super.key,
    required this.subjectName,
  });


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


/*
 * Apre il dettaglio della flashcard selezionata.
 *
 * Riutilizza lo stesso ViewModel della tab: le modifiche
 * saranno immediatamente visibili anche nell'elenco.
 */
  Future<void> _openDetail(
      BuildContext context,
      SubjectFlashcardsViewModel viewModel,
      PersonalFlashcard card,
      ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (pageContext) {
          return ChangeNotifierProvider<
              SubjectFlashcardsViewModel>.value(
            value: viewModel,
            child: FlashcardDetailScreen(
              flashcardId: card.id,
              subjectName: subjectName,

              // Riutilizziamo il dialog di modifica esistente.
              onEdit: (current) => _showForm(
                pageContext,
                viewModel,
                current,
              ),

              // Riutilizziamo la conferma di eliminazione.
              onDelete: (current) => _delete(
                pageContext,
                viewModel,
                current,
              ),
            ),
          );
        },
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

    return Stack(
        children: [
    Column(
    children: [

        if (viewModel.isSaving)
          const LinearProgressIndicator(),

        Expanded(
          child: RefreshIndicator(
            onRefresh: viewModel.load,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: viewModel.cards.length,
              itemBuilder: (context, index) {
                final card = viewModel.cards[index];


                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: const Icon(Icons.style_outlined),
                    title: Text(
                      card.question,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('Visualizza la flashcard'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openDetail(
                      context,
                      viewModel,
                      card,
                    ),
                  ),
                );

              },
            ),
          ),
        ),

    ],
    ),

          // Crea una flashcard nella materia corrente.
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'add_personal_flashcard',
              tooltip: 'Crea flashcard',
              onPressed: viewModel.isSaving
                  ? null
                  : () => _showForm(context, viewModel),
              child: const Icon(Icons.add),
            ),
          ),
        ],
    );
  }
}
