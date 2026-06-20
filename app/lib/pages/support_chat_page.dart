import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:la_nona/data/models/chat_message.dart';
import 'package:la_nona/services/chat_service.dart';
import 'package:la_nona/theme/app_colors.dart';

/// Tela de conversa do chat de suporte.
///
/// Histórico vem por REST (`GET /chat/threads/{userId}/messages`) e novas
/// mensagens chegam em tempo real via STOMP (`/topic/chat.{userId}`). O envio
/// é via STOMP (`/app/chat.{userId}.send`).
class SupportChatPage extends StatefulWidget {
  final String userId;
  final String userName;
  final bool isAdminView;

  const SupportChatPage({
    super.key,
    required this.userId,
    required this.userName,
    this.isAdminView = false,
  });

  @override
  State<SupportChatPage> createState() => _SupportChatPageState();
}

class _SupportChatPageState extends State<SupportChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();

  /// Mensagens em ordem decrescente (mais recente primeiro) para o ListView
  /// `reverse: true`.
  final List<ChatMessage> _messages = [];
  final Set<String> _ids = {};
  StreamSubscription<ChatMessage>? _subscription;
  bool _loading = true;

  String get _readAs => widget.isAdminView ? 'admin' : 'user';

  @override
  void initState() {
    super.initState();
    _chatService.connect();
    _chatService.markAsRead(widget.userId, as: _readAs);
    _loadHistory();
    _subscription = _chatService.messagesStream(widget.userId).listen(_onIncoming);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await _chatService.getHistory(widget.userId);
      if (!mounted) return;
      setState(() {
        for (final message in history.reversed) {
          if (_ids.add(message.id)) _messages.add(message);
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar mensagens: $e')),
      );
    }
  }

  void _onIncoming(ChatMessage message) {
    if (!mounted) return;
    if (!_ids.add(message.id)) return;
    setState(() => _messages.insert(0, message));
    // Estou com a conversa aberta: zera o contador do meu lado.
    _chatService.markAsRead(widget.userId, as: _readAs);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _chatService.sendMessage(userId: widget.userId, text: text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminView ? widget.userName : 'Suporte La Nonna'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              widget.isAdminView
                  ? 'Nenhuma mensagem nesta conversa'
                  : 'Como podemos ajudar você hoje?',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = widget.isAdminView ? message.isAdmin : !message.isAdmin;
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.secondaryBase : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.sentAt),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Digite sua mensagem...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppColors.secondaryBase,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
