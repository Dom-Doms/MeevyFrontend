
import 'package:dio/dio.dart';

/*
 * Traduce gli errori delle API dei gruppi
 * in messaggi comprensibili per l'utente.
 */
String groupErrorMessage(
    Object error, {
      required String fallback,
    }) {
  if (error is! DioException) {
    return fallback;
  }

  final data = error.response?.data;

  final code = data is Map
      ? data['code']
      : null;

  switch (code) {
    case 'INVALID_GROUP_INVITATION':
      return 'Il codice di invito non è valido.';

    case 'GROUP_INVITATION_EXPIRED':
      return 'Questo invito è scaduto.';

    case 'GROUP_INVITATION_USED':
      return 'Questo invito è già stato utilizzato.';

    case 'ALREADY_GROUP_MEMBER':
      return 'Fai già parte di questo gruppo.';

    case 'GROUP_ACCESS_DENIED':
      return 'Non hai i permessi per questa operazione.';

    case 'GROUP_NOT_FOUND':
      return 'Il gruppo non esiste o non è più accessibile.';

    case 'GROUP_MEMBER_NOT_FOUND':
      return 'L’utente non appartiene più al gruppo.';

    case 'INVALID_GROUP_ROLE':
      return 'Non è possibile assegnare questo ruolo.';

    case 'OWNER_CANNOT_LEAVE':
      return 'Trasferisci la proprietà prima di abbandonare il gruppo.';

    case 'INVALID_OWNERSHIP_TRANSFER':
      return 'Non è possibile trasferire la proprietà a questo utente.';

    case 'VALIDATION_ERROR':
      return 'Controlla i dati inseriti.';
  }

  if (error.response == null) {
    return 'Impossibile contattare il server. '
        'Verifica la connessione.';
  }

  if (error.response?.statusCode == 403) {
    return 'Non hai i permessi necessari.';
  }

  return fallback;
}
