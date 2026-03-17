import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:la_nona/data/models/chat_message.dart';
import 'package:la_nona/data/models/chat_thread.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtém todas as conversas (Apenas para Admin)
  Stream<List<ChatThread>> getAllThreads() {
    return _firestore
        .collection('chats')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatThread.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Obtém o unreadCount total de todas as conversas (Apenas para Admin)
  Stream<int> getTotalUnreadCountAdmin() {
    return _firestore
        .collection('chats')
        .snapshots()
        .map((snapshot) {
          int total = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            total += (data['unreadCount'] ?? 0) as int;
          }
          return total;
        });
  }

  /// Obtém o unreadCount de um usuário específico
  Stream<int> getUnreadCountForUser(String userId) {
    return _firestore
        .collection('chats')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return 0;
          return (snapshot.data()?['userUnreadCount'] ?? 0) as int;
        });
  }

  /// Obtém as mensagens de um chat específico
  Stream<List<ChatMessage>> getMessages(String userId) {
    return _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Envia uma mensagem
  Future<void> sendMessage({
    required String targetUserId,
    required String text,
    required bool isAdmin,
    String? userName,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final batch = _firestore.batch();

    // 1. Referência do documento da conversa (Thread)
    final threadRef = _firestore.collection('chats').doc(targetUserId);
    
    // 2. Referência da nova mensagem
    final messageRef = threadRef.collection('messages').doc();

    final message = ChatMessage(
      id: messageRef.id,
      senderId: currentUserId,
      text: text,
      isAdmin: isAdmin,
      sentAt: DateTime.now(),
    );

    // Salvar a mensagem
    batch.set(messageRef, message.toMap());

    // Atualizar o documento do chat (lastMessage, updatedAt, unreadCount)
    Map<String, dynamic> threadUpdate = {
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (userName != null) {
      threadUpdate['userName'] = userName;
      threadUpdate['userId'] = targetUserId;
    }

    // Se for o usuário enviando, incrementa unreadCount para o Admin
    if (!isAdmin) {
      threadUpdate['unreadCount'] = FieldValue.increment(1);
    } else {
      // Se for o admin enviando, incrementa userUnreadCount para o usuário
      threadUpdate['userUnreadCount'] = FieldValue.increment(1);
    }

    batch.set(threadRef, threadUpdate, SetOptions(merge: true));

    await batch.commit();
  }

  /// Zera o contador de mensagens não lidas para o Admin
  Future<void> markAsRead(String userId) async {
    await _firestore.collection('chats').doc(userId).update({
      'unreadCount': 0,
    });
  }

  /// Zera o contador de mensagens não lidas para o Usuário
  Future<void> markAsReadForUser(String userId) async {
    await _firestore.collection('chats').doc(userId).update({
      'userUnreadCount': 0,
    });
  }
}
