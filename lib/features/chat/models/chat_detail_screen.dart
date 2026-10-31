import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/chat/services/cloudinary_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/chat_controller.dart';
import '../services/chat_service.dart';


class ChatDetailScreen extends StatefulWidget {
  final String currentUserId;
  final String peerId;
  final String peerName;

  const ChatDetailScreen({
    super.key,
    required this.currentUserId,
    required this.peerId,
    required this.peerName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  late final ChatController controller;

  bool _isTyping = false;
  bool isBlocked = false;
  bool _uploadingFile = false;

  StreamSubscription? _blockSubscription;
  StreamSubscription? _theyBlockedSubscription;

  @override
  void initState() {
    super.initState();
    _listenToBlockStatus();

    // Force a fresh controller instance for the active chat pair
    if (Get.isRegistered<ChatController>()) {
      Get.delete<ChatController>();
    }
    controller = Get.put(ChatController());

    // Bind real-time stream for the active room
    controller.listenToMessages(widget.currentUserId, widget.peerId);

    _textController.addListener(() {
      final isTyping = _textController.text.trim().isNotEmpty;
      if (isTyping != _isTyping) {
        setState(() {
          _isTyping = isTyping;
        });
      }
    });
  }

  @override
  void dispose() {
    _blockSubscription?.cancel();
    _theyBlockedSubscription?.cancel();
    _audioPlayer.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleSendText() {
    if (isBlocked) return;

    if (_textController.text.trim().isNotEmpty) {
      controller.sendMessage(
        text: _textController.text.trim(),
        currentUserId: widget.currentUserId,
        peerId: widget.peerId,
      );
      _textController.clear();
    }
  }

  void _listenToBlockStatus() {
    // 1. Check if CURRENT user blocked THIS SPECIFIC PEER
    _blockSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('blocked')
        .doc(widget.peerId)
        .snapshots()
        .listen((iBlockedDoc) {
      if (iBlockedDoc.exists) {
        if (mounted) setState(() => isBlocked = true);
      } else {
        // 2. Check if THIS SPECIFIC PEER blocked CURRENT user
        _theyBlockedSubscription?.cancel();
        _theyBlockedSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.peerId)
            .collection('blocked')
            .doc(widget.currentUserId)
            .snapshots()
            .listen((theyBlockedDoc) {
          if (mounted) {
            setState(() {
              isBlocked = theyBlockedDoc.exists;
            });
          }
        });
      }
    });
  }

  // 🖼️ Send Image Handler
  Future<void> _handleSendImage() async {
    if (isBlocked) return;

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _chatService.sendImageMessage(
        senderId: widget.currentUserId,
        receiverId: widget.peerId,
        imageFile: image,
      );
    }
  }

  // 📎 Send File Handler (NEW)
  Future<void> _handleSendFile() async {
    if (isBlocked) return;

    final file = await FilePicker.pickFile();
    if (file == null) return;

    final size = await file.length();
    if (size != null && size > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 10 MB)')));
      return;
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 10 MB)')));
      return;
    }

