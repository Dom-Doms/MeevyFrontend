
import 'package:flutter/material.dart';

import '../../data/models/group_role.dart';
import '../../data/models/study_group.dart';

/*
 * Contenitore delle funzionalità di un gruppo.
 * Mostra inizialmente la chat e permette di
 * accedere alla dashboard dalla barra superiore.
 */
class GroupWorkspaceScreen extends StatelessWidget {
  final StudyGroup group;
  final bool showDashboard;

  final VoidCallback onBack;
  final VoidCallback onOpenDashboard;
  final VoidCallback? onEdit;

  const GroupWorkspaceScreen({
    super.key,
    required this.group,
    required this.showDashboard,
    required this.onBack,
    required this.onOpenDashboard,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),

        // Il nome del gruppo apre la dashboard.
        title: showDashboard
            ? Text(group.name)
            : InkWell(
          onTap: onOpenDashboard,
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${group.memberCount} membri'
                    ' · Informazioni gruppo',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        ),

        actions: [
          if (!showDashboard)
            IconButton(
              tooltip: 'Dashboard del gruppo',
              onPressed: onOpenDashboard,
              icon: const Icon(
                Icons.dashboard_outlined,
              ),
            ),
        ],
      ),

      body: showDashboard
          ? _buildDashboard(context)
          : _buildChat(context),
    );
  }

  /*
   * Struttura della chat.
   * L'invio sarà abilitato quando saranno
   * disponibili le API dei messaggi.
   */
  Widget _buildChat(BuildContext context) {
    return Column(
      children: [
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 56,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Chat non ancora disponibile.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),

        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    enabled: false,
                    decoration: InputDecoration(
                      hintText: 'Scrivi un messaggio...',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: null,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Mostra le informazioni e le azioni consentite.
  Widget _buildDashboard(BuildContext context) {
    final description = group.description;
    final isOwner = group.myRole == GroupRole.owner;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(context)
                .colorScheme
                .primaryContainer,
            child: const Icon(
              Icons.groups,
              size: 36,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Text(
          group.name,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall,
        ),

        const SizedBox(height: 8),

        Center(
          child: Chip(
            label: Text(group.myRole.label),
          ),
        ),

        const SizedBox(height: 24),

        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
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
            leading: const Icon(Icons.people_outline),
            title: const Text('Membri del gruppo'),
            subtitle: Text(
              '${group.memberCount} partecipanti',
            ),
          ),
        ),

        // Il backend permette la modifica solo all'OWNER.
        if (isOwner) ...[
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
