
/*
 * Rappresenta un invito generato dal backend.
 * Il token permette a un altro utente di unirsi al gruppo.
 */
class GroupInvitation {
  final int groupId;
  final String token;
  final DateTime expiresAt;

  const GroupInvitation({
    required this.groupId,
    required this.token,
    required this.expiresAt,
  });

  factory GroupInvitation.fromJson(
      Map<String, dynamic> json,
      ) {
    return GroupInvitation(
      groupId: json['groupId'] as int,
      token: json['token'] as String,
      expiresAt: DateTime.parse(
        json['expiresAt'] as String,
      ),
    );
  }
}
