import 'package:cloud_firestore/cloud_firestore.dart';

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

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'isAdmin': isAdmin,
      'sentAt': Timestamp.fromDate(sentAt),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
