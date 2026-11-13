
import 'package:flutter/material.dart';

import '../../data/models/study_group.dart';

/*
 * Dashboard dello spazio di studio condiviso.
 * Organizza le funzionalità del gruppo in sezioni.
 */
class GroupDashboard extends StatelessWidget {
  final StudyGroup group;
  final VoidCallback onOpenMembers;
  final VoidCallback onOpenSettings;

  const GroupDashboard({
    super.key,
    required this.group,
    required this.onOpenMembers,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final memberLabel = group.memberCount == 1
        ? '1 membro'
        : '${group.memberCount} membri';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Intestazione compatta del gruppo.
        Text(
          '$memberLabel · ${group.myRole.label}',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),

        const SizedBox(height: 20),

        // Card principale del piano di studio.
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: colors.primaryContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.assignment_outlined,
                      color: colors.onPrimaryContainer,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Piano di studio',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Organizza le attività di studio '
                      'insieme al tuo gruppo.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Funzionalità in arrivo'),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Riepilogo della prossima scadenza.
        Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colors.outlineVariant,
            ),
          ),
          child: const ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Icon(
              Icons.event_available_outlined,
              size: 32,
            ),
            title: Text('Prossima scadenza'),
            subtitle: Text('Funzionalità in arrivo'),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Spazio di studio',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        /*
         * Griglia adattabile alla larghezza dello schermo.
         * Le funzionalità non implementate sono disabilitate.
         */
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = constraints.maxWidth >= 300
                ? (constraints.maxWidth - 12) / 2
                : constraints.maxWidth;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: itemWidth,
                  child: const _DashboardTile(
                    title: 'Appunti',
                    description: 'Materiale condiviso',
                    icon: Icons.folder_open_outlined,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _DashboardTile(
                    title: 'Flashcard',
                    description: 'Ripassa insieme',
                    icon: Icons.style_outlined,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _DashboardTile(
                    title: 'Pomodoro',
                    description: 'Sessioni di gruppo',
                    icon: Icons.timer_outlined,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: const _DashboardTile(
                    title: 'Calendario',
                    description: 'Eventi e scadenze',
                    icon: Icons.calendar_month_outlined,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _DashboardTile(
                    title: 'Membri',
                    description: memberLabel,
                    icon: Icons.groups_outlined,
                    onTap: onOpenMembers,
                  ),
                ),
                SizedBox(
                  width: itemWidth,
                  child: _DashboardTile(
                    title: 'Impostazioni',
                    description: 'Gestisci il gruppo',
                    icon: Icons.settings_outlined,
                    onTap: onOpenSettings,
                  ),
                ),
              ],
            );
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

/*
 * Componente grafico riutilizzabile
 * per tutte le funzionalità della dashboard.
 */
class _DashboardTile extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onTap;
  //Perché tutte le card della dashboard hanno la stessa struttura e cambiano soltanto icona, titolo, descrizione e operazione associata.
  const _DashboardTile({
    required this.title,
    required this.description,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isAvailable = onTap != null;

    final borderRadius = BorderRadius.circular(20);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
        side: BorderSide(
          color: colors.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 160,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius:
                    BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 26,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                if (!isAvailable) ...[
                  const SizedBox(height: 8),
                  Text(
                    'In arrivo',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(
                      color: colors.outline,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
