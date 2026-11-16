
/*
 * Rappresenta una singola attività della checklist.
 */
class ChecklistItem {
  final int id;
  final int checklistId;
  final String text;
  final bool completed;

  const ChecklistItem({
    required this.id,
    required this.checklistId,
    required this.text,
    required this.completed,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as int,
      checklistId: json['checklistId'] as int,
      text: json['text'] as String,
      completed: json['completed'] as bool,
    );
  }
}
