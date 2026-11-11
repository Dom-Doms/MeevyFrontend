import 'dart:async';

import 'package:flutter/material.dart';

import 'pomodoro_timer_ring.dart';

/*
 * Stati del Pomodoro ospite.
 *
 * Sono locali e non corrispondono a sessioni del backend.
 */
enum _GuestTimerStatus { ready, running, paused }

/*
 * Timer Pomodoro utilizzabile senza autenticazione.
 *
 * Alterna automaticamente studio e pausa.
 * Non effettua richieste HTTP e non salva sessioni.
 */
class GuestPomodoroTimer extends StatefulWidget {
  const GuestPomodoroTimer({super.key});

  @override
  State<GuestPomodoroTimer> createState() => _GuestPomodoroTimerState();
}

class _GuestPomodoroTimerState extends State<GuestPomodoroTimer>
    with WidgetsBindingObserver {
  final Stopwatch _stopwatch = Stopwatch();

  Timer? _ticker;

  _GuestTimerStatus _status = _GuestTimerStatus.ready;

  int _studyMinutes = 25;
  int _breakMinutes = 5;

  final List<int> _studyOptions = [15, 25, 40, 50];
  final List<int> _breakOptions = [5, 10, 15];

  bool get _isRunning => _status == _GuestTimerStatus.running;

  bool get _canConfigure => _status == _GuestTimerStatus.ready;

  /*
   * Determina la fase corrente utilizzando il tempo
   * effettivamente trascorso dall'avvio.
   */
  bool get _isBreak {
    final studySeconds = _studyMinutes * 60;
    final cycleSeconds = (_studyMinutes + _breakMinutes) * 60;

    final position = _stopwatch.elapsed.inSeconds % cycleSeconds;

    return position >= studySeconds;
  }

  int get _remainingSeconds {
    final studySeconds = _studyMinutes * 60;
    final cycleSeconds = (_studyMinutes + _breakMinutes) * 60;

    final position = _stopwatch.elapsed.inSeconds % cycleSeconds;

    if (position < studySeconds) {
      return studySeconds - position;
    }

    return cycleSeconds - position;
  }

  double get _progress {
    if (_status == _GuestTimerStatus.ready) return 0.0;

    final phaseDuration = (_isBreak ? _breakMinutes : _studyMinutes) * 60;

    return (1 - _remainingSeconds / phaseDuration).clamp(0.0, 1.0);
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');

    return '$minutes:$remaining';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  /*
   * Aggiorna la schermata quando Android riporta
   * l'app in primo piano.
   *
   * Stopwatch misura il tempo trascorso anche quando
   * i callback periodici vengono temporaneamente sospesi.
   */
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  /*
   * Avvia oppure riprende il timer.
   */
  void _startOrResume() {
    if (_isRunning) return;

    _stopwatch.start();

    _ticker?.cancel();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });

    setState(() {
      _status = _GuestTimerStatus.running;
    });
  }

  /*
   * Sospende il timer conservando il tempo trascorso.
   */
  void _pause() {
    if (!_isRunning) return;

    _stopwatch.stop();
    _ticker?.cancel();
    _ticker = null;

    setState(() {
      _status = _GuestTimerStatus.paused;
    });
  }

  /*
   * Azzera il timer e permette una nuova configurazione.
   */
  void _reset() {
    _ticker?.cancel();
    _ticker = null;

    _stopwatch.stop();
    _stopwatch.reset();

    setState(() {
      _status = _GuestTimerStatus.ready;
    });
  }

  /*
   * Card per modificare studio e pausa prima dell'avvio.
   */
  Widget _buildDurationCard({
    required IconData icon,
    required String title,
    required int value,
    required List<int> options,
    required ValueChanged<int> onChanged,
  }) {
    final index = options.indexOf(value);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E3EF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4D8B67), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6C6672),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _canConfigure && index > 0
                    ? () => onChanged(options[index - 1])
                    : null,
                icon: const Icon(Icons.remove),
                iconSize: 19,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
              ),

              Text(
                '$value min',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),

              IconButton(
                onPressed: _canConfigure && index < options.length - 1
                    ? () => onChanged(options[index + 1])
                    : null,
                icon: const Icon(Icons.add),
                iconSize: 19,
                color: const Color(0xFF4D8B67),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phaseLabel = _isBreak ? 'Pausa programmata' : 'Studio';

    final statusLabel = switch (_status) {
      _GuestTimerStatus.ready => 'Pronto',
      _GuestTimerStatus.running => 'In corso',
      _GuestTimerStatus.paused => 'In pausa',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Concentrati sui tuoi obiettivi di studio.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),

        const SizedBox(height: 24),

        Center(
          child: PomodoroTimerRing(
            phaseLabel: phaseLabel,
            timeText: _formatDuration(_remainingSeconds),
            statusText: statusLabel,
            progress: _progress,
          ),
        ),

        const SizedBox(height: 28),

        Row(
          children: [
            Expanded(
              child: _buildDurationCard(
                icon: Icons.menu_book_outlined,
                title: 'Durata studio',
                value: _studyMinutes,
                options: _studyOptions,
                onChanged: (value) {
                  setState(() {
                    _studyMinutes = value;
                  });
                },
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: _buildDurationCard(
                icon: Icons.free_breakfast_outlined,
                title: 'Pausa breve',
                value: _breakMinutes,
                options: _breakOptions,
                onChanged: (value) {
                  setState(() {
                    _breakMinutes = value;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _isRunning ? _pause : _startOrResume,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4D8B67),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(
                  _isRunning
                      ? 'Pausa'
                      : _status == _GuestTimerStatus.paused
                      ? 'Riprendi'
                      : 'Avvia',
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: OutlinedButton.icon(
                onPressed: _canConfigure ? null : _reset,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.restart_alt),
                label: const Text('Azzera'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        Text(
          'Modalità ospite: il timer funziona senza account. '
          'Le sessioni non vengono salvate.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _ticker?.cancel();
    _stopwatch.stop();

    super.dispose();
  }
}
