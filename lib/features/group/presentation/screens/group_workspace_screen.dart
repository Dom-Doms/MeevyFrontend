
import 'package:flutter/material.dart';

import '../../data/models/group_role.dart';
import '../../data/models/study_group.dart';


import 'package:dio/dio.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/groups_repository.dart';
import '../view_models/group_members_view_model.dart';
import '../widgets/group_dashboard.dart';
import '../widgets/group_members_view.dart';
import '../widgets/group_settings.dart';

// Schermate disponibili all'interno del gruppo.
enum GroupWorkspacePage {
  chat,
  dashboard,
  members,
  settings,
}


/*
 * Contenitore delle funzionalità di un gruppo.
 * Mostra inizialmente la chat e permette di
 * accedere alla dashboard dalla barra superiore.
 */
class GroupWorkspaceScreen extends StatelessWidget {

  final StudyGroup group;
  final GroupWorkspacePage page;

  final VoidCallback onBack;
  final ValueChanged<GroupWorkspacePage> onOpenPage;
  final VoidCallback? onEdit;

  const GroupWorkspaceScreen({
    super.key,
    required this.group,
    required this.page,
    required this.onBack,
    required this.onOpenPage,
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

        title: _buildTitle(context),

        actions: [
          // Dalla chat si accede alla dashboard.
          if (page == GroupWorkspacePage.chat)
            IconButton(
              tooltip: 'Dashboard del gruppo',
              onPressed: () {
                onOpenPage(GroupWorkspacePage.dashboard);
              },
              icon: const Icon(
                Icons.dashboard_outlined,
              ),
            ),

          // Accesso rapido alle impostazioni.
          if (page == GroupWorkspacePage.dashboard)
            IconButton(
              tooltip: 'Impostazioni',
              onPressed: () {
                onOpenPage(GroupWorkspacePage.settings);
              },
              icon: const Icon(
                Icons.settings_outlined,
              ),
            ),
        ],
      ),

      body: _buildPage(),
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




// Costruisce il titolo in base alla schermata aperta.
  Widget _buildTitle(BuildContext context) {
    switch (page) {
      case GroupWorkspacePage.chat:
        final memberLabel = group.memberCount == 1
            ? '1 membro'
            : '${group.memberCount} membri';

        return InkWell(
          onTap: () {
            onOpenPage(GroupWorkspacePage.dashboard);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$memberLabel · Informazioni gruppo',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall,
              ),
            ],
          ),
        );

      case GroupWorkspacePage.dashboard:
        return Text(group.name);

      case GroupWorkspacePage.members:
        return const Text('Membri');

      case GroupWorkspacePage.settings:
        return const Text('Impostazioni');
    }
  }

// Seleziona il contenuto della schermata.
  Widget _buildPage() {
    switch (page) {
      case GroupWorkspacePage.chat:
        return Builder(
          builder: _buildChat,
        );

      case GroupWorkspacePage.dashboard:
        return GroupDashboard(
          group: group,
          onOpenMembers: () {
            onOpenPage(GroupWorkspacePage.members);
          },
          onOpenSettings: () {
            onOpenPage(GroupWorkspacePage.settings);
          },
        );

      case GroupWorkspacePage.members:
        return ChangeNotifierProvider(
          create: (context) => GroupMembersViewModel(
            GroupsRepository(context.read<Dio>()),
            group.id,
          )..load(),
          child: const GroupMembersView(),
        );

      case GroupWorkspacePage.settings:
        return GroupSettings(
          group: group,
          onEdit: onEdit,
        );
    }
  }

}
