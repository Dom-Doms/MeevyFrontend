
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import '../widgets/join_group_dialog.dart';

import '../../data/models/study_group.dart';
import '../view_models/groups_view_model.dart';
import '../widgets/group_form_dialog.dart';
import 'group_workspace_screen.dart';

/*
 * Visualizza i gruppi dell'utente e gestisce
 * l'apertura della chat e della dashboard.
 */
class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  int? _selectedGroupId;
  GroupWorkspacePage _page = GroupWorkspacePage.chat;


  // Apre il gruppo mostrando inizialmente la chat.
  void _openGroup(StudyGroup group) {
    setState(() {
      _selectedGroupId = group.id;
      _page = GroupWorkspacePage.chat;
    });
  }


/*
 * Gestisce la navigazione all'indietro.
 *
 * Membri/Impostazioni -> Dashboard
 * Dashboard -> Chat
 * Chat -> Elenco gruppi
 */
  void _goBack() {
    setState(() {
      switch (_page) {
        case GroupWorkspacePage.members:
        case GroupWorkspacePage.settings:
          _page = GroupWorkspacePage.dashboard;
          break;

        case GroupWorkspacePage.dashboard:
          _page = GroupWorkspacePage.chat;
          break;

        case GroupWorkspacePage.chat:
          _selectedGroupId = null;
          break;
      }
    });
  }


  // Mostra il form e delega il salvataggio al ViewModel.
  Future<void> _showGroupForm({
    StudyGroup? group,
  }) async {
    final result = await showDialog<
        ({String name, String? description})>(
      context: context,
      builder: (_) => GroupFormDialog(group: group),
    );

    if (result == null || !mounted) return;

    final viewModel = context.read<GroupsViewModel>();

    final saved = await viewModel.save(
      groupId: group?.id,
      name: result.name,
      description: result.description,
    );

    if (!mounted) return;

    if (saved == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.saveError ??
                'Operazione non completata.',
          ),
        ),
      );
      return;
    }

    // Dopo la creazione apre direttamente il nuovo gruppo.
    if (group == null) {
      _openGroup(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<GroupsViewModel>();

    final selectedGroup = _selectedGroupId == null
        ? null
        : viewModel.findById(_selectedGroupId!);

    /*
     * Mantiene la navigazione del gruppo dentro
     * la sezione Gruppi della MainShell.
     */

    if (selectedGroup != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _goBack();
        },
        child: GroupWorkspaceScreen(
          group: selectedGroup,

          page: _page,

          onBack: _goBack,

          onOpenPage: (newPage) {
            setState(() {
              _page = newPage;
            });
          },

          onEdit: viewModel.isSaving
              ? null
              : () => _showGroupForm(
            group: selectedGroup,
          ),

          onLeave: viewModel.isSaving || viewModel.isLoading
              ? null
              : () => _leaveGroup(selectedGroup
          ),

        ),
      );
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('I miei gruppi'),
        actions: [

          IconButton(
            tooltip: 'Unisciti a un gruppo',
            onPressed: viewModel.isLoading ||
                viewModel.isSaving
                ? null
                : _joinGroup,
            icon: const Icon(
              Icons.group_add_outlined,
            ),
          ),

          IconButton(
            tooltip: 'Aggiorna',
            onPressed: viewModel.isLoading ||
                viewModel.isSaving
                ? null
                : viewModel.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: viewModel.isSaving ||
            viewModel.isLoading
            ? null
            : () => _showGroupForm(),
        icon: const Icon(Icons.add),
        label: const Text('Crea gruppo'),
      ),

      body: _buildGroupList(viewModel),
    );
  }

  Widget _buildGroupList(GroupsViewModel viewModel) {
    if (viewModel.isLoading && viewModel.groups.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.errorMessage != null &&
        viewModel.groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(viewModel.errorMessage!),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: viewModel.load,
              child: const Text('Riprova'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          16, 16, 16, 96,
        ),
        children: [
          if (viewModel.isSaving)
            const LinearProgressIndicator(),

          if (viewModel.errorMessage != null)
            Text(viewModel.errorMessage!),

          if (viewModel.groups.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Column(
                children: [
                  Icon(Icons.groups_outlined, size: 64),
                  SizedBox(height: 16),
                  Text('Non fai ancora parte di gruppi.'),
                  SizedBox(height: 8),
                  Text('Crea il tuo primo gruppo di studio!'),
                ],
              ),
            ),

          ...viewModel.groups.map(
                (group) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: const CircleAvatar(
                  child: Icon(Icons.groups_outlined),
                ),
                title: Text(group.name),
                subtitle: Text(
                  '${group.memberCount} membri'
                      ' · ${group.myRole.label}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _openGroup(group),
              ),
            ),
          ),
        ],
      ),
    );
  }

// Accetta il codice e apre il gruppo appena raggiunto.
  Future<void> _joinGroup() async {
    final token = await showDialog<String>(
      context: context,
      builder: (_) => const JoinGroupDialog(),
    );

    if (token == null || !mounted) return;

    final viewModel = context.read<GroupsViewModel>();

    final group = await viewModel.acceptInvitation(
      token,
    );

    if (!mounted) return;

    if (group == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.saveError ??
                'Impossibile unirsi al gruppo.',
          ),
        ),
      );

      return;
    }

    _openGroup(group);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ti sei unito a ${group.name}!',
        ),
      ),
    );
  }


// Chiede conferma prima di abbandonare il gruppo.
  Future<void> _leaveGroup(StudyGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Abbandona gruppo'),
        content: Text(
          'Vuoi abbandonare il gruppo ${group.name}? '
              'Per rientrare avrai bisogno di un nuovo invito.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Abbandona'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final viewModel = context.read<GroupsViewModel>();

    final success = await viewModel.leaveGroup(
      group.id,
    );

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.saveError ??
                'Impossibile abbandonare il gruppo.',
          ),
        ),
      );

      return;
    }

    // Torna all'elenco dei gruppi.
    setState(() {
      _selectedGroupId = null;
      _page = GroupWorkspacePage.chat;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hai abbandonato il gruppo.'),
      ),
    );
  }

}
