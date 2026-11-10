import 'dart:async';

import 'package:edunest_app/features/chat/models/message_model.dart';
import 'package:edunest_app/features/chat/widgets/chat_options_sheet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/chat_block_ext.dart';
import '../services/chat_service.dart';
import '../widgets/shared_media_tabs.dart';

class ChatProfileView extends StatefulWidget {
  final String receiverName;
  final String? receiverPhotoUrl;
  final String currentUserId;
  final String receiverId;
  final String chatId;

  const ChatProfileView({
    super.key,
    required this.receiverName,
    this.receiverPhotoUrl,
    required this.currentUserId,
    required this.receiverId,
    required this.chatId,
  });

  @override
  State<ChatProfileView> createState() => _ChatProfileViewState();
}

class _ChatProfileViewState extends State<ChatProfileView> {
  // 🎨 Profile colors (edit here to restyle the whole screen)
  static const _plum = Color(0xFF6B4A5B); // main accent
  static const _plumLight = Color(0xFFA58A92); // gradient end
  static const _rose = Color(0xFFE0BCC4); // dusty rose badges
  static const _card = Color(0xFFEEE8E7); // dialog / card surface
  static const _field = Color(0xFFE5DFDC); // inputs, cancel buttons
  static const _textDark = Color(0xFF3A2A32); // dark plum-brown text
  static const _muted = Color(0xFF7A6670); // muted text
  static const _danger = Color(0xFFC2674B); // terracotta (block / purge)
  static const _warn = Color(0xFFD08A4E); // dusty orange (report)

  final ChatService _chatService = ChatService();
  bool isMuted = false;
  late String activeChatRoomId;
  late final Stream<List<MessageModel>> _messagesStream;

  String? _nickname;
  StreamSubscription<String?>? _nickSub;
  bool get _hasNickname => _nickname != null && _nickname!.isNotEmpty;
  String get _displayName => _hasNickname ? _nickname! : widget.receiverName;

