
/*
 * Rappresenta i metadati di un file personale.
 * Corrisponde al ResourceResponse del backend.
 */
class PersonalResource {
  final int id;
  final String originalFilename;
  final String? contentType;
  final int sizeBytes;
  final int? subjectId;
  final DateTime createdAt;

  const PersonalResource({
    required this.id,
    required this.originalFilename,
    required this.contentType,
    required this.sizeBytes,
    required this.subjectId,
    required this.createdAt,
  });

  // Converte i metadati ricevuti dal server.
  factory PersonalResource.fromJson(
      Map<String, dynamic> json,
      ) {
    return PersonalResource(
      id: json['id'] as int,
      originalFilename: json['originalFilename'] as String,
      contentType: json['contentType'] as String?,
      sizeBytes: json['sizeBytes'] as int,
      subjectId: json['subjectId'] as int?,
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
    );
  }
}

