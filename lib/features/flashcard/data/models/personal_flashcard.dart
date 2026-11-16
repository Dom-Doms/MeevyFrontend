
/*
 * Flashcard personale associata a una materia.
 * Contiene domanda, risposta e metadati del backend.
 */
class PersonalFlashcard {
  final int id;
  final int? subjectId;
  final String question;
  final String answer;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PersonalFlashcard({
    required this.id,
    required this.subjectId,
    required this.question,
    required this.answer,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PersonalFlashcard.fromJson(
      Map<String, dynamic> json,
      ) {
    return PersonalFlashcard(
      id: json['id'] as int,
      subjectId: json['subjectId'] as int?,
      question: json['question'] as String,
      answer: json['answer'] as String,
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] as String,
      ),
    );
  }
}
