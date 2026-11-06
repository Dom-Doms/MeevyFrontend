
enum PomodoroStatus {
  ready,
  running,
  paused,
  completed,
  cancelled,
}

enum PomodoroPhase {
  study,
  breakTime,
}

class PomodoroSession {
  final int id;
  final int? subjectId;
  final PomodoroStatus status;
  final PomodoroPhase? phase;

  final int studyDurationSeconds;
  final int breakDurationSeconds;
  final int targetDurationSeconds;

  final int remainingPhaseSeconds;
  final int remainingSessionSeconds;

  const PomodoroSession({
    required this.id,
    required this.subjectId,
    required this.status,
    required this.phase,
    required this.studyDurationSeconds,
    required this.breakDurationSeconds,
    required this.targetDurationSeconds,
    required this.remainingPhaseSeconds,
    required this.remainingSessionSeconds,
  });

  factory PomodoroSession.fromJson(Map<String, dynamic> json) {
    return PomodoroSession(
      id: json['id'] as int,
      subjectId: json['subjectId'] as int?,
      status: PomodoroStatus.values.byName(
        (json['status'] as String).toLowerCase(),
      ),
      phase: switch (json['phase']) {
        'STUDY' => PomodoroPhase.study,
        'BREAK' => PomodoroPhase.breakTime,
        null => null,
        _ => throw const FormatException('Fase Pomodoro non valida'),
      },
      studyDurationSeconds: json['studyDurationSeconds'] as int,
      breakDurationSeconds: json['breakDurationSeconds'] as int,
      targetDurationSeconds: json['targetDurationSeconds'] as int,
      remainingPhaseSeconds: json['remainingPhaseSeconds'] as int,
      remainingSessionSeconds: json['remainingSessionSeconds'] as int,
    );
  }
}
