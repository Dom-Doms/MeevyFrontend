
//Rappresenta il ruolo dell'utente in un gruppo

enum GroupRole {
  owner,
  moderator,
  member;

  // Converte il ruolo ricevuto dal backend.
  static GroupRole fromJson(String value) {
    switch (value) {
      case 'OWNER':
        return GroupRole.owner;
      case 'MODERATOR':
        return GroupRole.moderator;
      case 'MEMBER':
        return GroupRole.member;
      default:
        throw FormatException('Ruolo non riconosciuto: $value');
    }
  }

  // Etichetta da mostrare nell'interfaccia.
  String get label {
    switch (this) {
      case GroupRole.owner:
        return 'Creatore';
      case GroupRole.moderator:
        return 'Moderatore';
      case GroupRole.member:
        return 'Membro';
    }
  }
}
