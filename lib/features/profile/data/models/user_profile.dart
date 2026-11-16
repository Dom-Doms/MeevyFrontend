
/*
 * Ruoli globali previsti dal backend Meevy.
 *
 * Sono distinti dai ruoli nei gruppi di studio.
 */
enum PlatformRole {
  user,
  admin,
}

// Stati possibili dell'account.

enum AccountStatus {
  active,
  suspended,
  banned,
}

//Rappresenta i dati restituiti da GET /user/me.

class UserProfile {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final PlatformRole platformRole;
  final AccountStatus accountStatus;

  const UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.platformRole,
    required this.accountStatus,
  });

  // Converte la risposta JSON del backend

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      platformRole: switch (json['platformRole']) {
        'USER' => PlatformRole.user,
        'ADMIN' => PlatformRole.admin,
        _ => throw const FormatException(
          'Ruolo utente non riconosciuto.',
        ),
      },
      accountStatus: switch (json['accountStatus']) {
        'ACTIVE' => AccountStatus.active,
        'SUSPENDED' => AccountStatus.suspended,
        'BANNED' => AccountStatus.banned,
        _ => throw const FormatException(
          'Stato account non riconosciuto.',
        ),
      },
    );
  }

  /*
   * Compone il nome visualizzato.
   * Nome e cognome possono essere null nel backend.
   */
  String get displayName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';

    final name = [first, last]
        .where((part) => part.isNotEmpty)
        .join(' ');

    return name.isEmpty ? 'Utente Meevy' : name;
  }

  /*
   * Genera le iniziali per l'avatar.
   * Non richiede immagini salvate sul server.
   */
  String get initials {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';

    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }

    if (first.isNotEmpty) return first[0].toUpperCase();
    if (last.isNotEmpty) return last[0].toUpperCase();

    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }

  String get roleLabel => switch (platformRole) {
    PlatformRole.user => 'Utente',
    PlatformRole.admin => 'Amministratore',
  };

  String get statusLabel => switch (accountStatus) {
    AccountStatus.active => 'Attivo',
    AccountStatus.suspended => 'Sospeso',
    AccountStatus.banned => 'Bannato',
  };
}
