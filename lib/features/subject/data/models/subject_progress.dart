
/*
 * Rappresenta il riepilogo della checklist di una materia.
 * La percentuale viene calcolata a partire dai conteggi.
 */
class SubjectProgress {
  final int subjectId;
  final int total;
  final int completed;

  const SubjectProgress({
    required this.subjectId,
    required this.total,
    required this.completed,
  });

  factory SubjectProgress.fromJson(
      Map<String, dynamic> json,
      ) {
    return SubjectProgress(
      subjectId: json['subjectId'] as int,
      total: json['total'] as int,
      completed: json['completed'] as int,
    );
  }

  // Nessuna attività significa progresso non definito.
  double? get fraction {
    if (total <= 0 ||
        completed < 0 ||
        completed > total) {
      return null;
    }

    return completed / total;
  }

  int? get percentage {
    final value = fraction;
    return value == null ? null : (value * 100).round();
  }
}