    setState(() => _uploadingFile = true);
    try {
      final url = await CloudinaryService.uploadBytes(
        bytes,
        file.name,
        folder: 'chat/files',
      );

      if (url == null) {
        throw Exception('Upload failed');
      }

      // You must add this method to ChatService (see instructions)
      await _chatService.sendFileMessage(
        senderId: widget.currentUserId,
        receiverId: widget.peerId,
        fileUrl: url,
        fileName: file.name,
        fileSize: bytes.length,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not send file: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingFile = false);
    }
  }

  // 📄 File bubble (NEW)
  Widget _buildFileBubble(Map msg, bool isMe) {
    final color = isMe ? Colors.white : Colors.black;
    final String url = (msg['fileUrl'] ?? msg['content'] ?? '').toString();
    final String name = (msg['fileName'] ?? 'File').toString();
    final int size = (msg['fileSize'] is num) ? (msg['fileSize'] as num).toInt() : 0;

    String fmt(int b) {
      if (b <= 0) return '';
      if (b < 1024) return '$b B';
      if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return InkWell(
      onTap: () {
        if (url.isEmpty) return;
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: color, size: 32),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
                if (fmt(size).isNotEmpty)
                  Text(
                    fmt(size),
                    style: TextStyle(
                        color: color.withValues(alpha: 0.7), fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.peerName),
      ),
      body: Column(
        children: [
          // 1. Message List View
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty) {
                return Center(
                  child: Text('Start chatting with ${widget.peerName}'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: controller.messages.length,
                itemBuilder: (context, index) {
                  final msg = controller.messages[index];
                  final isMe = msg['isMe'] ?? true;
                  final isAudio = msg['type'] == 'audio';
                  final isImage = msg['type'] == 'image';
                  final isFile = msg['type'] == 'file';

                  return Align(
                    alignment:
                        isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[600] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: isAudio
                          ? InkWell(
                              onTap: () async {
                                final String path = msg['content'];
                                await _audioPlayer.stop();

                                if (path.startsWith('http://') ||
                                    path.startsWith('https://') ||
                                    path.startsWith('blob:')) {
                                  await _audioPlayer.play(UrlSource(path));
                                } else {
                                  await _audioPlayer
                                      .play(DeviceFileSource(path));
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_circle_fill,
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Voice Message',
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : isFile
                              ? _buildFileBubble(msg, isMe)
                              : isImage
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        msg['content'] ?? '',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(Icons.broken_image,
                                                    size: 50),
                                      ),
                                    )
                                  : Text(
                                      msg['content'] ?? '',
                                      style: TextStyle(
                                        color:
                                            isMe ? Colors.white : Colors.black,
                                      ),
                                    ),
                    ),
                  );
                },
              );
            }),
          ),

          // 2. Conditional Input Bar vs Block Banner
          SafeArea(
            child: isBlocked
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: const Color(0xFFF1F5F9),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.block, color: Color(0xFFEF4444), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Messaging unavailable (Blocked)',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: Colors.white,
                    child: Row(
                      children: [
                        // Image picker button
                        IconButton(
                          icon: const Icon(Icons.image, color: Colors.blue),
                          onPressed: _handleSendImage,
                        ),

                        // File picker button (NEW)
                        _uploadingFile
                            ? const SizedBox(
                                width: 40,
                                height: 40,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.attach_file,
                                    color: Colors.grey),
                                onPressed: _handleSendFile,
                              ),

                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),

                        // Toggle Send Button when typing vs Mic Button when idle
                        _isTyping
                            ? CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: IconButton(
                                  icon: const Icon(Icons.send,
                                      color: Colors.white, size: 18),
                                  onPressed: _handleSendText,
                                ),
                              )
                            : Obx(() {
                                final isRec = controller.isRecording.value;

                                return GestureDetector(
                                  onTapDown: (_) {
                                    print('>>> Mic Tapped Down');
                                  },
                                  onLongPressStart: (_) async {
                                    if (isBlocked) return;
                                    print('>>> Mic Long Press Started');
                                    await controller.startRecording();
                                  },
                                  onLongPressEnd: (_) async {
                                    if (isBlocked) return;
                                    print('>>> Mic Long Press Ended');
                                    final String? recordedFilePath =
                                        await controller.stopRecording();

                                    if (recordedFilePath != null &&
                                        recordedFilePath.isNotEmpty) {
                                      print(
                                          '>>> Adding audio message locally...');
                                      controller.messages.add({
                                        'type': 'audio',
                                        'content': recordedFilePath,
                                        'isMe': true,
                                        'time': DateTime.now(),
                                      });
                                      controller.messages.refresh();

                                      try {
                                        print(
                                            '>>> Starting Firebase Upload...');
                                        final String audioUrl =
                                            await _chatService
                                                .uploadVoiceMessage(
                                                    recordedFilePath);
                                        print(
                                            '>>> Upload complete. URL: $audioUrl');

                                        await _chatService.sendAudioMessage(
                                          senderId: widget.currentUserId,
                                          receiverId: widget.peerId,
                                          audioBase64OrUrl: audioUrl.isNotEmpty
                                              ? audioUrl
                                              : recordedFilePath,
                                        );
                                        print(
                                            '>>> Sent audio message to Firestore');
                                      } catch (e) {
                                        print(
                                            '>>> Firebase error during audio send: $e');
                                      }
                                    } else {
                                      print(
                                          '>>> Warning: Recorded file path was null or empty');
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
          ),
        ],
      ),
    );
  }
}