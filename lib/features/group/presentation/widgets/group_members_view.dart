
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/group_role.dart';
import '../view_models/group_members_view_model.dart';


import '../../data/models/group_member.dart';
import 'group_invitation_dialog.dart';


// Operazioni selezionabili dal menu di un partecipante.
enum _MemberAction {
  promote,
  demote,
  remove,
  transfer,
}


/*
 * Mostra i partecipanti del gruppo
 * e il ruolo di ciascuno.
 */
class GroupMembersView extends StatelessWidget {
  const GroupMembersView({super.key});

  // Seleziona un'icona in base al ruolo.
  IconData _roleIcon(GroupRole role) {
    switch (role) {
      case GroupRole.owner:
        return Icons.star_outline;

      case GroupRole.moderator:
        return Icons.shield_outlined;

      case GroupRole.member:
        return Icons.person_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel =
    context.watch<GroupMembersViewModel>();

    final theme = Theme.of(context);

    if (viewModel.isLoading &&
        viewModel.members.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (viewModel.errorMessage != null &&
        viewModel.members.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: viewModel.load,
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      );
    }

    final members = viewModel.members;

    return RefreshIndicator(
      onRefresh: viewModel.load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics:
        const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            members.length == 1
                ? '1 partecipante'
                : '${members.length} partecipanti',
            style: theme.textTheme.titleMedium,
          ),

          const SizedBox(height: 16),

          // NUOVO: pulsante per invitare partecipanti.
          if (viewModel.myRole != GroupRole.member) ...[
            FilledButton.icon(
              onPressed: viewModel.canInvite
                  ? () => _invite(context, viewModel)
                  : null,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Invita partecipante'),
            ),

            const SizedBox(height: 16),
          ],



          // indicatore di caricamento.
          if (viewModel.isLoading || viewModel.isSaving)
            const LinearProgressIndicator(),

          if (viewModel.errorMessage != null)
            Text(viewModel.errorMessage!),

          ...members.map(
                (member) => Card(
              margin: const EdgeInsets.only(
                bottom: 8,
              ),
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),

                leading: CircleAvatar(
                  child: Icon(
                    _roleIcon(member.role),
                  ),
                ),

                title: Text(member.fullName),

                subtitle: Text(
                  member.role.label,
                ),
                // NUOVO: menu di gestione del partecipante.
                trailing: _buildMemberMenu(
                context,
                viewModel,
                member,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _invite(
      BuildContext context,
      GroupMembersViewModel viewModel,
      ) async {
    final invitation = await viewModel.createInvitation();

    if (!context.mounted) return;

    if (invitation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.actionError ??
                'Impossibile generare l’invito.',
          ),
        ),
      );

      return;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => GroupInvitationDialog(
        invitation: invitation,
      ),
    );
  }


/*
 * Costruisce il menu del partecipante
 * mostrando soltanto le azioni consentite.
 */
  Widget? _buildMemberMenu(
      BuildContext context,
      GroupMembersViewModel viewModel,
      GroupMember member,
      ) {
    final items = <PopupMenuEntry<_MemberAction>>[];

    if (viewModel.canChangeRole(member)) {
      if (member.role == GroupRole.member) {
        items.add(
          const PopupMenuItem(
            value: _MemberAction.promote,
            child: Text('Nomina moderatore'),
          ),
        );
      } else if (member.role == GroupRole.moderator) {
        items.add(
          const PopupMenuItem(
            value: _MemberAction.demote,
            child: Text('Revoca moderatore'),
          ),
        );
      }
    }

    if (viewModel.canTransferOwnership(member)) {
      items.add(
        const PopupMenuItem(
          value: _MemberAction.transfer,
          child: Text('Trasferisci proprietà'),
        ),
      );
    }

    if (viewModel.canRemove(member)) {
      items.add(
        const PopupMenuItem(
          value: _MemberAction.remove,
          child: Text('Rimuovi dal gruppo'),
        ),
      );
    }

    // Nessun menu se l'utente non ha operazioni disponibili.
    if (items.isEmpty) return null;

    return PopupMenuButton<_MemberAction>(
      tooltip: 'Gestisci partecipante',
      itemBuilder: (_) => items,
      onSelected: (action) {
        _handleMemberAction(
          context,
          viewModel,
          member,
          action,
        );
      },
    );
  }


  Future<void> _handleMemberAction(
      BuildContext context,
      GroupMembersViewModel viewModel,
      GroupMember member,
      _MemberAction action,
      ) async {
    final String title;
    final String message;
    final String successMessage;

    switch (action) {
      case _MemberAction.promote:
        title = 'Nomina moderatore';
        message =
        'Vuoi nominare ${member.fullName} moderatore?';
        successMessage = 'Moderatore nominato.';
        break;

      case _MemberAction.demote:
        title = 'Revoca moderatore';
        message =
        '${member.fullName} tornerà a essere un membro.';
        successMessage = 'Ruolo di moderatore revocato.';
        break;

      case _MemberAction.remove:
        title = 'Rimuovi partecipante';
        message =
        'Vuoi rimuovere ${member.fullName} dal gruppo?';
        successMessage = 'Partecipante rimosso.';
        break;

      case _MemberAction.transfer:
        title = 'Trasferisci proprietà';
        message =
        '${member.fullName} diventerà il proprietario '
            'del gruppo. Tu diventerai un membro e '
            'perderai i privilegi di gestione.';
        successMessage = 'Proprietà trasferita.';
        break;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
            child: const Text('Conferma'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final bool success;

    switch (action) {
      case _MemberAction.promote:
        success = await viewModel.changeRole(
          member,
          GroupRole.moderator,
        );
        break;

      case _MemberAction.demote:
        success = await viewModel.changeRole(
          member,
          GroupRole.member,
        );
        break;

      case _MemberAction.remove:
        success = await viewModel.removeMember(
          member,
        );
        break;

      case _MemberAction.transfer:
        success = await viewModel.transferOwnership(
          member,
        );
        break;
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? successMessage
              : viewModel.actionError ??
              'Operazione non completata.',
        ),
      ),
    );
  }


}
