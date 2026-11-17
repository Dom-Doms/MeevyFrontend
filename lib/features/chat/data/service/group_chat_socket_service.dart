
import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../auth/data/repositories/auth_repository.dart';

/*
 * Gestisce la connessione WebSocket/STOMP della chat.
 *
 * Il socket riceve soltanto notifiche di nuovi messaggi.
 * Invio e recupero dei messaggi rimangono operazioni REST.
 */
class GroupChatSocketService {
  final AuthRepository _authRepository;
  final String _webSocketUrl;

  StompClient? _client;
  bool _stopped = true;

  void Function(int groupId, int messageId)? _onNotification;
  void Function()? _onConnected;
  void Function(bool connected)? _onConnectionChanged;

  GroupChatSocketService({
    required AuthRepository authRepository,
    required String apiBaseUrl,
  })  : _authRepository = authRepository,
        _webSocketUrl = _buildWebSocketUrl(apiBaseUrl);

  bool get isConnected => !_stopped && (_client?.connected ?? false);

  /*
   * Ricava l'indirizzo WebSocket dall'URL REST configurato
   * nell'applicazione, senza codificare un server fisso.
   */
  static String _buildWebSocketUrl(String apiBaseUrl) {
    final uri = Uri.tryParse(apiBaseUrl.trim());

    if (uri == null ||
        uri.host.isEmpty ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw StateError('API_BASE_URL non valida.');
    }

    return uri.replace(
      scheme: uri.scheme == 'https' ? 'wss' : 'ws',
      path: '/ws/chat',
      query: '',
      fragment: '',
    ).toString();
  }

  /*
   * Apre la connessione e si iscrive alla coda privata
   * dell'utente autenticato.
   */
  void connect({
    required void Function(int groupId, int messageId)
    onNotification,
    required void Function() onConnected,
    required void Function(bool connected) onConnectionChanged,
  }) {
    disconnect();

    _stopped = false;
    _onNotification = onNotification;
    _onConnected = onConnected;
    _onConnectionChanged = onConnectionChanged;

    _authRepository.addListener(_onAuthChanged);

    // Aggiornati prima di ogni CONNECT, anche dopo un reconnect.
    final connectHeaders = <String, String>{};

    final client = StompClient(
      config: StompConfig(
        url: _webSocketUrl,
        reconnectDelay: const Duration(seconds: 5),
        connectionTimeout: const Duration(seconds: 10),
        stompConnectHeaders: connectHeaders,

        /*
         * Il token viene rinnovato, se necessario,
         * PRIMA del frame STOMP CONNECT.
         *
         * Non inviamo mai il refresh token sul WebSocket.
         */
        beforeConnect: () async {
          if (_stopped) {
            throw StateError('Connessione chiusa.');
          }

          final valid =
          await _authRepository.ensureValidAccessToken();

          final token = _authRepository.accessToken;

          if (_stopped || !valid || token == null) {
            throw StateError('Sessione non autenticata.');
          }

          connectHeaders['Authorization'] = 'Bearer $token';
        },

        onConnect: (_) {
          if (_stopped) return;

          _client?.subscribe(
            destination:
            '/user/queue/group-message-notifications',
            callback: _handleNotification,
          );

          _onConnectionChanged?.call(true);
          _onConnected?.call();
        },

        onDisconnect: (_) {
          if (!_stopped) {
            _onConnectionChanged?.call(false);
          }
        },

        onWebSocketError: (_) {
          if (!_stopped) {
            _onConnectionChanged?.call(false);
          }
        },

        onStompError: (_) {
          if (!_stopped) {
            _onConnectionChanged?.call(false);
          }
        },
      ),
    );

    _client = client;
    client.activate();
  }

  /*
   * La notifica Spring contiene groupId e messageId.
   * Non contiene il testo del messaggio.
   */
  void _handleNotification(StompFrame frame) {
    if (_stopped || frame.body == null) return;

    try {
      final decoded = jsonDecode(frame.body!);

      if (decoded is! Map<String, dynamic>) return;

      final groupId = decoded['groupId'];
      final messageId = decoded['messageId'];

      if (groupId is int && messageId is int) {
        _onNotification?.call(groupId, messageId);
      }
    } on FormatException {
      // Ignora notifiche malformate.
    }
  }

  // Il logout termina anche il collegamento WebSocket.
  void _onAuthChanged() {
    if (!_authRepository.isAuthenticated) {
      disconnect();
    }
  }

  /*
   * Chiude il collegamento e annulla le sottoscrizioni
   * quando si esce dalla chat o si effettua il logout.
   */
  void disconnect() {
    _stopped = true;

    _authRepository.removeListener(_onAuthChanged);

    final client = _client;
    _client = null;

    client?.deactivate();

    _onNotification = null;
    _onConnected = null;
    _onConnectionChanged = null;
  }

  void dispose() {
    disconnect();
  }
}
