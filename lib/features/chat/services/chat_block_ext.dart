// lib/features/chat/services/chat_block_ext.dart
// Adds two-way blocking to ChatService WITHOUT editing chat_service.dart.
// The marker is stored on the shared chat document:
//   chats/{chatId}  ->  blockedBy_{blockerId}: true/false
// Both users can already read this document, so no Firestore rule change
// is needed.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/message_model.dart';
import 'chat_service.dart';

extension ChatBlockExt on ChatService {
  DocumentReference<Map<String, dynamic>> _chatDocFor(String a, String b) =>
      FirebaseFirestore.instance.collection('chats').doc(getChatRoomId(a, b));

  /// Writes (or clears) the marker the OTHER user will read.
  Future<void> syncBlockMarker(
    String currentUserId,
    String peerId,
    bool blocked,
  ) {
    return _chatDocFor(currentUserId, peerId).set({
      'participants': [currentUserId, peerId],
      'blockedBy_$currentUserId': blocked,
    }, SetOptions(merge: true));
  }

  /// Use this instead of blockUser(...)
  Future<void> blockUserBothWays(String currentUserId, String peerId) async {
    await blockUser(currentUserId, peerId);
    await syncBlockMarker(currentUserId, peerId, true);
  }

  /// Use this instead of unblockUser(...)
  Future<void> unblockUserBothWays(String currentUserId, String peerId) async {
    await unblockUser(currentUserId, peerId);
    await syncBlockMarker(currentUserId, peerId, false);
  }

  /// true while [peerId] has blocked [currentUserId]
  Stream<bool> watchBlockedByPeer(String currentUserId, String peerId) {
    return _chatDocFor(currentUserId, peerId)
        .snapshots()
        .map((s) => s.data()?['blockedBy_$peerId'] == true)
        .handleError((e) => debugPrint('blockedBy check failed: $e'));
  }

  /// Sends a file message that keeps the REAL file name and size
  /// (so the bubble shows "report.pdf" instead of a random link name).
  Future<void> sendFileWithName({
    required String senderId,
    required String receiverId,
    required String fileUrl,
    required String fileName,
    required int fileSize,
  }) async {
    final chatRef = _chatDocFor(senderId, receiverId);

    final msg = MessageModel(
      messageId: '',
      senderId: senderId,
      receiverId: receiverId,
      type: 'file',
      text: fileUrl,
      timestamp: DateTime.now(),
      isSeen: false,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
    );

    final data = msg.toMap();
    data['timestamp'] = FieldValue.serverTimestamp();
    data.putIfAbsent('reactions', () => {});
    data.putIfAbsent('isDeleted', () => false);
    data.putIfAbsent('isForwarded', () => false);

    await chatRef.collection('messages').add(data);

    await chatRef.set({
      'participants': [senderId, receiverId],
      'lastMessage': '📎 $fileName',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}