
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meevy_app/features/group/data/models/group_member.dart';
import 'package:meevy_app/features/group/data/models/group_role.dart';
import 'package:meevy_app/features/group/data/models/study_group.dart';
import 'package:meevy_app/features/group/data/repositories/groups_repository.dart';
import 'package:meevy_app/features/group/presentation/view_models/group_members_view_model.dart';
import 'package:meevy_app/features/group/presentation/view_models/groups_view_model.dart';

// Costruisce un gruppo con un determinato ruolo.
StudyGroup createGroup(GroupRole role) {
  return StudyGroup(
    id: 1,
    name: 'Basi di dati',
    description: null,
    createdAt: DateTime.utc(2026),
    myRole: role,
    memberCount: 3,
  );
}

// Costruisce un partecipante per i test.
GroupMember createMember(
    int id,
    GroupRole role,
    ) {
  return GroupMember(
    userId: id,
    firstName: 'Utente',
    lastName: '$id',
    role: role,
    joinedAt: DateTime.utc(2026),
  );
}

// Repository finto: non contatta il backend.
class FakeGroupsRepository extends GroupsRepository {
  final StudyGroup group;

  bool failReload = false;
  int transferCalls = 0;
  int acceptCalls = 0;

  FakeGroupsRepository(this.group) : super(Dio());

  @override
  Future<StudyGroup> getById(int groupId) async {
    if (failReload) {
      throw StateError('Aggiornamento fallito');
    }

    return group;
  }

  @override
  Future<List<GroupMember>> getMembers(
      int groupId,
      ) async {
    return [
      createMember(1, GroupRole.owner),
      createMember(2, GroupRole.moderator),
      createMember(3, GroupRole.member),
    ];
  }

  @override
  Future<void> transferOwnership({
    required int groupId,
    required int newOwnerUserId,
  }) async {
    transferCalls++;

    // Simula un trasferimento riuscito,
    // seguito da un errore durante il caricamento.
    failReload = true;
  }

  @override
  Future<StudyGroup> acceptInvitation(
      String token,
      ) async {
    acceptCalls++;

    return createGroup(GroupRole.member);
  }
}

void main() {
  group('Permessi dei partecipanti', () {
    test(
      'Owner può gestire gli altri partecipanti',
          () async {
        final group = createGroup(GroupRole.owner);

        final repository = FakeGroupsRepository(
          group,
        );

        final viewModel = GroupMembersViewModel(
          repository,
          group,
              (_) {},
        );

        await viewModel.load();

        final owner = viewModel.members[0];
        final moderator = viewModel.members[1];
        final member = viewModel.members[2];

        expect(viewModel.canInvite, isTrue);

        expect(
          viewModel.canChangeRole(member),
          isTrue,
        );

        expect(
          viewModel.canRemove(moderator),
          isTrue,
        );

        expect(
          viewModel.canTransferOwnership(member),
          isTrue,
        );

        expect(
          viewModel.canRemove(owner),
          isFalse,
        );

        viewModel.dispose();
      },
    );

    test(
      'Moderator può espellere soltanto un Member',
          () async {
        final group = createGroup(
          GroupRole.moderator,
        );

        final viewModel = GroupMembersViewModel(
          FakeGroupsRepository(group),
          group,
              (_) {},
        );

        await viewModel.load();

        expect(viewModel.canInvite, isTrue);

        expect(
          viewModel.canRemove(viewModel.members[0]),
          isFalse,
        );

        expect(
          viewModel.canRemove(viewModel.members[1]),
          isFalse,
        );

        expect(
          viewModel.canRemove(viewModel.members[2]),
          isTrue,
        );

        expect(
          viewModel.canChangeRole(viewModel.members[2]),
          isFalse,
        );

        expect(
          viewModel.canTransferOwnership(
            viewModel.members[2],
          ),
          isFalse,
        );

        viewModel.dispose();
      },
    );

    test(
      'Member non può gestire altri partecipanti',
          () async {
        final group = createGroup(GroupRole.member);

        final repository = FakeGroupsRepository(
          group,
        );

        final viewModel = GroupMembersViewModel(
          repository,
          group,
              (_) {},
        );

        await viewModel.load();

        expect(viewModel.canInvite, isFalse);

        expect(
          viewModel.canChangeRole(viewModel.members[1]),
          isFalse,
        );

        expect(
          viewModel.canRemove(viewModel.members[1]),
          isFalse,
        );

        expect(
          await viewModel.transferOwnership(
            viewModel.members[1],
          ),
          isFalse,
        );

        expect(repository.transferCalls, 0);

        viewModel.dispose();
      },
    );
  });

  test(
    'Dopo il trasferimento il vecchio Owner '
        'diventa Member anche se il reload fallisce',
        () async {
      final group = createGroup(GroupRole.owner);

      final repository = FakeGroupsRepository(
        group,
      );

      StudyGroup? updatedGroup;

      final viewModel = GroupMembersViewModel(
        repository,
        group,
            (result) => updatedGroup = result,
      );

      await viewModel.load();

      final success =
      await viewModel.transferOwnership(
        viewModel.members[2],
      );

      expect(success, isTrue);
      expect(repository.transferCalls, 1);

      expect(viewModel.myRole, GroupRole.member);
      expect(updatedGroup?.myRole, GroupRole.member);

      expect(
        viewModel.members[0].role,
        GroupRole.member,
      );

      expect(
        viewModel.members[2].role,
        GroupRole.owner,
      );

      expect(viewModel.canInvite, isFalse);
      expect(viewModel.errorMessage, isNotNull);

      viewModel.dispose();
    },
  );

  test(
    'Accettare un invito aggiunge il gruppo '
        'all’elenco dell’utente',
        () async {
      final repository = FakeGroupsRepository(
        createGroup(GroupRole.member),
      );

      final viewModel = GroupsViewModel(
        repository,
      );

      final token = List.filled(43, 'a').join();

      final group = await viewModel.acceptInvitation(
        token,
      );

      expect(group, isNotNull);
      expect(repository.acceptCalls, 1);
      expect(viewModel.groups.length, 1);
      expect(
        viewModel.groups.first.myRole,
        GroupRole.member,
      );

      // Verifica che un aggiornamento dello stesso gruppo
      // non produca duplicati nell'elenco.
      await viewModel.acceptInvitation(token);

      expect(viewModel.groups.length, 1);

      viewModel.dispose();
    },
  );
}
