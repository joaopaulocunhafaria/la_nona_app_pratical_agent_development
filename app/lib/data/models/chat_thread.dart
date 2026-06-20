/// Conversa do chat de suporte (espelha o `ChatThreadResponse`).
class ChatThread {
  final String userId;
  final String userName;
  final String lastMessage;
  final DateTime updatedAt;

  /// Não lidas pelo admin (`adminUnreadCount`). Mantém o nome `unreadCount`
  /// usado pela tela do inbox do admin.
  final int unreadCount;

  /// Não lidas pelo cliente (`userUnreadCount`).
  final int userUnreadCount;

  ChatThread({
    required this.userId,
    required this.userName,
    required this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
    this.userUnreadCount = 0,
  });

  factory ChatThread.fromJson(Map<String, dynamic> json) {
    return ChatThread(
      userId: (json['userId'] ?? '').toString(),
      userName: (json['userName'] ?? 'Usuário').toString(),
      lastMessage: (json['lastMessage'] ?? '').toString(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      unreadCount: (json['adminUnreadCount'] as num?)?.toInt() ?? 0,
      userUnreadCount: (json['userUnreadCount'] as num?)?.toInt() ?? 0,
    );
  }
}
