
//Rappresenta i dati restituiti dal backend dopo una registrazione.

class RegisterResponse {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;

  const RegisterResponse({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
  });

  // Converte la risposta JSON in un oggetto Dart.
  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }
}
