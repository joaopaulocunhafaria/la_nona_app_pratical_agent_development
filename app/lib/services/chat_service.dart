import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import 'package:la_nona/data/api/api_client.dart';
import 'package:la_nona/data/api/api_config.dart';
import 'package:la_nona/data/models/chat_message.dart';
import 'package:la_nona/data/models/chat_thread.dart';
import 'package:la_nona/services/session_store.dart';

/// Chat de suporte: histórico/threads via REST e tempo real via STOMP/SockJS
/// (`/ws`), substituindo o Firestore + WriteBatch.
///
/// Singleton: as telas instanciam com `ChatService()` e compartilham a mesma
/// conexão WebSocket. O [AuthService] chama [connect] após o login e
/// [disconnect] no logout.
class ChatService {
  ChatService._();
  static final ChatService _instance = ChatService._();
  factory ChatService() => _instance;

  final ApiClient _api = ApiClient.instance;

  StompClient? _client;
  bool _connected = false;

  final Map<String, StreamController<ChatMessage>> _threadControllers = {};
  final Set<String> _subscribedThreads = {};
  final StreamController<ChatThread> _adminThreadsController =
      StreamController<ChatThread>.broadcast();
  bool _adminSubscribed = false;
  final List<void Function()> _onConnectQueue = [];

  bool get isConnected => _connected;

  // ---------------------------------------------------------------------------
  // Conexão STOMP
  // ---------------------------------------------------------------------------

  void connect() {
    if (_client != null) return; // já ativo ou ativando
    final token = SessionStore.instance.token;
    if (token == null || token.isEmpty) return;

    final headers = {'Authorization': 'Bearer $token'};
    _client = StompClient(
      config: StompConfig.sockJS(
        url: ApiConfig.wsUrl,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) {
          _connected = false;
          debugPrint('Chat WebSocket erro: $error');
        },
        onStompError: (StompFrame frame) =>
            debugPrint('Chat STOMP erro: ${frame.body}'),
        onDisconnect: (StompFrame frame) => _connected = false,
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _client!.activate();
  }

  void disconnect() {
    _client?.deactivate();
    _client = null;
    _connected = false;
    _subscribedThreads.clear();
    _adminSubscribed = false;
    _onConnectQueue.clear();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    // (re)assina tópicos após (re)conexão.
    if (_adminSubscribed) _subscribeAdminTopic();
    for (final userId in _subscribedThreads) {
      _subscribeThreadTopic(userId);
    }
    final queued = List<void Function()>.of(_onConnectQueue);
    _onConnectQueue.clear();
    for (final action in queued) {
      action();
    }
  }

  void _whenConnected(void Function() action) {
    if (_connected && _client?.connected == true) {
      action();
    } else {
      _onConnectQueue.add(action);
      connect();
    }
  }

  // ---------------------------------------------------------------------------
  // Tempo real (STOMP)
  // ---------------------------------------------------------------------------

  /// Novas mensagens da thread [userId] em tempo real.
  Stream<ChatMessage> messagesStream(String userId) {
    final controller = _threadControllers.putIfAbsent(
        userId, () => StreamController<ChatMessage>.broadcast());
    if (_subscribedThreads.add(userId)) {
      _whenConnected(() => _subscribeThreadTopic(userId));
    }
    return controller.stream;
  }

  void _subscribeThreadTopic(String userId) {
    _client?.subscribe(
      destination: '/topic/chat.$userId',
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        final message =
            ChatMessage.fromJson(jsonDecode(frame.body!) as Map<String, dynamic>);
        _threadControllers[userId]?.add(message);
      },
    );
  }

  /// Resumos de threads atualizadas (lista do admin).
  Stream<ChatThread> adminThreadUpdates() {
    if (!_adminSubscribed) {
      _adminSubscribed = true;
      _whenConnected(_subscribeAdminTopic);
    }
    return _adminThreadsController.stream;
  }

  void _subscribeAdminTopic() {
    _client?.subscribe(
      destination: '/topic/chat.admin.threads',
      callback: (StompFrame frame) {
        if (frame.body == null) return;
        _adminThreadsController
            .add(ChatThread.fromJson(jsonDecode(frame.body!) as Map<String, dynamic>));
      },
    );
  }

  /// Envia uma mensagem na thread [userId] (`SEND /app/chat.{userId}.send`).
  void sendMessage({required String userId, required String text}) {
    _whenConnected(() {
      _client?.send(
        destination: '/app/chat.$userId.send',
        body: jsonEncode({'text': text}),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // REST
  // ---------------------------------------------------------------------------

  /// `GET /api/chat/threads` (ROLE_ADMIN).
  Future<List<ChatThread>> getAllThreads() async {
    final response = await _api.get('/chat/threads');
    return (response as List<dynamic>)
        .map((e) => ChatThread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Histórico paginado da thread [userId] (ordenado por `sentAt` asc).
  Future<List<ChatMessage>> getHistory(String userId, {int page = 0, int size = 50}) async {
    final response = await _api.get(
      '/chat/threads/$userId/messages',
      query: {'page': page, 'size': size, 'sort': 'sentAt,asc'},
    );
    final content = (response as Map<String, dynamic>)['content'] as List<dynamic>? ?? const [];
    return content
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `PUT /api/chat/threads/{userId}/read?as=admin|user`.
  Future<void> markAsRead(String userId, {required String as}) async {
    await _api.put('/chat/threads/$userId/read', query: {'as': as});
  }

  Future<int> _totalUnreadAdmin() async {
    try {
      final response = await _api.get('/chat/threads/unread-count');
      return (response as Map<String, dynamic>)['total'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<int> _myUnread() async {
    try {
      final response = await _api.get('/chat/my-thread/unread-count');
      return (response as Map<String, dynamic>)['count'] as int? ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Badge do admin: total de não lidas, atualizado a cada thread modificada.
  Stream<int> totalUnreadCountAdmin() async* {
    yield await _totalUnreadAdmin();
    await for (final _ in adminThreadUpdates()) {
      yield await _totalUnreadAdmin();
    }
  }

  /// Badge do cliente: não lidas da própria thread, atualizado a cada mensagem.
  Stream<int> unreadCountForUser(String userId) async* {
    yield await _myUnread();
    await for (final _ in messagesStream(userId)) {
      yield await _myUnread();
    }
  }
}
