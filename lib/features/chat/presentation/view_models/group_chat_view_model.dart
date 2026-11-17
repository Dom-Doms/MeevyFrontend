
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/models/group_message.dart';
import '../../data/repositories/group_chat_repository.dart';
import '../../data/service/group_chat_socket_service.dart';

import '../../../profile/data/repositories/profile_repository.dart';

/*
 * Gestisce lo stato di una singola chat di gruppo.
 *
 * REST è la fonte autorevole dei messaggi.
 * WebSocket segnala soltanto quando recuperarli.
 */
class GroupChatViewModel extends ChangeNotifier {
  final GroupChatRepository _repository;
  final GroupChatSocketService _socket;
  final ProfileRepository _profileRepository;
  final int groupId;

  GroupChatViewModel(
      this._repository,
      this._socket,
      this._profileRepository,
      this.groupId,
      );

  static const int _pageSize = 30;

  List<GroupMessage> _messages = [];
  int? _currentUserId;

  bool _isLoading = false;
  bool _isLoadingOlder = false;
  bool _isSending = false;
  bool _isConnected = false;
  bool _hasMore = false;
  bool _catchingUp = false;
  bool _catchUpAgain = false;
  bool _disposed = false;

  String? _errorMessage;
  String? _sendError;

  List<GroupMessage> get messages =>
      List.unmodifiable(_messages);

  int? get currentUserId => _currentUserId;
  bool get isLoading => _isLoading;
  bool get isLoadingOlder => _isLoadingOlder;
  bool get isSending => _isSending;
  bool get isConnected => _isConnected;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  String? get sendError => _sendError;

  /*
   * Carica l'utente, la cronologia iniziale
   * e attiva la ricezione delle notifiche.
   */
  Future<void> initialize() async {
    if (_isLoading || _disposed) return;

    _socket.disconnect();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _profileRepository.getMe();

      if (_disposed) return;

      _currentUserId = profile.id;

      final page = await _repository.getMessages(
        groupId: groupId,
        limit: _pageSize,
      );

      if (_disposed) return;

      _messages = [];
      _mergeMessages(page);
      _hasMore = page.length == _pageSize;

      _socket.connect(
        onNotification: _onNotification,
        onConnected: () {
          // Recupera i messaggi persi mentre il socket
          // era disconnesso o in fase di collegamento.
          unawaited(_catchUp());
        },
        onConnectionChanged: (connected) {
          if (_disposed) return;

          _isConnected = connected;
          notifyListeners();
        },
      );
    } catch (_) {
      if (!_disposed) {
        _errorMessage =
        'Impossibile caricare la chat. Riprova.';
      }
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /*
   * Unisce nuovi messaggi per ID.
   * Non duplica quelli ricevuti sia dalla POST
   * sia dalla notifica WebSocket.
   *
   * L'ordine di visualizzazione è crescente.
   */
  void _mergeMessages(List<GroupMessage> incoming) {
    if (_disposed) return;

    final byId = {
      for (final message in _messages) message.id: message,
    };

    for (final message in incoming) {
      if (message.groupId == groupId) {
        byId[message.id] = message;
      }
    }

    _messages = byId.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    notifyListeners();
  }

  /*
   * La notifica contiene l'ID del messaggio.
   * Lo recuperiamo tramite la paginazione REST.
   */
  void _onNotification(int notifiedGroupId, int messageId) {
    if (_disposed || notifiedGroupId != groupId) return;

    if (_messages.any((message) => message.id == messageId)) {
      return;
    }

    unawaited(_fetchNotifiedMessage(messageId));
  }

  Future<void> _fetchNotifiedMessage(int messageId) async {
    try {
      // beforeId è esclusivo: id + 1 include il messaggio.
      final result = await _repository.getMessages(
        groupId: groupId,
        beforeId: messageId + 1,
        limit: 1,
      );

      if (_disposed) return;

      if (result.isNotEmpty && result.first.id == messageId) {
        _mergeMessages(result);
      }
    } catch (_) {
      // In caso di errore si potrà riconciliare via REST.
      if (!_disposed) {
        _errorMessage =
        'Alcuni messaggi potrebbero non essere aggiornati.';
        notifyListeners();
      }
    }
  }

  /*
   * Recupera i messaggi successivi all'ultimo
   * già conosciuto, anche se ne sono arrivati
   * più di 100 durante la disconnessione.
   */
  Future<void> _catchUp() async {
    if (_disposed) return;

    if (_catchingUp) {
      _catchUpAgain = true;
      return;
    }

    _catchingUp = true;

    try {
      do {
        _catchUpAgain = false;

        final lastKnownId =
        _messages.isEmpty ? 0 : _messages.last.id;

        int? beforeId;

        while (!_disposed) {
          final batch = await _repository.getMessages(
            groupId: groupId,
            beforeId: beforeId,
            limit: 100,
          );

          if (_disposed) return;

          _mergeMessages(
            batch
                .where((message) => message.id > lastKnownId)
                .toList(),
          );

          if (batch.isEmpty ||
              batch.length < 100 ||
              batch.any((message) => message.id <= lastKnownId)) {
            break;
          }

          beforeId = batch.last.id;
        }

        _errorMessage = null;
        notifyListeners();
      } while (_catchUpAgain && !_disposed);
    } catch (_) {
      if (!_disposed) {
        _errorMessage =
        'Impossibile aggiornare i nuovi messaggi.';
        notifyListeners();
      }
    } finally {
      _catchingUp = false;
    }
  }

  // Aggiorna la chat manualmente.
  Future<void> refresh() {
    if (_messages.isEmpty) {
      return initialize();
    }

    return _catchUp();
  }

  /*
   * Carica i messaggi più vecchi.
   * beforeId impedisce che nuovi messaggi spostino
   * le pagine durante lo scorrimento.
   */
  Future<void> loadOlder() async {
    if (_disposed ||
        _isLoading ||
        _isLoadingOlder ||
        !_hasMore ||
        _messages.isEmpty) {
      return;
    }

    _isLoadingOlder = true;
    notifyListeners();

    try {
      final batch = await _repository.getMessages(
        groupId: groupId,
        beforeId: _messages.first.id,
        limit: _pageSize,
      );

      if (_disposed) return;

      _hasMore = batch.length == _pageSize;
      _mergeMessages(batch);
    } catch (_) {
      if (!_disposed) {
        _errorMessage =
        'Impossibile caricare i messaggi precedenti.';
      }
    } finally {
      if (!_disposed) {
        _isLoadingOlder = false;
        notifyListeners();
      }
    }
  }

  /*
   * Invia tramite REST e inserisce la risposta
   * persistita nella cronologia.
   *
   * Non ritenta automaticamente una POST fallita,
   * perché il server potrebbe aver già salvato il messaggio.
   */
  Future<bool> sendMessage(String content) async {
    final text = content.trim();

    if (_disposed ||
        _isLoading ||
        _isSending ||
        text.isEmpty ||
        text.length > 4000) {
      return false;
    }

    _isSending = true;
    _sendError = null;
    notifyListeners();

    try {
      final saved = await _repository.sendMessage(
        groupId: groupId,
        content: text,
      );

      if (_disposed) return false;

      _mergeMessages([saved]);
      return true;
    } catch (_) {
      if (!_disposed) {
        _sendError =
        'Invio non confermato. Aggiorna la chat '
            'prima di riprovare, per evitare duplicati.';
      }
      return false;
    } finally {
      if (!_disposed) {
        _isSending = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _socket.dispose();
    super.dispose();
  }
}
