import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String userId;
  final String userName;
  final String lastMessage;
  final DateTime updatedAt;
  final int unreadCount; // Admin unread count
  final int userUnreadCount; // Regular user unread count

  ChatThread({
    required this.userId,
    required this.userName,
    required this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
    this.userUnreadCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'lastMessage': lastMessage,
      'updatedAt': Timestamp.fromDate(updatedAt),
      'unreadCount': unreadCount,
      'userUnreadCount': userUnreadCount,
    };
  }

  factory ChatThread.fromMap(Map<String, dynamic> map, String id) {
    return ChatThread(
      userId: id,
      userName: map['userName'] ?? 'Usuário',
      lastMessage: map['lastMessage'] ?? '',
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: map['unreadCount'] ?? 0,
      userUnreadCount: map['userUnreadCount'] ?? 0,
    );
  }
}
