import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/pomodoro_session.dart';
import '../view_models/pomodoro_view_model.dart';
import '../widgets/pomodoro_setup_form.dart';
import '../widgets/pomodoro_timer_ring.dart';

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
                    child: Center(child: _buildContent(context, pomodoro)),
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
  Widget _buildContent(BuildContext context, PomodoroViewModel pomodoro) {
    if (pomodoro.isLoading) {
      return const CircularProgressIndicator();
    }

    if (pomodoro.errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pomodoro.errorMessage!, textAlign: TextAlign.center),

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
 * Mostra il form quando non esiste una sessione corrente.
 *
 * Lo scroll evita problemi su schermi Android piccoli.
 */
  Widget _buildEmptyState(BuildContext context) {
    return const SizedBox(
      width: double.infinity,
      child: SingleChildScrollView(child: PomodoroSetupForm()),
    );
  }

  String _formatClock(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8E3EF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF4D8B67)),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF6C6672)),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
  /*
   * Visualizza i dati della sessione recuperata.
   *
   * Per ora il tempo è una fotografia della
   * risposta HTTP: non è ancora un countdown.
   */

  /*
 * Visualizza la sessione Pomodoro utilizzando
 * il timer circolare e le schede informative.
 *
 * I dati e il countdown continuano a provenire
 * dal PomodoroViewModel.
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

    final phase = pomodoro.displayPhase;

    final phaseLabel = session.status == PomodoroStatus.ready
        ? 'Pronto a studiare'
        : phase == PomodoroPhase.breakTime
        ? 'Pausa programmata'
        : 'Studio';

    // Prima dell'avvio mostriamo la durata configurata.
    final remainingPhase = session.status == PomodoroStatus.ready
        ? session.studyDurationSeconds
        : pomodoro.displayRemainingPhaseSeconds;

    final phaseDuration = phase == PomodoroPhase.breakTime
        ? session.breakDurationSeconds
        : session.studyDurationSeconds;

    // Progresso della fase corrente da 0.0 a 1.0.
    final progress =
        session.status == PomodoroStatus.ready || phaseDuration <= 0
        ? 0.0
        : (1 - remainingPhase / phaseDuration).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),

          // TIMER CIRCOLARE
          Center(
            child: PomodoroTimerRing(
              phaseLabel: phaseLabel,
              timeText: _formatClock(remainingPhase),
              statusText: statusLabel,
              progress: progress,
            ),
          ),

          const SizedBox(height: 28),

          // DURATA STUDIO E PAUSA
          Row(
            children: [
              _buildInfoCard(
                icon: Icons.menu_book_outlined,
                title: 'Durata studio',
                value: '${session.studyDurationSeconds ~/ 60} min',
              ),
              const SizedBox(width: 12),
              _buildInfoCard(
                icon: Icons.free_breakfast_outlined,
                title: 'Pausa breve',
                value: '${session.breakDurationSeconds ~/ 60} min',
              ),
            ],
          ),

          const SizedBox(height: 16),

          // MATERIA ASSOCIATA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E3EF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.school_outlined, color: Color(0xFF4D8B67)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Materia associata',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6C6672),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        session.subjectId == null
                            ? 'Nessuna materia'
                            : 'Materia #${session.subjectId}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // CARICAMENTO DELLE OPERAZIONI HTTP
          if (pomodoro.isPerformingAction) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 12),
          ],

          // ERRORI DELLE OPERAZIONI
          if (pomodoro.actionError != null) ...[
            Text(
              pomodoro.actionError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],

          // CONTROLLI DELLA SESSIONE
          if (session.status == PomodoroStatus.ready ||
              session.status == PomodoroStatus.running ||
              session.status == PomodoroStatus.paused)
            Row(
              children: [
                // Pulsante principale: cambia in base allo stato.
                Expanded(
                  child: FilledButton.icon(
                    onPressed: pomodoro.isPerformingAction
                        ? null
                        : switch (session.status) {
                            PomodoroStatus.ready => pomodoro.startSession,
                            PomodoroStatus.running => pomodoro.pauseSession,
                            PomodoroStatus.paused => pomodoro.resumeSession,
                            _ => null,
                          },
                    icon: Icon(
                      session.status == PomodoroStatus.running
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
                    label: Text(switch (session.status) {
                      PomodoroStatus.ready => 'Avvia',
                      PomodoroStatus.running => 'Pausa',
                      PomodoroStatus.paused => 'Riprendi',
                      _ => '',
                    }),
                  ),
                ),

                const SizedBox(width: 12),

                // Annullamento sempre disponibile per sessioni attive.
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: pomodoro.isPerformingAction
                        ? null
                        : () async {
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
                                    child: const Text('Conferma'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true && context.mounted) {
                              await context
                                  .read<PomodoroViewModel>()
                                  .cancelSession();
                            }
                          },
                    icon: const Icon(Icons.close),
                    label: const Text('Annulla'),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 20),

          // TEMPO TOTALE RIMANENTE
          Center(
            child: Text(
              'Tempo totale residuo: '
              '${_formatDuration(pomodoro.displayRemainingSessionSeconds)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
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
