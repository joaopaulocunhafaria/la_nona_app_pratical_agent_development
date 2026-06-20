/// Mensagem do chat de suporte (espelha o `ChatMessageResponse`).
class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final bool isAdmin;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.isAdmin,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      isAdmin: json['isAdmin'] as bool? ?? false,
      sentAt: DateTime.tryParse((json['sentAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
    );
  }
}
