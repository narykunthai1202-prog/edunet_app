import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../models/chat_room_model.dart';
import '../models/message_model.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _player = AudioPlayer();

  /// Generate a unique Chat Room ID for two users.
  String getChatRoomId(String user1, String user2) {
    List<String> ids = [user1, user2];
    ids.sort(); // Ensures user1_user2 and user2_user1 resolve to the exact same room ID
    return ids.join('_');
  }

 CollectionReference<Map<String, dynamic>> _settingsCol(String uid) =>
    FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chatSettings');

// Live map of chatId -> settings
Stream<Map<String, Map<String, dynamic>>> watchChatSettings(String uid) {
  return _settingsCol(uid).snapshots().map((snap) => {
        for (final d in snap.docs) d.id: d.data(),
      });
}
Future<void> _sendMedia({
  required String chatId,
  required String senderId,
  required String receiverId,
  required Map<String, dynamic> content, // type + payload
  required String preview,               // shown in the chat list
}) async {
  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

  await chatRef.collection('messages').add({
    'senderId': senderId,
    'receiverId': receiverId,
    'timestamp': FieldValue.serverTimestamp(),
    ...content,
  });

  await chatRef.set({
  'participants': [senderId, receiverId],
  'lastMessage': preview,
  'lastMessageSenderId': senderId,   // add this line
  'lastMessageTime': FieldValue.serverTimestamp(),
  'unreadCount_$receiverId': FieldValue.increment(1),
}, SetOptions(merge: true));
}

Future<void> sendStickerMessage({
  required String chatId,
  required String senderId,
  required String receiverId,
  required String stickerPath,
}) =>
    _sendMedia(
      chatId: chatId,
      senderId: senderId,
      receiverId: receiverId,
      content: {'type': 'sticker', 'text': stickerPath},
      preview: '🙂 Sticker',
    );

Future<void> sendVideoMessage({
  required String chatId,
  required String senderId,
  required String receiverId,
  required XFile video,
}) async {
  final bytes = await video.readAsBytes(); // works on web and mobile
  if (bytes.length > 50 * 1024 * 1024) {
    throw Exception('Video is larger than 50 MB');
  }

  final ref = FirebaseStorage.instance
      .ref('chat_videos/$chatId/${DateTime.now().millisecondsSinceEpoch}.mp4');
  await ref.putData(bytes, SettableMetadata(contentType: 'video/mp4'));
  final url = await ref.getDownloadURL();

  await _sendMedia(
    chatId: chatId,
    senderId: senderId,
    receiverId: receiverId,
    content: {
  'type': 'video',
  'text': url,        // the bubble reads this
  'videoUrl': url,
},
    preview: '🎥 Video',
  );
}

Future<void> togglePinChat(String uid, String chatId, bool pin) =>
    _settingsCol(uid).doc(chatId).set({
      'pinned': pin,
      'pinnedAt': pin ? FieldValue.serverTimestamp() : null,
    }, SetOptions(merge: true));

Future<void> toggleFavoriteChat(String uid, String chatId, bool fav) =>
    _settingsCol(uid)
        .doc(chatId)
        .set({'favorite': fav}, SetOptions(merge: true));

Future<void> setMuteChat(String uid, String chatId, bool muted) =>
    _settingsCol(uid)
        .doc(chatId)
        .set({'muted': muted}, SetOptions(merge: true));

