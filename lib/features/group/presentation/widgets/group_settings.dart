
import 'package:flutter/material.dart';

import '../../data/models/group_role.dart';
import '../../data/models/study_group.dart';

/*
 * Informazioni e impostazioni del gruppo.
 * Le operazioni disponibili dipendono dal ruolo.
 */
class GroupSettings extends StatelessWidget {
  final StudyGroup group;
  final VoidCallback? onEdit;

  const GroupSettings({
    super.key,
    required this.group,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = group.description;

    final isOwner =
        group.myRole == GroupRole.owner;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Informazioni del gruppo',
          style: theme.textTheme.titleLarge,
        ),

        const SizedBox(height: 16),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.groups_outlined,
            ),
            title: const Text('Nome'),
            subtitle: Text(group.name),
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.info_outline,
            ),
            title: const Text('Descrizione'),
            subtitle: Text(
              description == null ||
                  description.isEmpty
                  ? 'Nessuna descrizione.'
                  : description,
            ),
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(
              Icons.badge_outlined,
            ),
            title: const Text('Il tuo ruolo'),
            subtitle: Text(group.myRole.label),
          ),
        ),

        // Solo il proprietario può modificare il gruppo.
        if (isOwner) ...[
          const SizedBox(height: 24),

          Text(
            'Gestione del gruppo',
            style: theme.textTheme.titleLarge,
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Modifica gruppo'),
          ),
        ],
      ],
    );
  }
}
