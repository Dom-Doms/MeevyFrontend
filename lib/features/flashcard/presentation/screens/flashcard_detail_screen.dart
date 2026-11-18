
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/personal_flashcard.dart';
import '../view_models/subject_flashcards_view_model.dart';

/*
 * Pagina di dettaglio di una flashcard personale.
 *
 * Visualizza sempre i dati aggiornati del ViewModel
 * e riutilizza le azioni di modifica ed eliminazione
 * già disponibili nella tab Flashcard.
 *
 * La sezione condivisioni verrà collegata alle API
 * dei gruppi quando saranno implementate.
 */
class FlashcardDetailScreen extends StatelessWidget {
  final int flashcardId;
  final String subjectName;

  final Future<void> Function(PersonalFlashcard) onEdit;
  final Future<void> Function(PersonalFlashcard) onDelete;

  const FlashcardDetailScreen({
    super.key,
    required this.flashcardId,
    required this.subjectName,
    required this.onEdit,
    required this.onDelete,
  });

  /*
   * Duplica una flashcard tramite il ViewModel esistente.
   * La copia viene aggiunta all'elenco della materia.
   */
  Future<void> _duplicate(
      BuildContext context,
      SubjectFlashcardsViewModel viewModel,
      PersonalFlashcard card,
      ) async {
    final success = await viewModel.duplicate(card);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Flashcard duplicata.'
              : (viewModel.actionError ??
              'Impossibile duplicare la flashcard.'),
        ),
      ),
    );
  }

  /*
   * Chiude il dettaglio soltanto quando la cancellazione
   * è stata confermata dal server.
   *
   * Se l'utente annulla o l'operazione fallisce,
   * la pagina rimane aperta.
   */
  Future<void> _delete(
      BuildContext context,
      SubjectFlashcardsViewModel viewModel,
      PersonalFlashcard card,
      ) async {
    await onDelete(card);

    if (!context.mounted) return;

    final stillExists = viewModel.cards.any(
          (item) => item.id == flashcardId,
    );

    if (!stillExists) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel =
    context.watch<SubjectFlashcardsViewModel>();

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Utilizziamo sempre la versione aggiornata
    // della flashcard presente nel ViewModel.
    final matchingCards = viewModel.cards.where(
          (item) => item.id == flashcardId,
    );

    if (matchingCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dettaglio flashcard'),
        ),
        body: const Center(
          child: Text('Flashcard non disponibile.'),
        ),
      );
    }

    final card = matchingCards.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dettaglio flashcard'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Altre azioni',
            enabled: !viewModel.isSaving,
            onSelected: (action) {
              if (action == 'duplicate') {
                _duplicate(context, viewModel, card);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'duplicate',
                child: Text('Duplica flashcard'),
              ),
            ],
          ),
        ],
      ),

      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16, 8, 16, 28,
          ),
          children: [
            // Materia alla quale appartiene la flashcard.
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    subjectName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Domanda della flashcard.
            _FlashcardSection(
              title: 'Domanda',
              content: card.question,
              icon: Icons.help_outline,
            ),

            const SizedBox(height: 16),

            // Risposta della flashcard.
            _FlashcardSection(
              title: 'Risposta',
              content: card.answer,
              icon: Icons.description_outlined,
            ),

            const SizedBox(height: 16),

            /*
             * Questa sezione è già predisposta
             * visivamente per le future condivisioni.
             *
             * Non mostra gruppi inventati e non contiene
             * pulsanti collegati a endpoint inesistenti.
             */
            _FlashcardSection(
              title: 'Condivisa con',
              content:
              'Questa flashcard è personale.\n\n'
                  'Quando sarà disponibile la condivisione, '
                  'qui potrai visualizzare i gruppi collegati '
                  'e gestire le singole condivisioni.',
              icon: Icons.groups_outlined,
            ),

            const SizedBox(height: 24),

            if (viewModel.isSaving)
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              ),

            // Azioni principali della flashcard.
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.error,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                    onPressed: viewModel.isSaving
                        ? null
                        : () => _delete(
                      context,
                      viewModel,
                      card,
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Elimina'),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
                    ),
                    onPressed: viewModel.isSaving
                        ? null
                        : () => onEdit(card),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Modifica'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/*
 * Componente grafico riutilizzabile per le sezioni
 * Domanda, Risposta e Condivisioni.
 *
 * Utilizza il tema Material già presente in Meevy.
 */
class _FlashcardSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;

  const _FlashcardSection({
    required this.title,
    required this.content,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: colors.onPrimaryContainer,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            content,
            style: theme.textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