// "Delete for me" – hides the chat only for this user
Future<void> deleteChatForMe(String uid, String chatId) =>
    _settingsCol(uid).doc(chatId).set({
      'deleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
void listenForIncomingMessages({
  required String currentUserId,
  required String conversationId,
  required String senderName,
}) {
  FirebaseFirestore.instance
      .collection('chats')
      .doc(conversationId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(1)
      .snapshots()
      .listen((snapshot) {
    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final data = doc.data();

      // Only notify if the message was sent by the other user and is new
      if (data['senderId'] != currentUserId && data['status'] == 'sent') {
       NotificationService.showMessageNotification(
  senderName: senderName,
  messageType: data['type'] ?? 'text',
  content: data['text'] ?? '',
);
      }
    }
  });
}
  Future<void> sendTextMessage({
  required String senderId,
  required String receiverId,
  required String text,
}) async {
  if (text.trim().isEmpty) return;

  final String chatRoomId = getChatRoomId(senderId, receiverId);
  final chatDocRef = _firestore.collection('chats').doc(chatRoomId);

  try {
    // 1. Add message subdocument
    await chatDocRef.collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text.trim(),
      'type': 'text',
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'isSeen': false,
      'status': 'sent',
      'reactions': {},
      'isDeleted': false,
      'isForwarded': false,
    });

    // 2. Update parent chat preview metadata & unread counters
    await chatDocRef.set({
      'participants': [senderId, receiverId],
      'lastMessage': text.trim(),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  } catch (e) {
    debugPrint('Error sending text message: $e');
    rethrow;
  }
}

Future<void> setNickname(String uid, String chatId, String nickname) {
  final name = nickname.trim();
  return _settingsCol(uid).doc(chatId).set({
    'nickname': name.isEmpty ? FieldValue.delete() : name,
  }, SetOptions(merge: true));
}

Stream<String?> watchNickname(String uid, String chatId) {
  return _settingsCol(uid)
      .doc(chatId)
      .snapshots()
      .map((d) => d.data()?['nickname'] as String?);
}
  /// Send a standard message (supports optional type like 'text', 'image', etc.)
  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String text, {
    String type = 'text',
    bool isForwarded = false,
  }) async {
    final String chatRoomId = getChatRoomId(senderId, receiverId);

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
      'type': type,
      'reactions': {},
      'isDeleted': false,
      'isForwarded': isForwarded,
    };

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chats').doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': type == 'image'
          ? '📷 Photo'
          : (type == 'audio' ? '🎙️ Voice message' : text),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Unified Audio / Voice Message Sender
  Future<void> sendAudioMessage({
    required String senderId,
    required String receiverId,
    required String audioBase64OrUrl,
  }) async {
    final String chatRoomId = getChatRoomId(senderId, receiverId);

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': audioBase64OrUrl,
      'type': 'audio',
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
      'reactions': {},
      'isDeleted': false,
      'isForwarded': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chats').doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': '🎙️ Voice message',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  Future<void> sendVoiceMessage({
    required String senderId,
    required String receiverId,
    required String audioUrl,
  }) async {
    await sendAudioMessage(
      senderId: senderId,
      receiverId: receiverId,
      audioBase64OrUrl: audioUrl,
    );
  }

  Future<String> uploadVoiceMessage(String audioPath) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      final ref = FirebaseStorage.instance
          .ref()
          .child('chats/voice_messages/$fileName');

      if (kIsWeb) {
        final response = await http.get(Uri.parse(audioPath));
        final bytes = response.bodyBytes;
        await ref.putData(bytes, SettableMetadata(contentType: 'audio/m4a'));
      } else {
        final file = File(audioPath);
        await ref.putFile(file);
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print('Firebase Storage Upload Error: $e');
      return audioPath;
    }
  }

  Future<void> playAudio(String audioPath) async {
    if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
      await _player.play(UrlSource(audioPath));
    } else {
      await _player.play(DeviceFileSource(audioPath));
    }
  }

  /// Send an Image Message using Free ImgBB Hosting
 Future<void> sendImageMessage({
  required String senderId,
  required String receiverId,
  required XFile imageFile,
}) async {
  final String chatRoomId = getChatRoomId(senderId, receiverId);
  final chatDocRef = _firestore.collection('chats').doc(chatRoomId);

  try {
    // 1. Read image bytes and convert to Base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // 2. Upload to ImgBB
    final response = await http.post(
      Uri.parse(
        'https://api.imgbb.com/1/upload?key=9d7ae5b87d6058d799e40b603e34ee41',
      ),
      body: {
        'image': base64Image,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload image to ImgBB: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final String imageUrl = data['data']['url'];

    // 3. Add image message document
    await chatDocRef.collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'imageUrl': imageUrl,
      'text': imageUrl, // Retained for backwards compatibility
      'type': 'image',
      'status': 'sent',
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'isSeen': false,
      'reactions': {},
      'isDeleted': false,
      'isForwarded': false,
    });

    // 4. Update parent chat metadata & increment unread counter
    await chatDocRef.set({
      'participants': [senderId, receiverId],
      'lastMessage': '📷 Photo',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));

  } catch (error) {
    debugPrint('Error sending image message: $error');
    rethrow;
  }
}

  /// Send a Forwarded Message to a target recipient
  Future<void> sendForwardedMessage({
    required MessageModel originalMessage,
    required String currentUserId,
    required String targetUserId,
    String? originalSenderName,
  }) async {
    final String chatRoomId = getChatRoomId(currentUserId, targetUserId);

    final forwardedData = {
      'senderId': currentUserId,
      'receiverId': targetUserId,
      'text': originalMessage.text,
      'type': originalMessage.type,
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
      'reactions': {},
      'isDeleted': false,
      'isForwarded': true,
      'forwardedFromSenderName':
          originalMessage.forwardedFromSenderName ?? originalSenderName,
    };

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(forwardedData);

    await _firestore.collection('chats').doc(chatRoomId).set({
      'participants': [currentUserId, targetUserId],
      'lastMessage': originalMessage.type == 'image'
          ? 'Sent you a photo'
          : (originalMessage.type == 'audio'
              ? 'Sent you a voice message'
              : originalMessage.text),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': currentUserId,
      'isForwarded': true,
      'unreadCount_$targetUserId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Send a message with optional reply support
  Future<void> sendMessageWithReply({
    required String senderId,
    required String receiverId,
    required String text,
    String? replyToText,
    String type = 'text',
  }) async {
    final String chatRoomId = getChatRoomId(senderId, receiverId);

    final messageData = {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
      'type': type,
      'reactions': {},
      'replyToText': replyToText,
      'isDeleted': false,
      'isForwarded': false,
    };

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(messageData);

    await _firestore.collection('chats').doc(chatRoomId).set({
      'participants': [senderId, receiverId],
      'lastMessage': type == 'image'
          ? 'Sent you a photo'
          : (type == 'audio' ? 'Sent you a voice message' : text),
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': senderId,
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ==========================================
  // 2. REAL-TIME STREAMS
  // ==========================================

  /// Listen to real-time messages in a room
 
  Stream<List<MessageModel>> getMessagesStream(String currentUserId, String peerId) {
  String chatRoomId = getChatRoomId(currentUserId, peerId);

  return _firestore
      .collection('chats')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: true) // Set to true
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return MessageModel.fromMap(doc.data(), doc.id);
    }).toList();
  });
}

  /// Listen to all active chat rooms for a user
  Stream<List<ChatRoomModel>> getUserChatRoomsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// Stream metadata for a specific chat room
  Stream<Map<String, dynamic>> getChatMetadataStream(
      String currentUserId, String receiverId) {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return {};
      }
      return snapshot.data()!;
    });
  }

  /// Stream typing status of the receiver
  Stream<bool> getTypingStream(String currentUserId, String receiverId) {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    return _firestore
        .collection('chats')
        .doc(chatRoomId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return false;
      final data = snapshot.data()!;
      return data['typing_$receiverId'] ?? false;
    });
  }

  /// Stream receiver online status
  Stream<bool> getUserPresenceStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return false;
      return snapshot.data()!['isOnline'] ?? false;
    });
  }

  // ==========================================
  // 3. STATUS & INTERACTIONS
  // ==========================================

  /// Update Typing Status
  Future<void> setTypingStatus(
      String currentUserId, String receiverId, bool isTyping) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    await _firestore.collection('chats').doc(chatRoomId).set({
      'typing_$currentUserId': isTyping,
    }, SetOptions(merge: true));
  }

  /// Update User Online Presence
  Future<void> updateUserPresence(String userId, bool isOnline) async {
    await _firestore.collection('users').doc(userId).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Add or remove emoji reaction
  Future<void> toggleReaction(
    String currentUserId,
    String receiverId,
    String messageId,
    String emoji,
  ) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    final docRef = _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    Map<String, dynamic> reactions =
        Map<String, dynamic>.from(snapshot.data()?['reactions'] ?? {});

    if (reactions[currentUserId] == emoji) {
      reactions.remove(currentUserId);
    } else {
      reactions[currentUserId] = emoji;
    }

    await docRef.update({'reactions': reactions});
  }

  /// Unsend message
  Future<void> unsendMessage(
      String currentUserId, String receiverId, String messageId) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isUnsent': true,
      'text': 'This message was unsent',
    });
  }

  /// Mark all incoming unread messages as seen
  Future<void> markMessagesAsSeen(
      String currentUserId, String receiverId) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    final unreadQuery = await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .where('senderId', isEqualTo: receiverId)
        .where('isSeen', isEqualTo: false)
        .get();

    for (var doc in unreadQuery.docs) {
      await doc.reference.update({'isSeen': true});
    }

    await _firestore.collection('chats').doc(chatRoomId).set({
      'unreadCount_$currentUserId': 0,
    }, SetOptions(merge: true));
  }

  /// Mark the current user's unread count as read
  Future<void> markAsRead(String currentUserId, String targetUserId) async {
    final String roomId = getChatRoomId(currentUserId, targetUserId);

    await _firestore.collection('chats').doc(roomId).set({
      'unreadCount_$currentUserId': 0,
    }, SetOptions(merge: true));
  }

  // ==========================================
  // 4. DELETION & BLOCKING
  // ==========================================

  /// Soft delete a message ("Delete for Everyone")
  Future<void> deleteMessage(
    String currentUserId,
    String receiverId,
    String messageId,
  ) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);

    await _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isDeleted': true,
      'text': 'This message was deleted',
    });
  }

  /// Delete all messages in a specific chat room
  Future<void> deleteAllMessagesInRoom(
      String currentUserId, String receiverId) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    final collectionRef = _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages');

    final snapshots = await collectionRef.get();
    final batch = _firestore.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await _firestore.collection('chats').doc(chatRoomId).update({
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// Delete ALL messages across every single chat room
  Future<void> deleteAllDatabaseMessages() async {
    final chatsQuery = await _firestore.collection('chats').get();

    for (var chatDoc in chatsQuery.docs) {
      final messagesQuery =
          await chatDoc.reference.collection('messages').get();
      final batch = _firestore.batch();
      for (var messageDoc in messagesQuery.docs) {
        batch.delete(messageDoc.reference);
      }
      await batch.commit();

      await chatDoc.reference.update({
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Block a user
 // Block specific peer
Future<void> blockUser(String currentUserId, String peerId) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('blocked')
      .doc(peerId)
      .set({'blockedAt': FieldValue.serverTimestamp()});
}
Future<void> reportUser({
  required String reporterId,
  required String reportedId,
  required String reason,
  String? details,
}) async {
  await FirebaseFirestore.instance.collection('reports').add({
    'reporterId': reporterId,
    'reportedId': reportedId,
    'reason': reason,
    'details': details ?? '',
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
  });
}
Future<void> sendFileMessage({
  required String senderId,
  required String receiverId,
  required String fileUrl,
  required String fileName,
  required int fileSize,
}) async {
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

  // TODO: replace this block with the SAME path sendImageMessage uses
  final chatId = senderId.compareTo(receiverId) < 0
      ? '${senderId}_$receiverId'
      : '${receiverId}_$senderId';

  await FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .add(msg.toMap());
}
Future<bool> isUserBlocked(
  String currentUserId,
  String peerId,
) async {
  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('blocked')
      .doc(peerId)
      .get();

  return doc.exists;
}
// Unblock specific peer
Future<void> unblockUser(String currentUserId, String peerId) async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('blocked')
      .doc(peerId)
      .delete();
}
  Future<void> toggleMuteChat({
    required String currentUserId,
    required String chatId,
    required bool isMuted,
  }) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('muted_chats')
        .doc(chatId)
        .set({
      'isMuted': isMuted,
      'chatId': chatId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
/// Report user profile
  Future<void> reportProfile({
    required String currentUserId,
    required String reportedUserId,
    required String chatId,
    required String reason,
  }) async {
    await _firestore.collection('reports').add({
      'reportedUserId': reportedUserId,
      'reportedByUserId': currentUserId,
      'chatId': chatId,
      'reason': reason.trim(),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
  /// Purge/Delete all messages in a specific chat room
  Future<void> purgeMessages({
    required String currentUserId,
    required String receiverId,
  }) async {
    final String chatRoomId = getChatRoomId(currentUserId, receiverId);
    final collectionRef = _firestore
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages');

    final snapshots = await collectionRef.get();
    final batch = _firestore.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    await _firestore.collection('chats').doc(chatRoomId).set({
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  // Check Mute Status
  Future<bool> isChatMuted({
    required String currentUserId,
    required String chatId,
  }) async {
    final doc = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('muted_chats')
        .doc(chatId)
        .get();

    return doc.exists ? (doc.data()?['isMuted'] ?? false) : false;
  }
}