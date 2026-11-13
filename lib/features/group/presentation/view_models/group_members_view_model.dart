
import 'package:flutter/foundation.dart';

import '../../data/models/group_member.dart';
import '../../data/repositories/groups_repository.dart';

//Gestisce il caricamento dei membri di un gruppo

class GroupMembersViewModel extends ChangeNotifier {
  final GroupsRepository _repository;
  final int _groupId;

  List<GroupMember> _members = [];
  bool _isLoading = false;
  bool _disposed = false;

  String? _errorMessage;

  GroupMembersViewModel(
      this._repository,
      this._groupId,
      );

  List<GroupMember> get members =>
      List.unmodifiable(_members);

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Recupera l'elenco aggiornato dei membri.
  Future<void> load() async {
    if (_isLoading || _disposed) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getMembers(
        _groupId,
      );

      if (_disposed) return;

      _members = result;
    } catch (_) {
      if (_disposed) return;

      _errorMessage =
      'Impossibile caricare i membri del gruppo.';
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