  @override
  void initState() {
    super.initState();

    activeChatRoomId = widget.chatId.isNotEmpty
        ? widget.chatId
        : _chatService.getChatRoomId(widget.currentUserId, widget.receiverId);

    // Messages of this chat for the Media / Files / Links card
    _messagesStream = FirebaseFirestore.instance
        .collection('chats')
        .doc(activeChatRoomId)
        .collection('messages')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => MessageModel.fromMap(d.data(), d.id))
              // don't count media the user deleted
              .where((m) => !m.isHiddenFor(widget.currentUserId))
              .toList(),
        );

    _nickSub = _chatService
        .watchNickname(widget.currentUserId, activeChatRoomId)
        .listen((nick) {
          if (mounted) setState(() => _nickname = nick);
        });

    _loadMuteStatus();
  }

  Future<void> _loadMuteStatus() async {
    final muted = await _chatService.isChatMuted(
      currentUserId: widget.currentUserId,
      chatId: activeChatRoomId,
    );
    if (mounted) {
      setState(() {
        isMuted = muted;
      });
    }
  }

  Future<void> _handleMuteToggle(bool value) async {
    setState(() {
      isMuted = value;
    });

    try {
      await _chatService.toggleMuteChat(
        currentUserId: widget.currentUserId,
        chatId: activeChatRoomId,
        isMuted: value,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value ? 'Chat muted' : 'Chat unmuted'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isMuted = !value;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update mute status: $e')),
        );
      }
    }
  }

  Future<void> _handleSetNickname() async {
    final result = await showNicknameDialog(
      context,
      realName: widget.receiverName,
      currentNickname: _nickname,
    );
    if (result == null) return; // cancelled

    try {
      await _chatService.setNickname(
        widget.currentUserId,
        activeChatRoomId,
        result,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.isEmpty ? 'Nickname removed' : 'Nickname saved',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save nickname: $e')));
      }
    }
  }

  // Shared look for the Cancel button in all dialogs
  ButtonStyle get _cancelStyle => TextButton.styleFrom(
    backgroundColor: _field,
    padding: const EdgeInsets.symmetric(vertical: 14),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );

  Future<void> _handleBlockUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: _card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.block, color: _danger, size: 32),
              ),
              const SizedBox(height: 18),
              Text(
                'Block ${widget.receiverName}?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "They won't be able to message or call you, and you won't be able to message or call them unless you unblock.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _muted, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: _cancelStyle,
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Block',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
           await _chatService.blockUserBothWays(widget.currentUserId, widget.receiverId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.receiverName} has been blocked.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error blocking user: $e')));
      }
    }
  }

  Future<void> _handleReportUser() async {
    const reasons = [
      'Spam',
      'Harassment or bullying',
      'Inappropriate content',
      'Fake account or scam',
      'Other',
    ];
    String? selected;
    final detailsController = TextEditingController();

    final submit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => Dialog(
          backgroundColor: _card,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: _warn.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag, color: _warn, size: 32),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Report ${widget.receiverName}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...reasons.map(
                    (r) => RadioListTile<String>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: _plum,
                      title: Text(
                        r,
                        style: const TextStyle(color: _textDark),
                      ),
                      value: r,
                      groupValue: selected,
                      onChanged: (v) => setLocal(() => selected = v),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: detailsController,
                    maxLines: 3,
                    cursorColor: _plum,
                    decoration: InputDecoration(
                      hintText: 'Add details (optional)',
                      hintStyle: const TextStyle(color: _muted),
                      filled: true,
                      fillColor: _field,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: _cancelStyle,
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: _textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            backgroundColor: selected == null
                                ? Colors.grey.shade300
                                : _warn,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: selected == null
                              ? null
                              : () => Navigator.pop(context, true),
                          child: const Text(
                            'Report',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (submit != true || selected == null) return;

    try {
      await _chatService.reportUser(
        reporterId: widget.currentUserId,
        reportedId: widget.receiverId,
        reason: selected!,
        details: detailsController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent. Thank you.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not send report: $e')));
      }
    }
  }

  Future<void> _handlePurgeMessages() async {
    // small "what will be deleted" pill used inside the dialog
    Widget pill(IconData icon, String text) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _muted),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: _textDark,
            ),
          ),
        ],
      ),
    );

    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: _card,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: _danger,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Purge all messages?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Everything in this conversation will be deleted for good:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _muted, height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  pill(Icons.chat_bubble_rounded, 'Messages'),
                  pill(Icons.photo_library_rounded, 'Photos & videos'),
                  pill(Icons.insert_drive_file_rounded, 'Files'),
                  pill(Icons.link_rounded, 'Links'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _danger.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _danger.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: _danger,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: _danger,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: _cancelStyle,
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: _textDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete all',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    try {
      await _chatService.purgeMessages(
        currentUserId: widget.currentUserId,
        receiverId: widget.receiverId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All messages purged successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error purging messages: $e')));
      }
    }
  }

  @override
  void dispose() {
    _nickSub?.cancel();
    super.dispose();
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textDark,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'PROFILE',
          style: TextStyle(
            color: _textDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _header(),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SharedMediaTabs(
                messages: _messagesStream,
                currentUserId: widget.currentUserId,
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _safetyCard(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- header

  Widget _header() {
    final top = MediaQuery.of(context).padding.top + kToolbarHeight;
    final photoUrl = widget.receiverPhotoUrl?.trim();
    final profileImage = photoUrl == null || photoUrl.isEmpty
        ? null
        : NetworkImage(photoUrl);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, top + 6, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF2E2E6), _rose, Color(0xFFD3A9B4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Column(
        children: [
          // avatar with soft cream ring
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EDEB),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 52,
              backgroundColor: _rose,
              backgroundImage: profileImage,
              child: profileImage != null
                  ? null
                  : Text(
                      _displayName.isNotEmpty
                          ? _displayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 42,
                        color: _plum,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // name
          Text(
            _displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _textDark,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (_hasNickname)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                widget.receiverName,
                style: const TextStyle(color: _muted, fontSize: 13),
              ),
            ),
          const SizedBox(height: 10),

          // active chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(radius: 4, backgroundColor: Color(0xFF4ADE80)),
                SizedBox(width: 7),
                Text(
                  'Active now',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // quick actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _action(
                Icons.edit_rounded,
                _hasNickname ? 'Nickname' : 'Set nickname',
                _handleSetNickname,
              ),
              _action(
                isMuted
                    ? Icons.notifications_off_rounded
                    : Icons.notifications_active_rounded,
                isMuted ? 'Muted' : 'Mute',
                () => _handleMuteToggle(!isMuted),
                active: isMuted,
              ),
              _action(Icons.flag_rounded, 'Report', _handleReportUser),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: active
                  ? _plum
                  : Colors.white.withValues(alpha: 0.65),
              shape: BoxShape.circle,
              border: Border.all(
                color: _plum.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(icon, color: active ? Colors.white : _plum, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: _textDark,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------ privacy and safety

  Widget _safetyCard() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: _plum.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_plumLight, _plum],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Privacy & safety',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _safetyRow(
            icon: Icons.block_rounded,
            color: _danger,
            title: 'Block user',
            subtitle: 'Stop messages and calls',
            onTap: _handleBlockUser,
          ),
          _safetyRow(
            icon: Icons.delete_outline_rounded,
            color: _danger,
            title: 'Purge messages',
            subtitle: 'Delete the whole conversation',
            onTap: _handlePurgeMessages,
          ),
        ],
      ),
    );
  }

  Widget _safetyRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}