import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_audio_bubble.dart';

class ChatDetailView extends StatefulWidget {
  final String receiverName;
  final String currentUserId;
  final String receiverId;

  const ChatDetailView({
    super.key,
    required this.receiverName,
    required this.currentUserId,
    required this.receiverId,
  });

  @override
  State<ChatDetailView> createState() => _ChatDetailViewState();
}

class _ChatDetailViewState extends State<ChatDetailView> {
  final TextEditingController _messageController = TextEditingController();
  late final ChatController controller;
  bool _isTyping = false;
  bool isBlocked = false;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
    controller = Get.put(ChatController());
    _messageController.addListener(() {
      setState(() {
        _isTyping = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> unblockUser() async {
  await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUserId)
      .collection('blocked')
      .doc(widget.receiverId)
      .delete();

  if (mounted) {
    setState(() {
      isBlocked = false;
    });
  }
}


Future<void> _checkBlockStatus() async {
  // Check if I blocked them
  final iBlocked = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUserId)
      .collection('blocked')
      .doc(widget.receiverId)
      .get();

  // Check if they blocked me
  final theyBlocked = await FirebaseFirestore.instance
      .collection('users')
      .doc(widget.receiverId)
      .collection('blocked')
      .doc(widget.currentUserId)
      .get();

  if (mounted) {
    setState(() {
      isBlocked = iBlocked.exists || theyBlocked.exists;
    });
  }
}

  // ✉️ Send Text Message
  Future<void> _sendTextMessage(String chatRoomId) async {
    if (isBlocked) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);

    await chatDocRef.collection('messages').add({
      'senderId': widget.currentUserId,
      'type': 'text',
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatDocRef.set({
      'participants': [widget.currentUserId, widget.receiverId],
      'receiverName': widget.receiverName,
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': widget.currentUserId,
      'unreadCount_${widget.receiverId}': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // ☁️ Upload Audio File/Bytes to Firebase Storage
  Future<String> _uploadAudioToStorage(String filePath) async {
    String fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    Reference ref = FirebaseStorage.instance.ref().child('chat_voices/$fileName');

    TaskSnapshot snap;
    if (kIsWeb) {
      final Uint8List audioBytes = await XFile(filePath).readAsBytes();
      snap = await ref.putData(audioBytes, SettableMetadata(contentType: 'audio/m4a'));
    } else {
      snap = await ref.putFile(File(filePath));
    }

    return await snap.ref.getDownloadURL();
  }

  // 🎤 Send Voice Message
  Future<void> _sendVoiceMessage({
    required String chatRoomId,
    required String audioUrl,
  }) async {
    if (isBlocked) return;

    final chatDocRef = FirebaseFirestore.instance.collection('chats').doc(chatRoomId);

    await chatDocRef.collection('messages').add({
      'senderId': widget.currentUserId,
      'receiverId': widget.receiverId,
      'type': 'audio',
      'audioUrl': audioUrl,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await chatDocRef.set({
      'participants': [widget.currentUserId, widget.receiverId],
      'receiverName': widget.receiverName,
      'lastMessage': '🎤 Voice message',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'lastSenderId': widget.currentUserId,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final List<String> ids = [widget.currentUserId, widget.receiverId]..sort();
    final String chatRoomId = ids.join('_');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(chatRoomId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Say hi! 👋', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == widget.currentUserId;
                    final isAudio = data['type'] == 'audio' || data['type'] == 'voice';

                    if (isAudio) {
                      return Align(
                        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: ChatAudioBubble(
                          audioUrl: data['mediaUrl'] ?? data['audioUrl'] ?? data['url'] ?? '',
                          isMe: isMe,
                          formattedTime: data['durationMs'] != null 
                              ? '${(data['durationMs'] / 1000).floor()}s' 
                              : '0:00',
                        ),
                      );
                    }

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          data['text'] ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Conditional Input Bar or Block Banner
          isBlocked
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFFF1F5F9),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.block, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'You have blocked ${widget.receiverName}.',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _isTyping
                          ? IconButton(
                              icon: const Icon(Icons.send, color: Color(0xFF2563EB)),
                              onPressed: () => _sendTextMessage(chatRoomId),
                            )
                          : Obx(() {
                              final isRec = controller.isRecording.value;

                              return GestureDetector(
                                onLongPressStart: (_) => controller.startRecording(),
                                onLongPressEnd: (_) async {
                                  final String? recordedFilePath = await controller.stopRecording();

                                  if (recordedFilePath != null && recordedFilePath.isNotEmpty) {
                                    final String audioUrl = await _uploadAudioToStorage(recordedFilePath);
                                    await _sendVoiceMessage(
                                      chatRoomId: chatRoomId,
                                      audioUrl: audioUrl,
                                    );
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isRec ? Colors.red : Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isRec ? Icons.mic : Icons.mic_none,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            }),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}