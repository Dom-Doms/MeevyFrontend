
import 'package:flutter/material.dart';

import '../../data/models/personal_flashcard.dart';

/*
 * Schermata di ripasso delle flashcard personali.
 *
 * La sessione utilizza una copia delle flashcard
 * disponibili al momento dell'avvio.
 *
 * Domanda e risposta vengono alternate al tocco.
 * Il ripasso non modifica le flashcard nel backend.
 */
class FlashcardReviewScreen extends StatefulWidget {
  final String subjectName;
  final List<PersonalFlashcard> cards;

  FlashcardReviewScreen({
    super.key,
    required this.subjectName,
    required List<PersonalFlashcard> cards,
  }) : cards = List.unmodifiable(cards);

  @override
  State<FlashcardReviewScreen> createState() =>
      _FlashcardReviewScreenState();
}

class _FlashcardReviewScreenState
    extends State<FlashcardReviewScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _finished = false;

  // Alterna domanda e risposta della flashcard corrente.
  void _flipCard() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  // Torna alla flashcard precedente.
  void _previous() {
    if (_currentIndex == 0) return;

    setState(() {
      _currentIndex--;
      _showAnswer = false;
    });
  }

  /*
   * Passa alla flashcard successiva.
   *
   * Ogni nuova flashcard mostra inizialmente
   * soltanto la domanda.
   *
   * Dopo l'ultima flashcard mostra il riepilogo.
   */
  void _next() {
    if (_currentIndex >= widget.cards.length - 1) {
      setState(() {
        _finished = true;
      });
      return;
    }

    setState(() {
      _currentIndex++;
      _showAnswer = false;
    });
  }

  // Ricomincia il ripasso dalla prima domanda.
  void _restart() {
    setState(() {
      _currentIndex = 0;
      _showAnswer = false;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ripasso flashcard'),
      ),
      body: SafeArea(
        top: false,
        child: widget.cards.isEmpty
            ? const Center(
          child: Text(
            'Non ci sono flashcard da ripassare.',
          ),
        )
            : _finished
            ? _buildFinished(context)
            : _buildReview(context),
      ),
    );
  }

  /*
   * Mostra domanda o risposta e i controlli
   * di navigazione della sessione.
   */
  Widget _buildReview(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final card = widget.cards[_currentIndex];
    final total = widget.cards.length;

    final progress = (_currentIndex + 1) / total;
    final isLast = _currentIndex == total - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16, 12, 16, 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.subjectName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium,
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Domanda ${_currentIndex + 1} di $total',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${(progress * 100).round()}%',
                style: theme.textTheme.labelLarge,
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Indica la posizione all'interno del ripasso.
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(8),
          ),

          const SizedBox(height: 24),

          /*
           * Card interattiva.
           *
           * La risposta viene mostrata soltanto
           * quando l'utente tocca la card.
           */
          Expanded(
            child: Card(
              elevation: 0,
              margin: EdgeInsets.zero,
              color: colors.surface,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: colors.outlineVariant,
                ),
              ),
              child: Semantics(
                button: true,
                label: _showAnswer
                    ? 'Mostra la domanda'
                    : 'Mostra la risposta',
                child: InkWell(
                  key: const Key('review_card'),
                  onTap: _flipCard,
                  child: SizedBox(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: colors.primaryContainer,
                                  borderRadius:
                                  BorderRadius.circular(18),
                                ),
                                child: Icon(
                                  _showAnswer
                                      ? Icons.menu_book_outlined
                                      : Icons.help_outline,
                                  size: 36,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),

                              const SizedBox(height: 24),

                              Text(
                                _showAnswer
                                    ? 'RISPOSTA'
                                    : 'DOMANDA',
                                style: theme.textTheme.labelLarge
                                    ?.copyWith(
                                  color: colors.primary,
                                  letterSpacing: 1.5,
                                ),
                              ),

                              const SizedBox(height: 20),

                              Text(
                                _showAnswer
                                    ? card.answer
                                    : card.question,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 28),

                              Text(
                                _showAnswer
                                    ? 'Tocca per rivedere la domanda'
                                    : 'Tocca per mostrare la risposta',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Navigazione indipendente dalla visualizzazione
          // della risposta: è possibile saltare una domanda.
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _currentIndex > 0
                      ? _previous
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Precedente'),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: FilledButton.icon(
                  onPressed: _next,
                  icon: Icon(
                    isLast
                        ? Icons.check
                        : Icons.arrow_forward,
                  ),
                  label: Text(
                    isLast ? 'Termina' : 'Successiva',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /*
   * Riepilogo al termine del mazzo.
   *
   * Non mostriamo un punteggio, perché l'app
   * non valuta ancora le risposte dell'utente.
   */
  Widget _buildFinished(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: colors.primary,
            ),

            const SizedBox(height: 24),

            Text(
              'Ripasso terminato!',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              'Hai raggiunto la fine delle '
                  '${widget.cards.length} flashcard.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _restart,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Ricomincia'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Torna alle flashcard',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
