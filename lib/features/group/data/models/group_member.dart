
import 'group_role.dart';

// Rappresenta un utente appartenente ad un gruppo

class GroupMember {
  final int userId;
  final String firstName;
  final String lastName;
  final GroupRole role;
  final DateTime joinedAt;

  const GroupMember({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.joinedAt,
  });

  String get fullName => '$firstName $lastName';

  // Converte il DTO ricevuto dal backend.
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: GroupRole.fromJson(json['role'] as String),
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
