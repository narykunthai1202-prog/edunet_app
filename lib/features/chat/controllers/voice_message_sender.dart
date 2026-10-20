
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import 'voice_recorder_controller.dart';

class VoiceMessageSender {
  VoiceMessageSender({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  Future<void> send({
    required String conversationId,
    required String senderId,
    required String receiverId,
    required VoiceDraft draft,
  }) async {
    if (draft.durationMs < 500) {
      throw ArgumentError('Voice message is too short.');
    }
    // Firestore document max limit is 1 MB. Base64 adds ~33% overhead.
    if (draft.bytes > 700 * 1024) {
      throw ArgumentError('Voice message exceeds maximum length (~45 seconds).');
    }

    final chatDocRef = _firestore.collection('chats').doc(conversationId);
    final messageId = _uuid.v4();
    final messageRef = chatDocRef.collection('messages').doc(messageId);

    try {
      // Read recorded bytes directly from local file or web blob
      final xFile = XFile(draft.path);
      final bytes = await xFile.readAsBytes();

      // Convert raw bytes to Base64 data URI string
      final base64Audio = base64Encode(bytes);
      final dataUri = 'data:${draft.mimeType};base64,$base64Audio';

      // 1. Save individual message to subcollection
      await messageRef.set({
        'id': messageId,
        'conversationId': conversationId,
        'senderId': senderId,
        'type': 'audio',
        'status': 'sent',
        'audioUrl': dataUri,
        'text': dataUri,
        'durationMs': draft.durationMs,
        'audio': {
          'durationMs': draft.durationMs,
          'mimeType': draft.mimeType,
          'bytes': draft.bytes,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update parent chat preview metadata
      await chatDocRef.set({
        'participants': [senderId, receiverId],
        'lastMessage': '🎤 Voice message',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'unreadCount_$receiverId': FieldValue.increment(1),
      }, SetOptions(merge: true));

    } catch (error) {
      debugPrint('Voice encoding/sending error: $error');
      
      await messageRef.set({
        'id': messageId,
        'conversationId': conversationId,
        'senderId': senderId,
        'type': 'audio',
        'status': 'failed',
        'failureReason': error.toString(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      rethrow;
    }
  }
}