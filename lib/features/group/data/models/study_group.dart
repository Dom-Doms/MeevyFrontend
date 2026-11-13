
import 'group_role.dart';

// Rappresenta un gruppo di studio, corrisponde al DTO StudyGroupResponse del backend

class StudyGroup {
  final int id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final GroupRole myRole;
  final int memberCount;

  const StudyGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.myRole,
    required this.memberCount,
  });

  // Converte la risposta JSON in un gruppo di studio.
  factory StudyGroup.fromJson(Map<String, dynamic> json) {
    return StudyGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      myRole: GroupRole.fromJson(json['myRole'] as String),
      memberCount: json['memberCount'] as int,
    );
  }
}
