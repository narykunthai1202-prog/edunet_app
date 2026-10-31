import 'dart:async';

import 'package:edunest_app/features/chat/views/chat_profile_view.dart';
import 'package:edunest_app/features/chat/widgets/chat_extras.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/presence.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/chat_block_ext.dart'; // NEW
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

// Color of the delete dialog (change this one line to recolor it).
const Color _kDeleteColor = Color(0xFFC2674B); // warm terracotta

// App-bar icon color (your own 140,90,90 rose-brown, kept from your old file)
const Color _kIconColor = Color.fromARGB(255, 140, 90, 90);
// Plum used for your sent file bubble / picker icons (was blue)
const Color _kPlum = Color(0xFF6B4A5B);
// Color of YOUR file bubble (change this one line to recolor it)
const Color _kFileColor = Color(0xFF2563EB); // same blue as your text bubbles

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

  // I blocked them
  bool isBlocked = false;
  // NEW: they blocked me
  bool theyBlockedMe = false;

  StreamSubscription<bool>? _blockSub;
  StreamSubscription<bool>? _blockedBySub; // NEW
  StreamSubscription<User?>? _authSub;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>
  _receiverProfileStream;
  bool _isSessionValid = false;
  MessageModel? replyingToMessage;
  bool _isTyping = false;
  Timer? _debounceTimer;

  // NEW: true if a block exists in EITHER direction
  bool get _chatLocked => isBlocked || theyBlockedMe;

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
        _blockedBySub?.cancel();
        _blockedBySub = null;
        _chatService.updateUserPresence(widget.currentUserId, false);
        _chatService.setTypingStatus(
          widget.currentUserId,
          widget.receiverId,
          false,
        );
      } else if (!_isSessionValid && isValid) {
        _startBlockListeners();
        _chatService.updateUserPresence(widget.currentUserId, true);
        _chatService.markMessagesAsSeen(
          widget.currentUserId,
          widget.receiverId,
        );
      }
      if (mounted) setState(() => _isSessionValid = isValid);
    });
    if (_isSessionValid) {
      _startBlockListeners();
      _chatService.updateUserPresence(widget.currentUserId, true);
      _chatService.markMessagesAsSeen(widget.currentUserId, widget.receiverId);
    }
  }

  // ------------------------------------------------------------- blocking

  // NEW: starts both listeners (I blocked them / they blocked me)
  void _startBlockListeners() {
    _blockSub?.cancel();
    _blockedBySub?.cancel();

    _blockSub = _watchBlocked().listen((blocked) {
      if (mounted) setState(() => isBlocked = blocked);
      // keep the marker the other user reads in sync (also fixes old blocks)
      _chatService
          .syncBlockMarker(widget.currentUserId, widget.receiverId, blocked)
          .catchError((e) => debugPrint('sync block marker failed: $e'));
    });

    _blockedBySub = _watchBlockedBy().listen((blocked) {
      if (mounted) setState(() => theyBlockedMe = blocked);
    });
  }

  // I blocked them:  users/{me}/blocked/{them}
  Stream<bool> _watchBlocked() => FirebaseFirestore.instance
      .collection('users')
      .doc(widget.currentUserId)
      .collection('blocked')
      .doc(widget.receiverId)
      .snapshots()
      .map((s) => s.exists);

  // NEW - They blocked me: read the marker on the shared chat document
  Stream<bool> _watchBlockedBy() => _chatService.watchBlockedByPeer(
        widget.currentUserId,
        widget.receiverId,
      );

  Future<void> _unblock() =>
      _chatService.unblockUserBothWays(widget.currentUserId, widget.receiverId);

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
              // CHANGED: disabled if blocked in either direction
              onPressed: _chatLocked
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
        color: isMe ? _kFileColor : colors.surfaceContainerHighest,
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
                        ? const Color(0xFFF2C6D6)
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
    if (_chatLocked) return; // NEW
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
              if (_chatLocked) return; // NEW
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
                color: _kPlum,
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
                color: _kPlum,
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
    if (_chatLocked) return;
    try {
      await _chatService.sendFileWithName(
        senderId: widget.currentUserId,
        receiverId: widget.receiverId,
        fileUrl: url,
        fileName: name,
        fileSize: size,
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

  // 🗑️ DELETE
  // Shows the confirm dialog. Result:
  //   null  -> cancelled
  //   false -> delete for me only
  //   true  -> delete for everyone (sender only)
  Future<bool?> _confirmDeleteMessage({required bool canDeleteForEveryone}) {
    bool alsoForOther = false;
    const surface = Colors.white;
    const textDark = Color(0xFF1F2937);

    return showDialog<bool?>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => Dialog(
          backgroundColor: surface,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _kDeleteColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: _kDeleteColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Delete message',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Are you sure you want to delete this message?',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withValues(alpha: 0.6),
                  ),
                ),
                if (canDeleteForEveryone) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => setLocal(() => alsoForOther = !alsoForOther),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: alsoForOther
                            ? _kDeleteColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: alsoForOther
                              ? _kDeleteColor
                              : Colors.black.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            alsoForOther
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 20,
                            color: alsoForOther ? Colors.white : _kDeleteColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Also delete for ${widget.receiverName}',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: alsoForOther ? Colors.white : textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textDark,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                            color: Colors.black.withValues(alpha: 0.12),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, alsoForOther),
                        style: FilledButton.styleFrom(
                          backgroundColor: _kDeleteColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleDelete(MessageModel message) async {
    if (!mounted) return;
    final isMine = message.senderId == widget.currentUserId;

    final forEveryone = await _confirmDeleteMessage(
      canDeleteForEveryone: isMine,
    );
    if (forEveryone == null) return; // cancelled

    try {
      await _chatService.deleteMessage(
        widget.currentUserId,
        widget.receiverId,
        message.id,
        forEveryone: forEveryone,
      );
    } catch (e) {
      _showError('Failed to delete message: $e');
    }
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
    if (_chatLocked) return; // NEW
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
    if (_chatLocked) return; // CHANGED
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
    _blockedBySub?.cancel(); // NEW
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
                        // Warmer, rounder font + dark plum instead of cold black
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF3A2A32),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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
              // CHANGED: disabled if blocked in either direction
              if (_chatLocked)
                const IconButton(
                  icon: Icon(Icons.call, color: _kIconColor),
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
                    icon: Icon(Icons.call, color: _kIconColor),
                  ),
                ),
              if (_chatLocked)
                const IconButton(
                  icon: Icon(Icons.videocam, color: _kIconColor),
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
                    icon: Icon(Icons.videocam, color: _kIconColor),
                  ),
                ),
              IconButton(
                icon: Icon(Icons.info, color: _kIconColor),
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

                final allMessages = snapshot.data ?? [];

                if (allMessages.isNotEmpty) {
                  _chatService.markMessagesAsSeen(
                    widget.currentUserId,
                    widget.receiverId,
                  );
                }

                // 🗑️ Hide messages I deleted "for me", and old messages that
                // were soft-deleted (isDeleted: true). No placeholder bubble.
                final messages = allMessages
                    .where((m) => !m.isHiddenFor(widget.currentUserId))
                    .toList();

                if (messages.isEmpty) {
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
          if (!_chatLocked) _buildReplyBanner(),

          // 📥 MESSAGE INPUT BAR, or a blocked bar
          if (isBlocked)
            // I blocked them -> Unblock / Delete
            BlockedBar(
              name: widget.receiverName,
              onUnblock: _unblock,
              onDelete: () => Navigator.pop(context),
            )
          else if (theyBlockedMe)
            // NEW: they blocked me -> can't reply
            const BlockedByBar()
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