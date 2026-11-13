
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/group_role.dart';
import '../view_models/group_members_view_model.dart';

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

          if (viewModel.isLoading)
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
