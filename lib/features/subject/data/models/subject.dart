
/*
 * Rappresenta una materia personale dell'utente.
 * I campi corrispondono al SubjectResponse del backend.
 */
class Subject {
  final int id;
  final String name;

  const Subject({
    required this.id,
    required this.name,
  });

  // Converte il JSON ricevuto dal backend.
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
