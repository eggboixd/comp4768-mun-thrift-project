import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat.dart';

// Provider for FirebaseFirestore instance
final chatFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

class ChatService {
  final FirebaseFirestore _firestore;
  ChatService(this._firestore);

  // Collection reference for chats
  CollectionReference get _chatsCollection => _firestore.collection('chats');

  // Send a message between two users
  Future<void> sendMessage({
    required String fromUserId,
    required String toUserId,
    required String message,
  }) async {
    final chatId = _getChatId(fromUserId, toUserId);
    await _chatsCollection.doc(chatId).collection('messages').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Watch messages between two users
  Stream<List<ChatMessage>> watchMessages({
    required String userA,
    required String userB,
  }) {
    final chatId = _getChatId(userA, userB);
    return _chatsCollection
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          return <ChatMessage>[];
        }
        return snapshot.docs.map((doc) {
          final data = doc.data();
          return ChatMessage.fromMap({
            'id': doc.id,
            ...data,
          });
        }).toList();
      });
  }

  // Helper to generate a unique chat id for two users
  String _getChatId(String userA, String userB) {
    final sorted = [userA, userB]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}

// Provider for ChatService
final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(ref.watch(chatFirestoreProvider));
});

// Provider to watch messages between two users
final chatMessagesProvider = StreamProvider.family<List<ChatMessage>, (String, String)>((ref, userIds) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.watchMessages(userA: userIds.$1, userB: userIds.$2);
});
