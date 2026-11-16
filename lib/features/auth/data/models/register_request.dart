
// Rappresenta i dati inviati al backend per registrare un nuovo utente.

class RegisterRequest {
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;

  const RegisterRequest({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
  });

  // Converte l'oggetto Dart nel JSON richiesto.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    };
  }
}
