
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/pomodoro_session.dart';
import '../view_models/pomodoro_view_model.dart';

/*
 * Schermata del Pomodoro personale autenticato.
 *
 * Mostra la sessione restituita dal backend oppure
 * lo stato iniziale quando non esiste una sessione.
 */
class PomodoroScreen extends StatelessWidget {
  const PomodoroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<PomodoroViewModel>(
          builder: (context, pomodoro, _) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Pomodoro personale',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: 8),

                  const Text('Concentrati sui tuoi obiettivi di studio.'),

                  const SizedBox(height: 32),

                  Expanded(
                    child: Center(
                      child: _buildContent(context, pomodoro),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /*
   * Decide cosa visualizzare in base allo stato
   * del ViewModel.
   */
  Widget _buildContent(
      BuildContext context,
      PomodoroViewModel pomodoro,
      ) {
    if (pomodoro.isLoading) {
      return const CircularProgressIndicator();
    }

    if (pomodoro.errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            pomodoro.errorMessage!,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          OutlinedButton(
            onPressed: pomodoro.loadCurrentSession,
            child: const Text('Riprova'),
          ),
        ],
      );
    }

    final session = pomodoro.currentSession;

    if (session == null) {
      return _buildEmptyState(context);
    }

    return _buildSession(context, pomodoro, session);
  }

  /*
   * Schermata mostrata quando GET /current
   * restituisce 204 No Content.
   */
  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),

        const SizedBox(height: 24),

        Text(
          'Pronto per studiare?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),

        const SizedBox(height: 12),

        const Text(
          'Non hai nessuna sessione Pomodoro in corso.',
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        const Text(
          'Nel prossimo passaggio aggiungeremo '
              'la configurazione di una nuova sessione.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /*
   * Visualizza i dati della sessione recuperata.
   *
   * Per ora il tempo è una fotografia della
   * risposta HTTP: non è ancora un countdown.
   */
  Widget _buildSession(
      BuildContext context,
      PomodoroViewModel pomodoro,
      PomodoroSession session,
      ) {
    final statusLabel = switch (session.status) {
      PomodoroStatus.ready => 'Pronto',
      PomodoroStatus.running => 'In corso',
      PomodoroStatus.paused => 'In pausa',
      PomodoroStatus.completed => 'Completato',
      PomodoroStatus.cancelled => 'Annullato',
    };

    final phaseLabel = switch (pomodoro.displayPhase) {
      PomodoroPhase.study => 'Studio',
      PomodoroPhase.breakTime => 'Pausa programmata',
      null => 'Sessione non avviata',
    };

    // In READY mostriamo la durata di studio dei secondi che mancano.
    final displaySeconds = session.status == PomodoroStatus.ready
        ? session.studyDurationSeconds
        : pomodoro.displayRemainingPhaseSeconds;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          phaseLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),

        const SizedBox(height: 20),

        Text(
          _formatDuration(displaySeconds),
          style: Theme.of(context).textTheme.displayLarge,
        ),

        const SizedBox(height: 16),

        Chip(label: Text(statusLabel)),


        //aggiunto ma da ricontrollare prima versione di prova

        const SizedBox(height: 20),

// Avvia una sessione configurata.
        if (session.status == PomodoroStatus.ready)
          FilledButton.icon(
            onPressed: pomodoro.startSession,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Avvia'),
          ),

// Mette in pausa una sessione in esecuzione.
        if (session.status == PomodoroStatus.running)
          FilledButton.icon(
            onPressed: pomodoro.pauseSession,
            icon: const Icon(Icons.pause),
            label: const Text('Pausa'),
          ),

// Possiamo riprendere soltanto una sessione sospesa.
        if (session.status == PomodoroStatus.paused)
          FilledButton.icon(
            onPressed: pomodoro.resumeSession,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Riprendi'),
          ),

// READY, RUNNING e PAUSED possono essere annullati.
        if (session.status == PomodoroStatus.ready ||
            session.status == PomodoroStatus.running ||
            session.status == PomodoroStatus.paused)
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Annullare la sessione?'),
                  content: const Text(
                    'La sessione verrà annullata '
                        'e il tempo di studio non sarà contabilizzato.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, false),
                      child: const Text('Indietro'),
                    ),
                    FilledButton(
                      onPressed: () =>
                          Navigator.pop(dialogContext, true),
                      child: const Text('Annulla sessione'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await context.read<PomodoroViewModel>().cancelSession();
              }
            },
            icon: const Icon(Icons.close),
            label: const Text('Annulla sessione'),
          ),




        const SizedBox(height: 32),

        Text(
          'Studio: ${session.studyDurationSeconds ~/ 60} min',
        ),

        Text(
          'Pausa: ${session.breakDurationSeconds ~/ 60} min',
        ),

        Text(
          'Tempo totale residuo: '
              '${_formatDuration(pomodoro.displayRemainingSessionSeconds)}',
        ),
      ],
    );
  }

  /*
   * Converte i secondi in mm:ss oppure h:mm:ss.
   */
  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final remainingSeconds = duration.inSeconds.remainder(60);

    final mm = minutes.toString().padLeft(2, '0');
    final ss = remainingSeconds.toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hours:$mm:$ss';
    }

    return '$mm:$ss';
  }
}
