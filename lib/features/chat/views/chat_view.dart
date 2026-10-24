import 'dart:async';

import 'package:edunest_app/features/chat/views/chat_profile_view.dart';
import 'package:edunest_app/features/chat/widgets/chat_extras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/presence.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../widgets/blocked_bar.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/group_avatar.dart';
import '../widgets/message_options.dart';
import '../widgets/image_preview_dialog.dart';
import '../widgets/chat_image_bubble.dart';
import '../widgets/chat_text_bubble.dart';
import '../widgets/chat_audio_bubble.dart';
import '../widgets/forward_contact_sheet.dart';

import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit/zego_uikit.dart';

class ChatView extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  final String chatId;
  final String? peerId; // optional now

  const ChatView({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    required this.chatId,
    this.peerId,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  bool isBlocked = false;
  StreamSubscription<bool>? _blockSub;
  StreamSubscription<User?>? _authSub;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>
  _receiverProfileStream;
  bool _isSessionValid = false;
  MessageModel? replyingToMessage;
  bool _isTyping = false;
  Timer? _debounceTimer;

  // Available everywhere in this class (not only inside build)
  String get _conversationId {
    final ids = [widget.currentUserId, widget.receiverId]..sort();
    return ids.join('_');
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  void initState() {
    super.initState();
    _receiverProfileStream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.receiverId)
        .snapshots();
    _isSessionValid =
        FirebaseAuth.instance.currentUser?.uid == widget.currentUserId;
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final isValid = user?.uid == widget.currentUserId;
      if (_isSessionValid && !isValid) {
        _blockSub?.cancel();
        _blockSub = null;
        _chatService.updateUserPresence(widget.currentUserId, false);
        _chatService.setTypingStatus(
          widget.currentUserId,
          widget.receiverId,
          false,
        );
      } else if (!_isSessionValid && isValid) {
        _blockSub = _watchBlocked().listen((blocked) {
          if (mounted) setState(() => isBlocked = blocked);
        });
        _chatService.updateUserPresence(widget.currentUserId, true);
        _chatService.markMessagesAsSeen(
          widget.currentUserId,
          widget.receiverId,
        );
      }
      if (mounted) setState(() => _isSessionValid = isValid);
    });
    if (_isSessionValid) {
      _blockSub = _watchBlocked().listen((blocked) {
        if (mounted) setState(() => isBlocked = blocked);
      });
      _chatService.updateUserPresence(widget.currentUserId, true);
      _chatService.markMessagesAsSeen(widget.currentUserId, widget.receiverId);
    }
  }

  // ------------------------------------------------------------- blocking

  Stream<bool> _watchBlocked() => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUserId)
      .collection('blocked')
      .doc(widget.receiverId)
      .snapshots()
      .map((s) => s.exists);

  Future<void> _unblock() => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUserId)
      .collection('blocked')
      .doc(widget.receiverId)
      .delete();

  // --------------------------------------------------------------- helpers

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _mediaWithTime(Widget media, String time, bool isMe) {
    return Column(
      crossAxisAlignment: isMe
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        media,
        const SizedBox(height: 2),
        Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 10)),
      ],
    );
  }

  // Gets a readable file name out of a Cloudinary URL
  String _fileNameFromUrl(String url) {
    try {
      final last = Uri.parse(url).pathSegments.last;
      return Uri.decodeComponent(last);
    } catch (_) {
      return 'File';
    }
  }

  // 📞 Call bubble (Messenger style). message.text looks like:
  //   "Voice call • 2 min"  /  "Video call • 45 sec"  /  "Missed voice call"
  Widget _buildCallBubble(MessageModel message, bool isMe, String time) {
    final colors = Theme.of(context).colorScheme;
    final text = message.text;
    final isVideo = text.toLowerCase().contains('video');
    final missed = text.startsWith('Missed');
    final title = isVideo ? 'Video call' : 'Audio call';

    String subtitle;
    if (missed) {
      subtitle = isMe ? 'No answer' : 'Missed call';
    } else {
      final i = text.indexOf('•');
      subtitle = i >= 0 ? text.substring(i + 1).trim() : 'Call ended';
    }

    IconData icon;
    if (missed) {
      icon = Icons.call_missed;
    } else if (isVideo) {
      icon = Icons.videocam;
    } else {
      icon = isMe ? Icons.call_made : Icons.call_received;
    }

    return Container(
      width: 250,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: colors.primaryContainer,
                child: Icon(
                  icon,
                  color: (missed && !isMe) ? Colors.redAccent : colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.onSurface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: isBlocked
                  ? null
                  : () {
                      ZegoUIKitPrebuiltCallInvitationService().send(
                        invitees: [
                          ZegoCallUser(widget.receiverId, widget.receiverName),
                        ],
                        isVideoCall: isVideo,
                      );
                    },
              child: const Text('Call back'),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              time,
              style: TextStyle(color: Colors.grey[600], fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  // 📄 File bubble
  Widget _buildFileBubble(MessageModel message, bool isMe, String time) {
    final colors = Theme.of(context).colorScheme;
    final textColor = isMe ? Colors.white : colors.onSurface;
    final url = (message.fileUrl != null && message.fileUrl!.isNotEmpty)
        ? message.fileUrl!
        : message.text;
    final name = (message.fileName != null && message.fileName!.isNotEmpty)
        ? message.fileName!
        : _fileNameFromUrl(url);
    final size = message.fileSize ?? 0;

    String fmt(int b) {
      if (b <= 0) return '';
      if (b < 1024) return '$b B';
      if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFF2563EB) : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              if (url.isEmpty) return;
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insert_drive_file, color: textColor, size: 32),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (fmt(size).isNotEmpty)
                        Text(
                          fmt(size),
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isSeen
                        ? Icons.done_all_rounded
                        : Icons.done_rounded,
                    size: 14,
                    color: message.isSeen
                        ? Colors.lightBlueAccent
                        : Colors.white70,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📸 Pick Image with Full Preview Dialog before uploading
  Future<void> _pickAndSendImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (pickedFile != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImagePreviewDialog(
            imageFile: pickedFile,
            onSend: () async {
              try {
                await _chatService.sendImageMessage(
                  senderId: widget.currentUserId,
                  receiverId: widget.receiverId,
                  imageFile: pickedFile,
                );
                _scrollToBottom();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send image: $e')),
                  );
                }
              }
            },
          ),
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF2563EB),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_rounded,
                color: Color(0xFF2563EB),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 📎 File: uploaded by ChatInputField, saved here with the same
  // sendMessage() that your other message types use.
  Future<void> _sendFile(String url, String name, int size) async {
    if (isBlocked) return;
    try {
      await _chatService.sendMessage(
        widget.currentUserId,
        widget.receiverId,
        url,
        type: 'file',
      );
      _scrollToBottom();
    } catch (e) {
      _showError('Failed to send file: $e');
    }
  }

  // 📍 Message Context Handlers
  void _handleCopy(MessageModel message) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
  }

  void _handleReply(MessageModel message) {
    setState(() {
      replyingToMessage = message;
    });
  }

  Future<void> _handleForward(MessageModel message) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => ForwardContactSheet(
        currentUserId: widget.currentUserId,
        onSelectUser: (targetUserId, targetUserName) async {
          await _chatService.sendMessage(
            widget.currentUserId,
            targetUserId,
            message.text,
            type: message.type,
            isForwarded: true,
          );

          if (!mounted) return;

          Navigator.pop(modalContext);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Forwarded to $targetUserName'),
              behavior: SnackBarBehavior.floating,
            ),
          );

          List<String> ids = [widget.currentUserId, targetUserId]..sort();
          String targetChatId = ids.join('_');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ChatView(
                currentUserId: widget.currentUserId,
                receiverId: targetUserId,
                receiverName: targetUserName,
                chatId: targetChatId,
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleDelete(MessageModel message) async {
    await _chatService.deleteMessage(
      widget.currentUserId,
      widget.receiverId,
      message.id,
    );
  }

  void _handleUnsend(MessageModel message) async {
    await _chatService.unsendMessage(
      widget.currentUserId,
      widget.receiverId,
      message.id,
    );
  }

  void _showMessageOptions(BuildContext context, MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MessageOptionsSheet(
        message: message,
        currentUserId: widget.currentUserId,
        onReactionSelected: (emoji) {
          _chatService.toggleReaction(
            widget.currentUserId,
            widget.receiverId,
            message.id,
            emoji,
          );
        },
        onReply: () => _handleReply(message),
        onCopy: () => _handleCopy(message),
        onForward: () => _handleForward(message),
        onUnsend: () => _handleUnsend(message),
        onDelete: () => _handleDelete(message),
      ),
    );
  }

  void _handleTyping() {
    if (!_isTyping) {
      _isTyping = true;
      _chatService.setTypingStatus(
        widget.currentUserId,
        widget.receiverId,
        true,
      );
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _chatService.setTypingStatus(
          widget.currentUserId,
          widget.receiverId,
          false,
        );
      }
    });
  }

  void _sendMessage(String text) {
    if (isBlocked) return;
    final trimmedText = text.trim();
    if (trimmedText.isNotEmpty) {
      if (replyingToMessage != null) {
        _chatService.sendMessageWithReply(
          senderId: widget.currentUserId,
          receiverId: widget.receiverId,
          text: trimmedText,
          replyToText: replyingToMessage!.text,
        );
        setState(() {
          replyingToMessage = null;
        });
      } else {
        _chatService.sendMessage(
          widget.currentUserId,
          widget.receiverId,
          trimmedText,
        );
      }

      _isTyping = false;
      _chatService.setTypingStatus(
        widget.currentUserId,
        widget.receiverId,
        false,
      );
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _blockSub?.cancel();
    _authSub?.cancel();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    if (_isSessionValid) {
      _chatService.setTypingStatus(
        widget.currentUserId,
        widget.receiverId,
        false,
      );
    }
    // (presence is handled by the chat list screen, so leaving a chat
    // does not make you look offline)
    super.dispose();
  }

  String _receiverDisplayName(Map<String, dynamic>? profile) {
    final profileName = profile?['name']?.toString().trim();
    if (profileName != null &&
        profileName.isNotEmpty &&
        profileName != widget.receiverId) {
      return profileName;
    }

    final fallbackName = widget.receiverName.trim();
    if (fallbackName.isNotEmpty && fallbackName != widget.receiverId) {
      return fallbackName;
    }
    return 'User';
  }

  String? _receiverPhotoUrl(Map<String, dynamic>? profile) {
    final photoUrl = profile?['profileImageUrl']?.toString().trim();
    return photoUrl == null || photoUrl.isEmpty ? null : photoUrl;
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _receiverProfileStream,
        builder: (context, snapshot) {
          final colors = Theme.of(context).colorScheme;
          final profile = snapshot.data?.data();
          final receiverName = _receiverDisplayName(profile);
          final receiverPhotoUrl = _receiverPhotoUrl(profile);

          return AppBar(
            backgroundColor: colors.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                GroupAvatar(
                  name: receiverName,
                  photoUrl: receiverPhotoUrl,
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        receiverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (snapshot.hasError)
                        const Text(
                          'Unable to load profile',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                          ),
                        )
                      else
                        PresenceLabel(userId: widget.receiverId),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (isBlocked)
                const IconButton(
                  icon: Icon(Icons.call, color: Colors.grey),
                  onPressed: null,
                )
              else
                ZegoSendCallInvitationButton(
                  isVideoCall: false,
                  resourceID: "zego_call",
                  invitees: [
                    ZegoUIKitUser(id: widget.receiverId, name: receiverName),
                  ],
                  onPressed: (code, message, errors) {
                    debugPrint(
                      'VOICE CALL RESULT -> code: $code, message: $message, errors: $errors',
                    );
                  },
                  iconSize: const Size(40, 40),
                  buttonSize: const Size(40, 40),
                  icon: ButtonIcon(
                    icon: Icon(Icons.call, color: colors.primary),
                  ),
                ),
              if (isBlocked)
                const IconButton(
                  icon: Icon(Icons.videocam, color: Colors.grey),
                  onPressed: null,
                )
              else
                ZegoSendCallInvitationButton(
                  isVideoCall: true,
                  resourceID: "zego_call",
                  invitees: [
                    ZegoUIKitUser(id: widget.receiverId, name: receiverName),
                  ],
                  onPressed: (code, message, errors) {
                    debugPrint(
                      'VIDEO CALL RESULT -> code: $code, message: $message, errors: $errors',
                    );
                  },
                  iconSize: const Size(40, 40),
                  buttonSize: const Size(40, 40),
                  icon: ButtonIcon(
                    icon: Icon(Icons.videocam, color: colors.primary),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.info, color: colors.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatProfileView(
                        receiverName: receiverName,
                        receiverPhotoUrl: receiverPhotoUrl,
                        currentUserId: widget.currentUserId,
                        receiverId: widget.receiverId,
                        chatId: widget.chatId,
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (!_isSessionValid) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colors.onSurface),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Your signed-in account changed. Reopen this chat.'),
        ),
      );
    }

    final conversationId = _conversationId;

    debugPrint(
      'CALL CHECK -> me: ${widget.currentUserId}, receiver: ${widget.receiverId}',
    );

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 💬 MESSAGES LIST
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatService.getMessagesStream(
                widget.currentUserId,
                widget.receiverId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isNotEmpty) {
                  _chatService.markMessagesAsSeen(
                    widget.currentUserId,
                    widget.receiverId,
                  );
                } else {
                  return const Center(
                    child: Text(
                      'No messages yet. Say hi! 👋',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUserId;
                    final time = _formatTime(message.timestamp);

                    Widget content;
                    switch (message.type) {
                      case 'image':
                        content = ChatImageBubble(
                          message: message,
                          isMe: isMe,
                          formattedTime: time,
                        );
                        break;
                      case 'audio':
                        content = ChatAudioBubble(
                          message: message,
                          isMe: isMe,
                          formattedTime: time,
                        );
                        break;
                      case 'sticker':
                        content = _mediaWithTime(
                          StickerBubble(path: message.text),
                          time,
                          isMe,
                        );
                        break;
                      case 'video':
                        content = _mediaWithTime(
                          VideoBubble(url: message.text),
                          time,
                          isMe,
                        );
                        break;
                      case 'file':
                        content = _buildFileBubble(message, isMe, time);
                        break;
                      case 'call':
                        content = _buildCallBubble(message, isMe, time);
                        break;
                      default:
                        content = ChatTextBubble(
                          message: message,
                          isMe: isMe,
                          formattedTime: time,
                        );
                    }

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () =>
                            _showMessageOptions(context, message),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: content,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 💬 REPLY BANNER
          if (!isBlocked) _buildReplyBanner(),

          // 📥 MESSAGE INPUT BAR, or the blocked bar
          if (isBlocked)
            BlockedBar(
              name: widget.receiverName,
              onUnblock: _unblock,
              onDelete: () => Navigator.pop(context),
            )
          else
            NotificationListener<KeepAliveNotification>(
              onNotification: (_) {
                _handleTyping();
                return false;
              },
              child: ChatInputField(
                conversationId: conversationId,
                currentUserId: widget.currentUserId,
                receiverId: widget.receiverId,
                onSendMessage: _sendMessage,
                onPickImage: _showImagePickerOptions,
                onSendFile: _sendFile,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReplyBanner() {
    if (replyingToMessage == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    final isReplyImage = replyingToMessage!.type == 'image';
    final isReplyAudio = replyingToMessage!.type == 'audio';
    final isReplyFile = replyingToMessage!.type == 'file';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.reply, color: colors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                if (isReplyAudio)
                  Row(
                    children: [
                      Icon(Icons.mic, size: 16, color: colors.onSurface),
                      SizedBox(width: 4),
                      Text('Voice message', style: TextStyle(fontSize: 13)),
                    ],
                  )
                else if (isReplyFile)
                  Row(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 16,
                        color: colors.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          (replyingToMessage!.fileName != null &&
                                  replyingToMessage!.fileName!.isNotEmpty)
                              ? replyingToMessage!.fileName!
                              : _fileNameFromUrl(replyingToMessage!.text),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  )
                else if (isReplyImage)
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          replyingToMessage!.text,
                          width: 32,
                          height: 32,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.image,
                                size: 24,
                                color: Colors.grey,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Photo',
                        style: TextStyle(fontSize: 13, color: colors.onSurface),
                      ),
                    ],
                  )
                else
                  Text(
                    replyingToMessage!.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: colors.onSurface),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                replyingToMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }
}
