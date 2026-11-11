import 'package:flutter/material.dart';

/*
 * Widget grafico circolare per mostrare il timer Pomodoro.
 *
 * Mostra:
 * - progresso della fase corrente;
 * - tempo rimanente;
 * - etichetta della fase;
 * - stato della sessione.
 */
class PomodoroTimerRing extends StatelessWidget {
  const PomodoroTimerRing({
    super.key,
    required this.phaseLabel,
    required this.timeText,
    required this.statusText,
    required this.progress,
  });

  final String phaseLabel;
  final String timeText;
  final String statusText;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const ringColor = Color(0xFF4D8B67);
    final backgroundRingColor = Colors.grey.shade200;

    return SizedBox(
      width: 230,
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 230,
            height: 230,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 10,
              backgroundColor: backgroundRingColor,
              valueColor: const AlwaysStoppedAnimation(ringColor),
            ),
          ),

          // Contenuto centrale
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: ringColor.withValues(alpha: 0.14),
                child: const Icon(Icons.eco, color: ringColor, size: 18),
              ),
              const SizedBox(height: 12),
              Text(
                timeText,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F1B24),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                phaseLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                statusText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
