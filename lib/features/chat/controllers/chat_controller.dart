import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../services/chat_service.dart';


class ChatController extends GetxController {
  var messages = <Map<String, dynamic>>[].obs;
  var isRecording = false.obs;

  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentAudioPath;
  final ChatService _chatService = ChatService();

  @override
  void onClose() {
    _audioRecorder.dispose();
    super.onClose();
  }

  // ==========================================
  // REAL-TIME STREAM LISTENER
  // ==========================================

  void listenToMessages(String currentUserId, String peerId) {
    _chatService.getMessagesStream(currentUserId, peerId).listen((messageModels) async {
      print('>>> Firebase Stream Updated: Received ${messageModels.length} items');

      // Process all messages asynchronously in parallel using Future.wait
      List<Map<String, dynamic>> updatedList = await Future.wait(
        messageModels.map((msg) async {
          String content = msg.text;

          // Resolve Storage paths to web download URLs if needed
          if (content.startsWith('chats/') || content.startsWith('conversations/')) {
            try {
              content = await FirebaseStorage.instance.ref(content).getDownloadURL();
            } catch (e) {
              print('Could not resolve download URL for $content: $e');
            }
          }

          return {
            'id': msg.messageId,
            'senderId': msg.senderId,
            'receiverId': msg.receiverId,
            'content': content,
            'text': content,
            'type': msg.type,
            'isMe': msg.senderId == currentUserId,
            'time': msg.timestamp,
            'isSeen': msg.isSeen,
            'reactions': msg.reactions,
            'status': msg.status,
            'replyToText': msg.replyToText,
            'isDeleted': msg.isDeleted,
            'isForwarded': msg.isForwarded,
            'audio': msg.audio,
          };
        }),
      );

      // Trigger GetX reactive update
      messages.assignAll(updatedList);
    });
  }

  // ==========================================
  // MESSAGE SENDING ACTIONS
  // ==========================================

  /// Send Text Message
 Future<void> sendMessage({
  required String text,
  required String currentUserId,
  required String peerId,
}) async {
  if (text.trim().isEmpty) return;

  // 1. Check if current user blocked peer
  final iBlocked = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .collection('blocked')
      .doc(peerId)
      .get();

  // 2. Check if peer blocked current user
  final theyBlocked = await FirebaseFirestore.instance
      .collection('users')
      .doc(peerId)
      .collection('blocked')
      .doc(currentUserId)
      .get();

  if (iBlocked.exists || theyBlocked.exists) {
    Get.snackbar(
      'Blocked',
      'Cannot send message while blocked.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }

  try {
    await _chatService.sendTextMessage(
      senderId: currentUserId,
      receiverId: peerId,
      text: text.trim(),
    );
  } catch (e) {
    print('Error sending text message: $e');
  }
}

  /// Complete Voice Message Recording & Send
  Future<void> sendVoiceNote(String currentUserId, String peerId) async {
    final path = await stopRecording();
    if (path == null || path.isEmpty) return;

    try {
      final downloadUrl = await _chatService.uploadVoiceMessage(path);
      await _chatService.sendVoiceMessage(
        senderId: currentUserId,
        receiverId: peerId,
        audioUrl: downloadUrl,
      );
    } catch (e) {
      print('Error uploading/sending voice note: $e');
    }
  }

  // ==========================================
  // AUDIO RECORDING LOGIC
  // ==========================================

  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        if (kIsWeb) {
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: '',
          );
        } else {
          final dir = await getTemporaryDirectory();
          _currentAudioPath = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.aacLc),
            path: _currentAudioPath!,
          );
        }
        isRecording.value = true;
      }
    } catch (e) {
      print('Error starting record: $e');
    }
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      isRecording.value = false;
      return path;
    } catch (e) {
      print('Error stopping record: $e');
      isRecording.value = false;
      return null;
    }
  }
}