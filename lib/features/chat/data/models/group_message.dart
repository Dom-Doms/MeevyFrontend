
/*
 * Rappresenta un messaggio persistente della chat di gruppo.
 * I campi corrispondono a GroupMessageResponse del backend.
 */
class GroupMessage {
  final int id;
  final int groupId;
  final int senderUserId;
  final String senderFirstName;
  final String senderLastName;
  final String content;
  final DateTime createdAt;

  const GroupMessage({
    required this.id,
    required this.groupId,
    required this.senderUserId,
    required this.senderFirstName,
    required this.senderLastName,
    required this.content,
    required this.createdAt,
  });

  // Converte il JSON restituito dalle API REST.
  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'] as int,
      groupId: json['groupId'] as int,
      senderUserId: json['senderUserId'] as int,
      senderFirstName: json['senderFirstName'] as String? ?? '',
      senderLastName: json['senderLastName'] as String? ?? '',
      content: json['content'] as String,
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
    );
  }

  String get senderName =>
      '$senderFirstName $senderLastName'.trim();

  // Permette alla View di distinguere messaggi propri e altrui.
  bool isMine(int currentUserId) =>
      senderUserId == currentUserId;
}
