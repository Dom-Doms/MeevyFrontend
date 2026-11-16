
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/models/group_invitation.dart';

/*
 * Mostra il codice generato e permette
 * di copiarlo negli appunti del dispositivo.
 */
class GroupInvitationDialog extends StatelessWidget {
  final GroupInvitation invitation;

  const GroupInvitationDialog({
    super.key,
    required this.invitation,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(
      context,
    );

    final expiration = invitation.expiresAt.toLocal();

    final date = localizations.formatShortDate(
      expiration,
    );

    final time = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(expiration),
    );

    return AlertDialog(
      title: const Text('Invita un partecipante'),

      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Condividi questo codice con la persona '
                  'che vuoi invitare nel gruppo.',
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText(
                invitation.token,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text('Scadenza: $date alle $time'),

            const SizedBox(height: 8),

            const Text(
              'Il codice può essere utilizzato '
                  'una sola volta.',
            ),
          ],
        ),
      ),

      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Chiudi'),
        ),

        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(
                text: invitation.token,
              ),
            );

            if (!context.mounted) return;

            ScaffoldMessenger.of(context)
                .showSnackBar(
              const SnackBar(
                content: Text(
                  'Codice copiato negli appunti.',
                ),
              ),
            );
          },
          icon: const Icon(Icons.copy),
          label: const Text('Copia'),
        ),
      ],
    );
  }
}
