<<<<<<< HEAD
// lib/chat/views/group_chat_view.dart
import 'dart:async';
import 'package:edunest_app/features/chat/views/voice_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'; // NEW (tappable links)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart'; // NEW
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../services/cloudinary_service.dart';
import '../services/group_service.dart';
import '../services/chat_service.dart'; // NEW (forward)
import '../models/message_model.dart'; // NEW
import '../widgets/message_options.dart'; // NEW
import '../widgets/forward_contact_sheet.dart'; // NEW
import '../widgets/group_avatar.dart';
import 'group_info_view.dart';
import 'image_preview_view.dart';
import '../widgets/video_preview_screen.dart';

class GroupChatView extends StatefulWidget {
  final String groupId;
  final String currentUserId;

  const GroupChatView({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  State<GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<GroupChatView> {
  // 🎨 Screen colors (edit here to restyle the whole group chat)
  static const _plum = Color(0xFF6B4A5B); // send button, accents
  static const _bubbleBlue = Color(0xFF2962FF); // sent message bubbles
  static const _fileColor = _bubbleBlue; // sent FILE bubble (change this one line)
  static const _incomingBubble = Color(0xFFF3EFF0); // received message bubbles
  static const _textDark = Color(0xFF3A2A32); // dark plum-brown text
  static const _muted = Color(0xFF7A6670); // muted text
  static const _iconColor = Color.fromARGB(255, 140, 90, 90); // app-bar icons
  static const _inputIcon = Color(0xFF9A7B86); // attach / emoji icons
  static const _danger = Color(0xFFC2674B); // cancel recording

  final GroupService _service = GroupService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final AudioRecorder _recorder = AudioRecorder();

  List<String> _participants = [];
  List<String> _stickers = [];
  bool _showPanel = false; // emoji / sticker panel
  bool _sending = false;
  double? _videoProgress; // NEW: 0.0 - 1.0 while a video uploads
  bool _hasText = false;
  bool _recording = false;
  int _seconds = 0;
  Timer? _timer;
  Map<String, dynamic>? _replyTo; // NEW: message I'm replying to

  // NEW: typing / pin / mentions / mute / seen
  Timer? _typingTimer;
  bool _iAmTyping = false;
  String? _pinnedId;
  Set<String> _blocked = {}; // users I blocked
  StreamSubscription<List<String>>? _blockSub;
  final Map<String, String> _memberNames = {};
  String _namesKey = '';
  String? _mentionQuery; // null = no @ suggestions
  bool _isMuted = false;
  final Set<String> _seenRequested = {};
  final Map<String, Future<String>> _typingFutures = {};
  final Map<String, TapGestureRecognizer> _linkTaps = {};

  // NEW: search
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStickers();
    _loadMuted();
    _blockSub = _service.watchBlocked(widget.currentUserId).listen((ids) {
      if (mounted) setState(() => _blocked = ids.toSet());
    });
    _focus.addListener(() {
      if (_focus.hasFocus && _showPanel) setState(() => _showPanel = false);
    });
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
      _handleTyping();
      _updateMention();
    });
  }

  @override
  void dispose() {
    _blockSub?.cancel();
    for (final t in _linkTaps.values) {
      t.dispose();
    }
    _typingTimer?.cancel();
    if (_iAmTyping) {
      _service.setGroupTyping(widget.groupId, widget.currentUserId, false);
    }
    _timer?.cancel();
    _recorder.dispose();
    _controller.dispose();
    _searchCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadStickers() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final list =
          manifest
              .listAssets()
              .where((p) => p.startsWith('assets/stickers/'))
              .toList()
            ..sort();
      if (mounted) setState(() => _stickers = list);
    } catch (_) {}
  }

  // ---------------------------------------------------------------- sending

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final mentions = _mentionsIn(text);
    _controller.clear();
    _stopTyping();

    final reply = _replyTo;
    if (reply != null) setState(() => _replyTo = null);

    await _service.sendTextWithMentions(
      groupId: widget.groupId,
      senderId: widget.currentUserId,
      text: text,
      mentions: mentions,
      participants: _participants,
      replyToText: reply?['text'] as String?,
      replyToSender: reply?['name'] as String?,
    );
  }

  Future<void> _sendSticker(String path) async {
    setState(() => _showPanel = false);
    await _service.sendSticker(
      groupId: widget.groupId,
      senderId: widget.currentUserId,
      stickerPath: path,
      participants: _participants,
    );
  }

  Future<void> _sendPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    // Show the preview first.
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ImagePreviewView(bytes: bytes)),
    );
    if (confirmed != true) return;

    setState(() => _sending = true);
    try {
      await _service.sendImage(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        bytes: bytes,
        participants: _participants,
      );
    } catch (e) {
      _toast('Failed to send photo: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  // NEW: pick a video, upload it to Cloudinary, save it in the group
  Future<void> _sendVideo() async {
    if (_sending) return;
    try {
      // Throws a readable Exception if the video is too large.
      final video = await CloudinaryService.pickVideo();
      if (video == null) return; // cancelled
      if (!mounted) return;

      // Show the preview first; only upload if the user taps Send.
      final confirmed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => VideoPreviewScreen(file: video)),
      );
      if (confirmed != true) return;
      if (!mounted) return;

      setState(() {
        _sending = true;
        _videoProgress = 0;
      });

      final uploaded = await CloudinaryService.uploadVideo(
        video,
        folder: 'chat/${widget.groupId}',
        onProgress: (p) {
          if (mounted) setState(() => _videoProgress = p);
        },
      );
      if (uploaded == null) {
        _toast('Failed to upload video');
        return;
      }

      await _service.sendVideo(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        url: uploaded.url,
        fileName: uploaded.name,
        fileSize: uploaded.size,
        participants: _participants,
      );
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
          _videoProgress = null;
        });
      }
    }
  }

  // NEW: image button -> choose Photo or Video
  void _showMediaSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F1F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTile(
                Icons.photo_rounded,
                'Send a photo',
                'Pick an image from your gallery',
                () {
                  Navigator.pop(ctx);
                  _sendPhoto();
                },
              ),
              const SizedBox(height: 10),
              _sheetTile(
                Icons.videocam_rounded,
                'Send a video',
                'Up to 25 MB and 2 minutes',
                () {
                  Navigator.pop(ctx);
                  _sendVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: pick any file, upload to Cloudinary, save it in the group
  Future<void> _sendFile() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final file = await CloudinaryService.pickAndUploadFile(
        folder: 'chat/${widget.groupId}',
      );
      if (file == null) return; // cancelled or upload failed

      await _service.sendFile(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        url: file.url,
        name: file.name,
        size: file.size,
        participants: _participants,
      );
    } catch (e) {
      _toast('Failed to send file: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // -------------------------------------------------------------- recording

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      _toast('Microphone permission denied');
      return;
    }
    String path = '';
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
    await _recorder.start(
      RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _stopRecording({required bool send}) async {
    _timer?.cancel();
    final path = await _recorder.stop();
    final secs = _seconds;
    if (mounted) setState(() => _recording = false);
    if (!send || path == null || secs < 1) return;

    setState(() => _sending = true);
    try {
      final bytes = await XFile(path).readAsBytes();
      final ext = kIsWeb ? 'webm' : 'm4a';
      final url = await CloudinaryService.uploadBytes(
        bytes,
        'voice_${DateTime.now().millisecondsSinceEpoch}.$ext',
        folder: 'chat/${widget.groupId}',
      );
      if (url == null) throw 'upload failed';
      await _service.sendMedia(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        type: 'audio',
        content: url,
        preview: '🎤 Voice message',
        duration: secs,
        participants: _participants,
      );
    } catch (e) {
      _toast('Failed to send voice: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _togglePanel() {
    if (_showPanel) {
      setState(() => _showPanel = false);
      _focus.requestFocus();
    } else {
      _focus.unfocus();
      setState(() => _showPanel = true);
    }
  }

  // ------------------------------------------------------ group calls (NEW)

  // Everyone in the group except me
  List<ZegoUIKitUser> _callInvitees() => _participants
      .where((id) => id != widget.currentUserId)
      .map((id) => ZegoUIKitUser(id: id, name: _memberNames[id] ?? 'User'))
      .toList();

  Widget _buildCallButton({required bool video}) {
    final icon = video ? Icons.videocam : Icons.call;
    final invitees = _callInvitees();

    // Nobody else in the group -> nothing to call
    if (invitees.isEmpty) {
      return IconButton(
        icon: Icon(icon, color: _iconColor.withValues(alpha: 0.4)),
        onPressed: null,
      );
    }

    return ZegoSendCallInvitationButton(
      isVideoCall: video,
      resourceID: 'zego_call',
      invitees: invitees,
      iconSize: const Size(40, 40),
      buttonSize: const Size(40, 40),
      icon: ButtonIcon(icon: Icon(icon, color: _iconColor)),
      onPressed: (code, message, errors) {
        debugPrint(
          'GROUP ${video ? 'VIDEO' : 'VOICE'} CALL RESULT -> '
          'code: $code, message: $message, errors: $errors',
        );
      },
    );
  }

  void _openInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupInfoView(
          groupId: widget.groupId,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  // ------------------------------------- typing / mute / mentions (NEW)

  void _handleTyping() {
    if (_controller.text.trim().isEmpty) {
      _stopTyping();
      return;
    }
    if (!_iAmTyping) {
      _iAmTyping = true;
      _service.setGroupTyping(widget.groupId, widget.currentUserId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (_iAmTyping) {
      _iAmTyping = false;
      _service.setGroupTyping(widget.groupId, widget.currentUserId, false);
    }
  }

  Future<void> _loadMuted() async {
    try {
      final m = await ChatService().isChatMuted(
        currentUserId: widget.currentUserId,
        chatId: widget.groupId,
      );
      if (mounted) setState(() => _isMuted = m);
    } catch (_) {}
  }

  Future<void> _toggleMute() async {
    final v = !_isMuted;
    setState(() => _isMuted = v);
    try {
      await ChatService().toggleMuteChat(
        currentUserId: widget.currentUserId,
        chatId: widget.groupId,
        isMuted: v,
      );
      _toast(v ? 'Group muted' : 'Group unmuted');
    } catch (e) {
      if (mounted) setState(() => _isMuted = !v);
      _toast('Failed to update mute: $e');
    }
  }

  // loads every member's name once (needed for @mentions and highlighting)
  void _ensureMemberNames() {
    final key = (List<String>.from(_participants)..sort()).join(',');
    if (key == _namesKey) return;
    _namesKey = key;
    Future.wait(
      _participants.map((id) async => MapEntry(id, await _nameOf(id))),
    ).then((entries) {
      if (!mounted) return;
      setState(() {
        for (final e in entries) {
          _memberNames[e.key] = e.value;
        }
      });
    });
  }

  void _updateMention() {
    final text = _controller.text;
    final sel = _controller.selection;
    final cursor = (sel.baseOffset < 0 || sel.baseOffset > text.length)
        ? text.length
        : sel.baseOffset;
    final m = RegExp(
      r'(?:^|\s)@([^\s@]*)$',
    ).firstMatch(text.substring(0, cursor));
    final q = m?.group(1);
    if (q != _mentionQuery) setState(() => _mentionQuery = q);
  }

  void _insertMention(String name) {
    final text = _controller.text;
    final sel = _controller.selection;
    final cursor = (sel.baseOffset < 0 || sel.baseOffset > text.length)
        ? text.length
        : sel.baseOffset;
    final at = text.substring(0, cursor).lastIndexOf('@');
    if (at < 0) return;
    final newText =
        '${text.substring(0, at)}@$name ${text.substring(cursor)}';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: at + name.length + 2),
    );
    setState(() => _mentionQuery = null);
  }

  List<String> _mentionsIn(String text) => _participants
      .where(
        (id) =>
            id != widget.currentUserId &&
            _memberNames[id] != null &&
            text.contains('@${_memberNames[id]}'),
      )
      .toList();

  Widget _buildMentionList() {
    final q = (_mentionQuery ?? '').toLowerCase();
    final people = _participants
        .where(
          (id) =>
              id != widget.currentUserId &&
              _memberNames[id] != null &&
              _memberNames[id]!.toLowerCase().contains(q),
        )
        .take(5)
        .toList();
    if (people.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: people.map((id) {
          final name = _memberNames[id]!;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _insertMention(name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFE0BCC4),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: _plum,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    name,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // under the group name: "members" or "Cassie is typing..."
  Widget _buildSubtitle(Map<String, dynamic> data) {
    final ids = <String>[];
    data.forEach((k, v) {
      if (k.startsWith('typing_') && v == true) {
        final id = k.substring(7);
        if (id != widget.currentUserId && _participants.contains(id)) {
          ids.add(id);
        }
      }
    });
    final members = Text(
      '${_participants.length} members',
      style: GoogleFonts.nunito(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: _muted,
      ),
    );
    if (ids.isEmpty) return members;

    ids.sort();
    final future = _typingFutures.putIfAbsent(ids.join(','), () async {
      final names = await Future.wait(ids.map(_nameOf));
      if (names.length == 1) return '${names[0]} is typing...';
      if (names.length == 2) return '${names[0]} and ${names[1]} are typing...';
      return 'Several people are typing...';
    });
    return FutureBuilder<String>(
      future: future,
      builder: (context, snap) => snap.hasData
          ? Text(
              snap.data!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _plum,
              ),
            )
          : members,
    );
  }

  // ------------------------------------------------------- pin / seen (NEW)

  Future<void> _pinMessage(String id, Map<String, dynamic> m) async {
    final name = await _nameOf((m['senderId'] ?? '') as String);
    try {
      await _service.pinGroupMessage(
        widget.groupId,
        id: id,
        text: _previewOf(m),
        senderName: name,
      );
      _toast('Message pinned');
    } catch (e) {
      _toast('Failed to pin: $e');
    }
  }

  Future<void> _unpin() async {
    try {
      await _service.unpinGroupMessage(widget.groupId);
    } catch (e) {
      _toast('Failed to unpin: $e');
    }
  }

  Widget _buildPinnedBanner(Map<String, dynamic> pin) {
    final text = (pin['text'] ?? '') as String;
    final who = (pin['senderName'] ?? '') as String;

    return Material(
      color: const Color(0xFFEFE3E6),
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                const Icon(Icons.push_pin_rounded, color: _plum, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pinned message',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (who.isNotEmpty)
                  Text(
                    who,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      color: _plum,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(fontSize: 15)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: _plum)),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          child: Row(
            children: [
              const Icon(Icons.push_pin_rounded, color: _plum, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pinned message',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _plum,
                      ),
                    ),
                    Text(
                      who.isEmpty ? text : '$who: $text',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, color: _textDark),
                    ),
                  ],
                ),
              ),
              // Any member can unpin.
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Unpin',
                icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
                onPressed: _unpin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markSeen(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final ids = <String>[];
    for (final d in docs) {
      final m = d.data();
      if (m['type'] == 'system') continue;
      if (m['senderId'] == widget.currentUserId) continue;
      final seen = m['seenBy'];
      if (seen is List && seen.contains(widget.currentUserId)) continue;
      if (_seenRequested.contains(d.id)) continue;
      ids.add(d.id);
    }
    if (ids.isEmpty) return;
    _seenRequested.addAll(ids);
    _service.markGroupSeen(widget.groupId, widget.currentUserId, ids);
  }

  List<String> _seenList(Map<String, dynamic> m) {
    final raw = m['seenBy'];
    if (raw is! List) return [];
    return raw
        .map((e) => e.toString())
        .where((u) => u != widget.currentUserId && _participants.contains(u))
        .toList();
  }

  Widget _buildSeenLabel(String id, Map<String, dynamic> m) {
    final seen = _seenList(m);
    if (seen.isEmpty) return const SizedBox.shrink();
    final others = _participants.length - 1;
    final label = seen.length >= others ? 'Seen by all' : 'Seen by ${seen.length}';
    return GestureDetector(
      onTap: () => _showSeenBy(id, m),
      child: Padding(
        padding: const EdgeInsets.only(top: 3, right: 4),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
      ),
    );
  }

  Widget _personRow(String uid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE0BCC4),
            child: FutureBuilder<String>(
              future: _nameOf(uid),
              builder: (c, s) {
                final n = s.data ?? '';
                return Text(
                  n.isNotEmpty ? n[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _plum,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          FutureBuilder<String>(
            future: _nameOf(uid),
            builder: (c, s) => Text(
              s.data ?? '',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSeenBy(String id, Map<String, dynamic> m) {
    final seen = _seenList(m);
    final notSeen = _participants
        .where((u) => u != widget.currentUserId && !seen.contains(u))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F1F0),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seen by ${seen.length}',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                if (seen.isEmpty)
                  Text(
                    'No one yet',
                    style: GoogleFonts.nunito(color: _muted),
                  )
                else
                  ...seen.map(_personRow),
                if (notSeen.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Not seen yet',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...notSeen.map(_personRow),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(String raw) async {
    final url = raw.startsWith('www.') ? 'https://$raw' : raw;
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _toast('Could not open link');
    } catch (_) {
      _toast('Could not open link');
    }
  }

  // text with tappable links + highlighted @mentions
  Widget _buildMessageText(
    String content,
    Map<String, dynamic> m,
    bool isMine,
    ColorScheme colors,
  ) {
    final base = TextStyle(
      color: isMine ? Colors.white : colors.onSurface,
      fontSize: 15,
    );

    // '@Name' -> is it me?
    final tokens = <String, bool>{};
    final raw = m['mentions'];
    if (raw is List) {
      for (final u in raw) {
        final n = _memberNames[u.toString()];
        if (n != null) tokens['@$n'] = u.toString() == widget.currentUserId;
      }
    }

    const urlPattern = r'(?:https?://|www\.)[^\s]*[^\s.,!?;:)\]]';
    final pattern = RegExp(
      [urlPattern, ...tokens.keys.map(RegExp.escape)].join('|'),
    );

    final matches = pattern.allMatches(content).toList();
    if (matches.isEmpty) return Text(content, style: base);

    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(text: content.substring(last, match.start)));
      }
      final t = match.group(0)!;

      if (tokens.containsKey(t)) {
        final me = tokens[t] == true;
        spans.add(
          TextSpan(
            text: t,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: me
                  ? const Color(0xFF3A2A32)
                  : (isMine ? Colors.white : _plum),
              backgroundColor: me ? const Color(0xFFFFE08A) : null,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: t,
            style: TextStyle(
              decoration: TextDecoration.underline,
              decorationColor: isMine ? Colors.white : _bubbleBlue,
              color: isMine ? Colors.white : _bubbleBlue,
            ),
            recognizer: _linkTaps.putIfAbsent(
              t,
              () => TapGestureRecognizer()..onTap = () => _openLink(t),
            ),
          ),
        );
      }
      last = match.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last)));
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }

  // ------------------------------------------------------- search (NEW)

  void _openSearch() {
    _focus.unfocus();
    setState(() {
      _searching = true;
      _showPanel = false;
    });
  }

  void _closeSearch() {
    _searchCtrl.clear();
    setState(() {
      _searching = false;
      _searchQuery = '';
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      autofocus: true,
      cursorColor: _plum,
      style: GoogleFonts.nunito(fontSize: 16, color: _textDark),
      decoration: InputDecoration(
        hintText: 'Search messages...',
        hintStyle: GoogleFonts.nunito(color: _muted.withValues(alpha: 0.7)),
        border: InputBorder.none,
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
              ),
      ),
      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
    );
  }

  bool _matchesSearch(Map<String, dynamic> m) {
    if (m['isUnsent'] == true) return false;
    final q = _searchQuery;
    final type = (m['type'] ?? 'text') as String;
    final parts = <String>[];
    if (type == 'text' || type == 'poll') {
      parts.add((m['text'] ?? '').toString());
    }
    if (type == 'file') parts.add((m['fileName'] ?? '').toString());
    if (type == 'poll' && m['pollOptions'] is List) {
      parts.addAll((m['pollOptions'] as List).map((e) => e.toString()));
    }
    if (m['replyToText'] != null) parts.add(m['replyToText'].toString());
    return parts.any((p) => p.toLowerCase().contains(q));
  }

  // ------------------------------------------------------- polls (NEW)

  Widget _sheetTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: _plum.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0BCC4).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _plum, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _plum),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F1F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTile(
                Icons.insert_drive_file_rounded,
                'Send a file',
                'PDFs, documents, text files',
                () {
                  Navigator.pop(ctx);
                  _sendFile();
                },
              ),
              const SizedBox(height: 10),
              _sheetTile(
                Icons.poll_rounded,
                'Create a poll',
                'Let the group vote',
                () {
                  Navigator.pop(ctx);
                  _createPoll();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPoll() async {
    final qCtrl = TextEditingController();
    final optCtrls = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
    ];
    final all = <TextEditingController>[qCtrl, ...optCtrls];

    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(color: _muted.withValues(alpha: 0.7)),
      filled: true,
      fillColor: const Color(0xFFE5DFDC),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _plum, width: 1.5),
      ),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          bool valid() {
            final opts = optCtrls
                .map((c) => c.text.trim())
                .where((t) => t.isNotEmpty)
                .toSet();
            return qCtrl.text.trim().isNotEmpty && opts.length >= 2;
          }

          return Dialog(
            backgroundColor: const Color(0xFFEEE8E7),
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE0BCC4,
                            ).withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.poll_rounded,
                            color: _plum,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Create poll',
                          style: GoogleFonts.nunito(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: qCtrl,
                      maxLength: 100,
                      cursorColor: _plum,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setLocal(() {}),
                      decoration: deco('Ask a question...'),
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < optCtrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optCtrls[i],
                                maxLength: 60,
                                cursorColor: _plum,
                                onChanged: (_) => setLocal(() {}),
                                decoration: deco('Option ${i + 1}'),
                              ),
                            ),
                            if (optCtrls.length > 2)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: _danger,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setLocal(() => optCtrls.removeAt(i)),
                              ),
                          ],
                        ),
                      ),
                    if (optCtrls.length < 6)
                      TextButton.icon(
                        onPressed: () => setLocal(() {
                          final c = TextEditingController();
                          optCtrls.add(c);
                          all.add(c);
                        }),
                        icon: const Icon(Icons.add_rounded, color: _plum),
                        label: Text(
                          'Add option',
                          style: GoogleFonts.nunito(
                            color: _plum,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFE5DFDC),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.nunito(
                                color: _textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: valid()
                                  ? _plum
                                  : const Color(0xFFCBBFC3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: !valid()
                                ? null
                                : () {
                                    final seen = <String>{};
                                    final opts = <String>[];
                                    for (final c in optCtrls) {
                                      final t = c.text.trim();
                                      if (t.isNotEmpty && seen.add(t)) {
                                        opts.add(t);
                                      }
                                    }
                                    Navigator.pop(ctx, {
                                      'q': qCtrl.text.trim(),
                                      'options': opts,
                                    });
                                  },
                            child: Text(
                              'Send poll',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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
        },
      ),
    );

    // dispose after the dialog's closing animation
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final c in all) {
        c.dispose();
      }
    });

    if (result == null) return;
    try {
      await _service.sendPoll(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        question: result['q'] as String,
        options: List<String>.from(result['options'] as List),
        participants: _participants,
      );
    } catch (e) {
      _toast('Failed to send poll: $e');
    }
  }

  Widget _buildPoll(
    String id,
    Map<String, dynamic> m,
    bool isMine,
    String time,
  ) {
    final question = (m['text'] ?? '') as String;
    final options = m['pollOptions'] is List
        ? (m['pollOptions'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final votes = m['votes'] is Map
        ? Map<String, dynamic>.from(m['votes'] as Map)
        : <String, dynamic>{};

    final counts = List<int>.filled(options.length, 0);
    votes.forEach((_, v) {
      if (v is num) {
        final i = v.toInt();
        if (i >= 0 && i < counts.length) counts[i]++;
      }
    });
    final total = counts.fold<int>(0, (a, b) => a + b);
    final mine = votes[widget.currentUserId];
    final myIndex = mine is num ? mine.toInt() : null;

    return Container(
      width: 250,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _plum.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_rounded, size: 16, color: _plum),
              const SizedBox(width: 6),
              Text(
                'Poll',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _plum,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _service.votePoll(
                  widget.groupId,
                  id,
                  widget.currentUserId,
                  i,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : counts[i] / total,
                        minHeight: 38,
                        backgroundColor: const Color(0xFFF1EAEC),
                        color: _plum.withValues(alpha: 0.22),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Icon(
                              myIndex == i
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 18,
                              color: _plum,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                options[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: myIndex == i
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _textDark,
                                ),
                              ),
                            ),
                            Text(
                              '${counts[i]}',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _plum,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                total == 1 ? '1 vote' : '$total votes',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
              Text(time, style: const TextStyle(fontSize: 10, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------- block / leave (NEW)
  // Available to every member and admin.

  void _showUserActions(String uid) {
    if (uid.isEmpty || uid == widget.currentUserId) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F1F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: FutureBuilder<String>(
            future: _nameOf(uid),
            builder: (c, snap) {
              final name = snap.data ?? 'this user';
              return _sheetTile(
                Icons.block_rounded,
                'Block $name',
                "You won't see their messages in your groups",
                () async {
                  Navigator.pop(ctx);
                  try {
                    await _service.blockUser(widget.currentUserId, uid);
                    _toast('Blocked $name');
                  } catch (e) {
                    _toast('Failed to block: $e');
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------- message actions (NEW)

  String _previewOf(Map<String, dynamic> m) {
    final type = (m['type'] ?? 'text') as String;
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'video':
        return '🎥 Video';
      case 'audio':
        return '🎤 Voice message';
      case 'sticker':
        return '🙂 Sticker';
      case 'poll':
        return '📊 ${m['text'] ?? 'Poll'}';
      case 'file':
        final n = (m['fileName'] ?? '') as String;
        return '📎 ${n.isEmpty ? 'File' : n}';
      default:
        return (m['text'] ?? '') as String;
    }
  }

  Future<void> _startReply(String id, Map<String, dynamic> m) async {
    final name = await _nameOf((m['senderId'] ?? '') as String);
    if (!mounted) return;
    setState(() => _replyTo = {'id': id, 'text': _previewOf(m), 'name': name});
    _focus.requestFocus();
  }

  void _showMessageOptions(String id, Map<String, dynamic> m) {
    final model = MessageModel.fromMap(m, id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MessageOptionsSheet(
        message: model,
        currentUserId: widget.currentUserId,
        onReactionSelected: (emoji) => _service.toggleReaction(
          widget.groupId,
          id,
          widget.currentUserId,
          emoji,
        ),
        onReply: () => _startReply(id, m),
        onCopy: () {},
        onUnsend: () {},
        onForward: () => _forward(m),
        onDelete: () => _deleteMessage(id, m),
        // Any member can pin / unpin (system messages can't be pinned).
        onPin: m['type'] != 'system'
            ? (id == _pinnedId ? _unpin : () => _pinMessage(id, m))
            : null,
        pinTitle: id == _pinnedId ? 'Unpin message' : 'Pin message',
        onSeenBy: m['senderId'] == widget.currentUserId
            ? () => _showSeenBy(id, m)
            : null,
      ),
    );
  }

  void _forward(Map<String, dynamic> m) {
    final type = (m['type'] ?? 'text') as String;
    final text = (m['text'] ?? '') as String;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => ForwardContactSheet(
        currentUserId: widget.currentUserId,
        onSelectUser: (targetUserId, targetUserName) async {
          await ChatService().sendMessage(
            widget.currentUserId,
            targetUserId,
            text,
            type: type,
            isForwarded: true,
          );
          if (!mounted) return;
          Navigator.pop(sheetCtx);
          _toast('Forwarded to $targetUserName');
        },
      ),
    );
  }

  Future<void> _deleteMessage(String id, Map<String, dynamic> m) async {
    final isMine = m['senderId'] == widget.currentUserId;

    const card = Color(0xFFEEE8E7);
    const field = Color(0xFFE5DFDC);

    Widget optionTile({
      required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap,
    }) {
      return Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.nunito(fontSize: 12, color: _muted),
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
      );
    }

    final choice = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: card,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
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
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete message?',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMine
                    ? 'Choose how you want to remove this message.'
                    : 'This removes the message only for you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: _muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              optionTile(
                icon: Icons.visibility_off_rounded,
                title: 'Delete for me',
                subtitle: 'Others in the group can still see it',
                color: _plum,
                onTap: () => Navigator.pop(ctx, 'me'),
              ),
              if (isMine) ...[
                const SizedBox(height: 10),
                optionTile(
                  icon: Icons.undo_rounded,
                  title: 'Delete for everyone',
                  subtitle: 'Removed for everyone in the group',
                  color: _danger,
                  onTap: () => Navigator.pop(ctx, 'all'),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: field,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.nunito(
                      color: _textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;

    try {
      if (choice == 'all') {
        await _service.unsendGroupMessage(widget.groupId, id);
        if (id == _pinnedId) await _service.unpinGroupMessage(widget.groupId);
      } else {
        await _service.deleteMessageForMe(
          widget.groupId,
          id,
          widget.currentUserId,
        );
      }
    } catch (e) {
      _toast('Failed to delete: $e');
    }
  }

  Widget _buildReplyBanner() {
    final r = _replyTo!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: _plum, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${r['name']}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _plum,
                  ),
                ),
                Text(
                  r['text'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: colors.onSurface),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  // quoted message shown inside a reply bubble
  Widget _buildQuote(Map<String, dynamic> m, bool isMine) {
    final fg = isMine ? Colors.white : _plum;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: fg, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (m['replyToSender'] ?? '') as String,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          Text(
            (m['replyToText'] ?? '') as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: isMine ? Colors.white70 : _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // emoji reactions under a bubble
  Widget _buildReactions(Map<String, dynamic> m) {
    final raw = m['reactions'];
    if (raw is! Map || raw.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (final e in raw.values) {
      counts[e.toString()] = (counts[e.toString()] ?? 0) + 1;
    }
    final label = counts.entries
        .map((e) => e.value > 1 ? '${e.key} ${e.value}' : e.key)
        .join('  ');
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _plum.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.watchGroup(widget.groupId),
      builder: (context, groupSnap) {
        final data = groupSnap.data?.data();
        if (groupSnap.connectionState == ConnectionState.waiting &&
            data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _plum)),
          );
        }
        if (data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Group not found')),
          );
        }

        _participants = List<String>.from(data['participants'] ?? []);
        final pinned = data['pinnedMessage'] is Map
            ? Map<String, dynamic>.from(data['pinnedMessage'] as Map)
            : null;
        _pinnedId = pinned?['id'] as String?;
        _ensureMemberNames();
        final name = (data['groupName'] ?? 'Group') as String;
        final photo = data['groupPhotoUrl'] as String?;

        if (!_participants.contains(widget.currentUserId)) {
          return Scaffold(
            appBar: AppBar(title: Text(name)),
            body: const Center(child: Text('You are no longer in this group')),
          );
        }

        // Clear the unread badge while the chat is open.
        final unread =
            (data['unreadCount_${widget.currentUserId}'] ?? 0) as int;
        if (unread > 0) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _service.markRead(widget.groupId, widget.currentUserId),
          );
        }

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            backgroundColor: colors.surface,
            foregroundColor: _textDark,
            elevation: 0,
            titleSpacing: 0,
            leading: _searching
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _closeSearch,
                  )
                : null,
            title: _searching
                ? _buildSearchField()
                : InkWell(
              onTap: _openInfo,
              child: Row(
                children: [
                  GroupAvatar(name: name, photoUrl: photo, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: _textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        _buildSubtitle(data),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: _searching
                ? const <Widget>[]
                : [
              _buildCallButton(video: false),
              _buildCallButton(video: true),
              PopupMenuButton<String>(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert, color: _iconColor),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (v) {
                  if (v == 'search') _openSearch();
                  if (v == 'mute') _toggleMute();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'search',
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded, color: _plum),
                        const SizedBox(width: 10),
                        Text('Search', style: GoogleFonts.nunito()),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'mute',
                    child: Row(
                      children: [
                        Icon(
                          _isMuted
                              ? Icons.notifications_off_rounded
                              : Icons.notifications_none_rounded,
                          color: _plum,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isMuted ? 'Unmute' : 'Mute',
                          style: GoogleFonts.nunito(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.info, color: _iconColor),
                onPressed: _openInfo,
              ),
            ],
          ),
          body: Column(
            children: [
              if (pinned != null && !_searching) _buildPinnedBanner(pinned),
              Expanded(child: _buildMessages()),
              if (_sending)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: _plum,
                  value: _videoProgress, // null = indeterminate
                ),
              if (!_searching) ...[
                if (_mentionQuery != null) _buildMentionList(),
                if (_replyTo != null) _buildReplyBanner(),
                _buildInputBar(),
                if (_showPanel) _buildPanel(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchMessages(widget.groupId),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? []).where((d) {
          final del = d.data()['deletedFor'];
          if (d.data()['isUnsent'] == true) return false; // old placeholders
          if (_blocked.contains(d.data()['senderId'])) return false; // blocked
          return !(del is List && del.contains(widget.currentUserId));
        }).toList();
        _markSeen(docs);
        final shown = _searchQuery.isEmpty
            ? docs
            : docs.where((d) => _matchesSearch(d.data())).toList();
        if (shown.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isEmpty ? 'No messages yet' : 'No results found',
              style: GoogleFonts.nunito(color: _muted),
            ),
          );
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: shown.length,
          itemBuilder: (context, i) =>
              _buildMessage(shown[i].id, shown[i].data()),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: _recording
            ? _buildRecordingRow()
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.add_photo_alternate,
                        color: _inputIcon,
                        size: 22,
                      ),
                      tooltip: 'Photo or video',
                      onPressed: _sending ? null : _showMediaSheet,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.attach_file,
                        color: _inputIcon,
                        size: 22,
                      ),
                      tooltip: 'Send a file',
                      onPressed: _sending ? null : _showAttachSheet,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 4,
                        cursorColor: _plum,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF424242),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintMaxLines: 1,
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8A8587),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          suffixIcon: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              _showPanel
                                  ? Icons.keyboard
                                  : Icons.emoji_emotions_outlined,
                              color: _inputIcon,
                              size: 24,
                            ),
                            onPressed: _togglePanel,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _plum,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _hasText ? Icons.send : Icons.mic,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _hasText ? _sendText : _startRecording,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRecordingRow() {
    final t =
        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: _danger),
          onPressed: () => _stopRecording(send: false),
        ),
        const Icon(Icons.graphic_eq, color: _plum),
        const SizedBox(width: 8),
        Text(
          'Recording $t',
          style: GoogleFonts.nunito(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 22,
          backgroundColor: _plum,
          child: IconButton(
            icon: const Icon(Icons.stop, color: Colors.white, size: 22),
            onPressed: () => _stopRecording(send: true),
          ),
        ),
      ],
    );
  }

  /// Emoji tab + Sticker tab, like the 1-to-1 chat.
  Widget _buildPanel() {
    return SizedBox(
      height: 280,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: _plum,
              unselectedLabelColor: _inputIcon,
              indicatorColor: _plum,
              tabs: [
                Tab(icon: Icon(Icons.emoji_emotions_outlined)),
                Tab(icon: Icon(Icons.sticky_note_2_outlined)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  EmojiPicker(
                    textEditingController: _controller,
                    config: const Config(height: 232),
                  ),
                  _stickers.isEmpty
                      ? Center(
                          child: Text(
                            'No stickers found',
                            style: GoogleFonts.nunito(color: _muted),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                              ),
                          itemCount: _stickers.length,
                          itemBuilder: (context, i) => InkWell(
                            onTap: () => _sendSticker(_stickers[i]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                _stickers[i],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- messages

  String _formatTime(dynamic ts) {
    if (ts is Timestamp) return DateFormat('h:mm a').format(ts.toDate());
    return '';
  }

  void _openImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
      ),
    );
  }

  // NEW: first-frame thumbnail of a Cloudinary video (url .mp4 -> .jpg)
  String _videoThumb(String url) {
    final dot = url.lastIndexOf('.');
    if (dot < 0) return url;
    var out = '${url.substring(0, dot)}.jpg';
    out = out.replaceFirst(
      '/video/upload/',
      '/video/upload/so_0,w_440,c_limit/',
    );
    return out;
  }

  // NEW: video bubble (thumbnail + play button, tap to play)
  Widget _buildVideo(Map<String, dynamic> m, String time) {
    final url = ((m['videoUrl'] ?? m['fileUrl'] ?? m['text'] ?? '') as String);
    final size = _formatSize(((m['fileSize'] ?? 0) as num).toInt());

    return GestureDetector(
      onTap: () {
        if (url.isEmpty) return;
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 220,
          height: 160,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: Colors.black),
              Image.network(
                _videoThumb(url),
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => const SizedBox.shrink(),
              ),
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
              ),
              if (size.isNotEmpty)
                Positioned(
                  left: 8,
                  bottom: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      size,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              Positioned(
                right: 8,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: readable size like "1.5 KB"
  String _formatSize(int b) {
    if (b <= 0) return '';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // NEW: file name from a URL, used when an old message has no fileName
  String _nameFromUrl(String url) {
    try {
      return Uri.decodeComponent(Uri.parse(url).pathSegments.last);
    } catch (_) {
      return 'File';
    }
  }

  // NEW: look up a user's display name (cached, so each user is read once)
  final Map<String, Future<String>> _nameFutures = {};
  final Map<String, Future<String>> _systemFutures = {};

  Future<String> _nameOf(String uid) {
    return _nameFutures.putIfAbsent(uid, () async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final n = doc.data()?['name']?.toString().trim();
        if (n != null && n.isNotEmpty) return n;
      } catch (_) {}
      return 'User';
    });
  }

  // NEW: replaces any user IDs inside a system message with real names
  Future<String> _resolveSystemText(String content) {
    return _systemFutures.putIfAbsent(content, () async {
      final ids = RegExp(r'[A-Za-z0-9]{20,}')
          .allMatches(content)
          .map((m) => m.group(0)!)
          .toSet()
          .toList();
      var out = content;
      for (final id in ids) {
        out = out.replaceAll(id, await _nameOf(id));
      }
      return out;
    });
  }

  Widget _buildMessage(String id, Map<String, dynamic> m) {
    final colors = Theme.of(context).colorScheme;
    final type = (m['type'] ?? 'text') as String;
    final content = (m['text'] ?? '') as String;
    final sender = (m['senderId'] ?? '') as String;
    final time = _formatTime(m['timestamp']);

    if (type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: FutureBuilder<String>(
            future: _resolveSystemText(content),
            builder: (context, snap) => Text(
              snap.data ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: _muted, fontSize: 12.5),
            ),
          ),
        ),
      );
    }

    final isMine = sender == widget.currentUserId;
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    final isUnsent = m['isUnsent'] == true;

    Widget body;
    if (isUnsent) {
      body = Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: isMine ? _bubbleBlue.withValues(alpha: 0.45) : _incomingBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 15,
              color: isMine ? Colors.white : _muted,
            ),
            const SizedBox(width: 6),
            Text(
              'This message was unsent',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: isMine ? Colors.white : _muted,
              ),
            ),
          ],
        ),
      );
    } else if (type == 'image') {
      body = GestureDetector(
        onTap: () => _openImage(content),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Image.network(
                content,
                width: 220,
                fit: BoxFit.cover,
                loadingBuilder: (c, child, p) => p == null
                    ? child
                    : Container(
                        width: 220,
                        height: 220,
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(color: _plum),
                        ),
                      ),
                errorBuilder: (c, e, s) => Container(
                  width: 220,
                  height: 120,
                  color: Colors.black12,
                  child: const Icon(Icons.broken_image, color: _muted),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (type == 'video') {
      // NEW: video bubble
      body = _buildVideo(m, time);
    } else if (type == 'sticker') {
      body = Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Image.asset(
            content,
            width: 130,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.broken_image, color: _muted),
          ),
          Text(time, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      );
    } else if (type == 'audio') {
      body = Container(
        width: 230,
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMine ? _bubbleBlue : _incomingBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: VoiceBubble(
          url: content,
          seconds: (m['duration'] ?? 0) as int,
          time: time,
          isMine: isMine,
        ),
      );
    } else if (type == 'poll') {
      body = _buildPoll(id, m, isMine, time);
    } else if (type == 'file') {
      // NEW: file bubble
      final textColor = isMine ? Colors.white : colors.onSurface;
      final url = ((m['fileUrl'] ?? content) as String);
      final fileName = ((m['fileName'] as String?)?.isNotEmpty ?? false)
          ? m['fileName'] as String
          : _nameFromUrl(url);
      final size = _formatSize(((m['fileSize'] ?? 0) as num).toInt());

      body = InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (url.isEmpty) return;
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          decoration: BoxDecoration(
            color: isMine ? _fileColor : _incomingBubble,
            borderRadius: BorderRadius.circular(18),
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file, color: textColor, size: 32),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (size.isNotEmpty)
                            Text(
                              size,
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
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isMine ? Colors.white70 : colors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      body = Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMine ? _bubbleBlue : _incomingBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m['replyToText'] != null) _buildQuote(m, isMine),
              _buildMessageText(content, m, isMine, colors),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  time,
                  style: TextStyle(
                    color: isMine ? Colors.white70 : colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 2),
                child: GestureDetector(
                  onTap: () => _showUserActions(sender),
                  child: FutureBuilder<String>(
                    future: _nameOf(sender),
                    builder: (context, snap) => Text(
                      snap.data ?? '',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _plum,
                      ),
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onLongPress: isUnsent ? null : () => _showMessageOptions(id, m),
              child: body,
            ),
            _buildReactions(m),
            if (isMine && !isUnsent) _buildSeenLabel(id, m),
          ],
        ),
      ),
    );
  }
=======
// lib/chat/views/group_chat_view.dart
import 'dart:async';
import 'package:edunest_app/features/chat/views/voice_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'; // NEW (tappable links)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart'; // NEW
import '../services/cloudinary_service.dart';
import '../services/group_service.dart';
import '../services/chat_service.dart'; // NEW (forward)
import '../models/message_model.dart'; // NEW
import '../widgets/message_options.dart'; // NEW
import '../widgets/forward_contact_sheet.dart'; // NEW
import '../widgets/group_avatar.dart';
import 'group_info_view.dart';
import 'image_preview_view.dart';

class GroupChatView extends StatefulWidget {
  final String groupId;
  final String currentUserId;

  const GroupChatView({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  @override
  State<GroupChatView> createState() => _GroupChatViewState();
}

class _GroupChatViewState extends State<GroupChatView> {
  // 🎨 Screen colors (edit here to restyle the whole group chat)
  static const _plum = Color(0xFF6B4A5B); // send button, accents
  static const _bubbleBlue = Color(0xFF2962FF); // sent message bubbles
  static const _fileColor = _bubbleBlue; // sent FILE bubble (change this one line)
  static const _incomingBubble = Color(0xFFF3EFF0); // received message bubbles
  static const _textDark = Color(0xFF3A2A32); // dark plum-brown text
  static const _muted = Color(0xFF7A6670); // muted text
  static const _iconColor = Color.fromARGB(255, 140, 90, 90); // app-bar icons
  static const _inputIcon = Color(0xFF9A7B86); // attach / emoji icons
  static const _danger = Color(0xFFC2674B); // cancel recording

  final GroupService _service = GroupService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final AudioRecorder _recorder = AudioRecorder();

  List<String> _participants = [];
  List<String> _stickers = [];
  bool _showPanel = false; // emoji / sticker panel
  bool _sending = false;
  bool _hasText = false;
  bool _recording = false;
  int _seconds = 0;
  Timer? _timer;
  Map<String, dynamic>? _replyTo; // NEW: message I'm replying to

  // NEW: typing / pin / mentions / mute / seen
  Timer? _typingTimer;
  bool _iAmTyping = false;
  String? _pinnedId;
  Set<String> _blocked = {}; // users I blocked
  StreamSubscription<List<String>>? _blockSub;
  final Map<String, String> _memberNames = {};
  String _namesKey = '';
  String? _mentionQuery; // null = no @ suggestions
  bool _isMuted = false;
  final Set<String> _seenRequested = {};
  final Map<String, Future<String>> _typingFutures = {};
  final Map<String, TapGestureRecognizer> _linkTaps = {};

  // NEW: search
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStickers();
    _loadMuted();
    _blockSub = _service.watchBlocked(widget.currentUserId).listen((ids) {
      if (mounted) setState(() => _blocked = ids.toSet());
    });
    _focus.addListener(() {
      if (_focus.hasFocus && _showPanel) setState(() => _showPanel = false);
    });
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
      _handleTyping();
      _updateMention();
    });
  }

  @override
  void dispose() {
    _blockSub?.cancel();
    for (final t in _linkTaps.values) {
      t.dispose();
    }
    _typingTimer?.cancel();
    if (_iAmTyping) {
      _service.setGroupTyping(widget.groupId, widget.currentUserId, false);
    }
    _timer?.cancel();
    _recorder.dispose();
    _controller.dispose();
    _searchCtrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadStickers() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final list =
          manifest
              .listAssets()
              .where((p) => p.startsWith('assets/stickers/'))
              .toList()
            ..sort();
      if (mounted) setState(() => _stickers = list);
    } catch (_) {}
  }

  // ---------------------------------------------------------------- sending

  Future<void> _sendText() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final mentions = _mentionsIn(text);
    _controller.clear();
    _stopTyping();

    final reply = _replyTo;
    if (reply != null) setState(() => _replyTo = null);

    await _service.sendTextWithMentions(
      groupId: widget.groupId,
      senderId: widget.currentUserId,
      text: text,
      mentions: mentions,
      participants: _participants,
      replyToText: reply?['text'] as String?,
      replyToSender: reply?['name'] as String?,
    );
  }

  Future<void> _sendSticker(String path) async {
    setState(() => _showPanel = false);
    await _service.sendSticker(
      groupId: widget.groupId,
      senderId: widget.currentUserId,
      stickerPath: path,
      participants: _participants,
    );
  }

  Future<void> _sendPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      imageQuality: 80,
    );
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    if (!mounted) return;

    // Show the preview first.
    final confirmed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ImagePreviewView(bytes: bytes)),
    );
    if (confirmed != true) return;

    setState(() => _sending = true);
    try {
      await _service.sendImage(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        bytes: bytes,
        participants: _participants,
      );
    } catch (e) {
      _toast('Failed to send photo: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  // NEW: pick any file, upload to Cloudinary, save it in the group
  Future<void> _sendFile() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      final file = await CloudinaryService.pickAndUploadFile(
        folder: 'chat/${widget.groupId}',
      );
      if (file == null) return; // cancelled or upload failed

      await _service.sendFile(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        url: file.url,
        name: file.name,
        size: file.size,
        participants: _participants,
      );
    } catch (e) {
      _toast('Failed to send file: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  // -------------------------------------------------------------- recording

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      _toast('Microphone permission denied');
      return;
    }
    String path = '';
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
    await _recorder.start(
      RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _stopRecording({required bool send}) async {
    _timer?.cancel();
    final path = await _recorder.stop();
    final secs = _seconds;
    if (mounted) setState(() => _recording = false);
    if (!send || path == null || secs < 1) return;

    setState(() => _sending = true);
    try {
      final bytes = await XFile(path).readAsBytes();
      final ext = kIsWeb ? 'webm' : 'm4a';
      final url = await CloudinaryService.uploadBytes(
        bytes,
        'voice_${DateTime.now().millisecondsSinceEpoch}.$ext',
        folder: 'chat/${widget.groupId}',
      );
      if (url == null) throw 'upload failed';
      await _service.sendMedia(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        type: 'audio',
        content: url,
        preview: '🎤 Voice message',
        duration: secs,
        participants: _participants,
      );
    } catch (e) {
      _toast('Failed to send voice: $e');
    }
    if (mounted) setState(() => _sending = false);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _togglePanel() {
    if (_showPanel) {
      setState(() => _showPanel = false);
      _focus.requestFocus();
    } else {
      _focus.unfocus();
      setState(() => _showPanel = true);
    }
  }

  void _openInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupInfoView(
          groupId: widget.groupId,
          currentUserId: widget.currentUserId,
        ),
      ),
    );
  }

  // ------------------------------------- typing / mute / mentions (NEW)

  void _handleTyping() {
    if (_controller.text.trim().isEmpty) {
      _stopTyping();
      return;
    }
    if (!_iAmTyping) {
      _iAmTyping = true;
      _service.setGroupTyping(widget.groupId, widget.currentUserId, true);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), _stopTyping);
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    if (_iAmTyping) {
      _iAmTyping = false;
      _service.setGroupTyping(widget.groupId, widget.currentUserId, false);
    }
  }

  Future<void> _loadMuted() async {
    try {
      final m = await ChatService().isChatMuted(
        currentUserId: widget.currentUserId,
        chatId: widget.groupId,
      );
      if (mounted) setState(() => _isMuted = m);
    } catch (_) {}
  }

  Future<void> _toggleMute() async {
    final v = !_isMuted;
    setState(() => _isMuted = v);
    try {
      await ChatService().toggleMuteChat(
        currentUserId: widget.currentUserId,
        chatId: widget.groupId,
        isMuted: v,
      );
      _toast(v ? 'Group muted' : 'Group unmuted');
    } catch (e) {
      if (mounted) setState(() => _isMuted = !v);
      _toast('Failed to update mute: $e');
    }
  }

  // loads every member's name once (needed for @mentions and highlighting)
  void _ensureMemberNames() {
    final key = (List<String>.from(_participants)..sort()).join(',');
    if (key == _namesKey) return;
    _namesKey = key;
    Future.wait(
      _participants.map((id) async => MapEntry(id, await _nameOf(id))),
    ).then((entries) {
      if (!mounted) return;
      setState(() {
        for (final e in entries) {
          _memberNames[e.key] = e.value;
        }
      });
    });
  }

  void _updateMention() {
    final text = _controller.text;
    final sel = _controller.selection;
    final cursor = (sel.baseOffset < 0 || sel.baseOffset > text.length)
        ? text.length
        : sel.baseOffset;
    final m = RegExp(
      r'(?:^|\s)@([^\s@]*)$',
    ).firstMatch(text.substring(0, cursor));
    final q = m?.group(1);
    if (q != _mentionQuery) setState(() => _mentionQuery = q);
  }

  void _insertMention(String name) {
    final text = _controller.text;
    final sel = _controller.selection;
    final cursor = (sel.baseOffset < 0 || sel.baseOffset > text.length)
        ? text.length
        : sel.baseOffset;
    final at = text.substring(0, cursor).lastIndexOf('@');
    if (at < 0) return;
    final newText =
        '${text.substring(0, at)}@$name ${text.substring(cursor)}';
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: at + name.length + 2),
    );
    setState(() => _mentionQuery = null);
  }

  List<String> _mentionsIn(String text) => _participants
      .where(
        (id) =>
            id != widget.currentUserId &&
            _memberNames[id] != null &&
            text.contains('@${_memberNames[id]}'),
      )
      .toList();

  Widget _buildMentionList() {
    final q = (_mentionQuery ?? '').toLowerCase();
    final people = _participants
        .where(
          (id) =>
              id != widget.currentUserId &&
              _memberNames[id] != null &&
              _memberNames[id]!.toLowerCase().contains(q),
        )
        .take(5)
        .toList();
    if (people.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: people.map((id) {
          final name = _memberNames[id]!;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _insertMention(name),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: const Color(0xFFE0BCC4),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: _plum,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    name,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // under the group name: "members" or "Cassie is typing..."
  Widget _buildSubtitle(Map<String, dynamic> data) {
    final ids = <String>[];
    data.forEach((k, v) {
      if (k.startsWith('typing_') && v == true) {
        final id = k.substring(7);
        if (id != widget.currentUserId && _participants.contains(id)) {
          ids.add(id);
        }
      }
    });
    final members = Text(
      '${_participants.length} members',
      style: GoogleFonts.nunito(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: _muted,
      ),
    );
    if (ids.isEmpty) return members;

    ids.sort();
    final future = _typingFutures.putIfAbsent(ids.join(','), () async {
      final names = await Future.wait(ids.map(_nameOf));
      if (names.length == 1) return '${names[0]} is typing...';
      if (names.length == 2) return '${names[0]} and ${names[1]} are typing...';
      return 'Several people are typing...';
    });
    return FutureBuilder<String>(
      future: future,
      builder: (context, snap) => snap.hasData
          ? Text(
              snap.data!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _plum,
              ),
            )
          : members,
    );
  }

  // ------------------------------------------------------- pin / seen (NEW)

  Future<void> _pinMessage(String id, Map<String, dynamic> m) async {
    final name = await _nameOf((m['senderId'] ?? '') as String);
    try {
      await _service.pinGroupMessage(
        widget.groupId,
        id: id,
        text: _previewOf(m),
        senderName: name,
      );
      _toast('Message pinned');
    } catch (e) {
      _toast('Failed to pin: $e');
    }
  }

  Future<void> _unpin() async {
    try {
      await _service.unpinGroupMessage(widget.groupId);
    } catch (e) {
      _toast('Failed to unpin: $e');
    }
  }

  Widget _buildPinnedBanner(Map<String, dynamic> pin) {
    final text = (pin['text'] ?? '') as String;
    final who = (pin['senderName'] ?? '') as String;

    return Material(
      color: const Color(0xFFEFE3E6),
      child: InkWell(
        onTap: () => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                const Icon(Icons.push_pin_rounded, color: _plum, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Pinned message',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (who.isNotEmpty)
                  Text(
                    who,
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      color: _plum,
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(text, style: const TextStyle(fontSize: 15)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close', style: TextStyle(color: _plum)),
              ),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
          child: Row(
            children: [
              const Icon(Icons.push_pin_rounded, color: _plum, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pinned message',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _plum,
                      ),
                    ),
                    Text(
                      who.isEmpty ? text : '$who: $text',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.5, color: _textDark),
                    ),
                  ],
                ),
              ),
              // Any member can unpin.
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Unpin',
                icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
                onPressed: _unpin,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markSeen(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final ids = <String>[];
    for (final d in docs) {
      final m = d.data();
      if (m['type'] == 'system') continue;
      if (m['senderId'] == widget.currentUserId) continue;
      final seen = m['seenBy'];
      if (seen is List && seen.contains(widget.currentUserId)) continue;
      if (_seenRequested.contains(d.id)) continue;
      ids.add(d.id);
    }
    if (ids.isEmpty) return;
    _seenRequested.addAll(ids);
    _service.markGroupSeen(widget.groupId, widget.currentUserId, ids);
  }

  List<String> _seenList(Map<String, dynamic> m) {
    final raw = m['seenBy'];
    if (raw is! List) return [];
    return raw
        .map((e) => e.toString())
        .where((u) => u != widget.currentUserId && _participants.contains(u))
        .toList();
  }

  Widget _buildSeenLabel(String id, Map<String, dynamic> m) {
    final seen = _seenList(m);
    if (seen.isEmpty) return const SizedBox.shrink();
    final others = _participants.length - 1;
    final label = seen.length >= others ? 'Seen by all' : 'Seen by ${seen.length}';
    return GestureDetector(
      onTap: () => _showSeenBy(id, m),
      child: Padding(
        padding: const EdgeInsets.only(top: 3, right: 4),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: _muted,
          ),
        ),
      ),
    );
  }

  Widget _personRow(String uid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFE0BCC4),
            child: FutureBuilder<String>(
              future: _nameOf(uid),
              builder: (c, s) {
                final n = s.data ?? '';
                return Text(
                  n.isNotEmpty ? n[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _plum,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          FutureBuilder<String>(
            future: _nameOf(uid),
            builder: (c, s) => Text(
              s.data ?? '',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSeenBy(String id, Map<String, dynamic> m) {
    final seen = _seenList(m);
    final notSeen = _participants
        .where((u) => u != widget.currentUserId && !seen.contains(u))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F1F0),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seen by ${seen.length}',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 8),
                if (seen.isEmpty)
                  Text(
                    'No one yet',
                    style: GoogleFonts.nunito(color: _muted),
                  )
                else
                  ...seen.map(_personRow),
                if (notSeen.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Not seen yet',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...notSeen.map(_personRow),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(String raw) async {
    final url = raw.startsWith('www.') ? 'https://$raw' : raw;
    try {
      final ok = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) _toast('Could not open link');
    } catch (_) {
      _toast('Could not open link');
    }
  }

  // text with tappable links + highlighted @mentions
  Widget _buildMessageText(
    String content,
    Map<String, dynamic> m,
    bool isMine,
    ColorScheme colors,
  ) {
    final base = TextStyle(
      color: isMine ? Colors.white : colors.onSurface,
      fontSize: 15,
    );

    // '@Name' -> is it me?
    final tokens = <String, bool>{};
    final raw = m['mentions'];
    if (raw is List) {
      for (final u in raw) {
        final n = _memberNames[u.toString()];
        if (n != null) tokens['@$n'] = u.toString() == widget.currentUserId;
      }
    }

    const urlPattern = r'(?:https?://|www\.)[^\s]*[^\s.,!?;:)\]]';
    final pattern = RegExp(
      [urlPattern, ...tokens.keys.map(RegExp.escape)].join('|'),
    );

    final matches = pattern.allMatches(content).toList();
    if (matches.isEmpty) return Text(content, style: base);

    final spans = <InlineSpan>[];
    var last = 0;
    for (final match in matches) {
      if (match.start > last) {
        spans.add(TextSpan(text: content.substring(last, match.start)));
      }
      final t = match.group(0)!;

      if (tokens.containsKey(t)) {
        final me = tokens[t] == true;
        spans.add(
          TextSpan(
            text: t,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: me
                  ? const Color(0xFF3A2A32)
                  : (isMine ? Colors.white : _plum),
              backgroundColor: me ? const Color(0xFFFFE08A) : null,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: t,
            style: TextStyle(
              decoration: TextDecoration.underline,
              decorationColor: isMine ? Colors.white : _bubbleBlue,
              color: isMine ? Colors.white : _bubbleBlue,
            ),
            recognizer: _linkTaps.putIfAbsent(
              t,
              () => TapGestureRecognizer()..onTap = () => _openLink(t),
            ),
          ),
        );
      }
      last = match.end;
    }
    if (last < content.length) {
      spans.add(TextSpan(text: content.substring(last)));
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }

  // ------------------------------------------------------- search (NEW)

  void _openSearch() {
    _focus.unfocus();
    setState(() {
      _searching = true;
      _showPanel = false;
    });
  }

  void _closeSearch() {
    _searchCtrl.clear();
    setState(() {
      _searching = false;
      _searchQuery = '';
    });
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchCtrl,
      autofocus: true,
      cursorColor: _plum,
      style: GoogleFonts.nunito(fontSize: 16, color: _textDark),
      decoration: InputDecoration(
        hintText: 'Search messages...',
        hintStyle: GoogleFonts.nunito(color: _muted.withValues(alpha: 0.7)),
        border: InputBorder.none,
        suffixIcon: _searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = '');
                },
              ),
      ),
      onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
    );
  }

  bool _matchesSearch(Map<String, dynamic> m) {
    if (m['isUnsent'] == true) return false;
    final q = _searchQuery;
    final type = (m['type'] ?? 'text') as String;
    final parts = <String>[];
    if (type == 'text' || type == 'poll') {
      parts.add((m['text'] ?? '').toString());
    }
    if (type == 'file') parts.add((m['fileName'] ?? '').toString());
    if (type == 'poll' && m['pollOptions'] is List) {
      parts.addAll((m['pollOptions'] as List).map((e) => e.toString()));
    }
    if (m['replyToText'] != null) parts.add(m['replyToText'].toString());
    return parts.any((p) => p.toLowerCase().contains(q));
  }

  // ------------------------------------------------------- polls (NEW)

  Widget _sheetTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Material(
      color: _plum.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0BCC4).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _plum, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _textDark,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.nunito(fontSize: 12, color: _muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _plum),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F1F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTile(
                Icons.insert_drive_file_rounded,
                'Send a file',
                'PDFs, documents, text files',
                () {
                  Navigator.pop(ctx);
                  _sendFile();
                },
              ),
              const SizedBox(height: 10),
              _sheetTile(
                Icons.poll_rounded,
                'Create a poll',
                'Let the group vote',
                () {
                  Navigator.pop(ctx);
                  _createPoll();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPoll() async {
    final qCtrl = TextEditingController();
    final optCtrls = <TextEditingController>[
      TextEditingController(),
      TextEditingController(),
    ];
    final all = <TextEditingController>[qCtrl, ...optCtrls];

    InputDecoration deco(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.nunito(color: _muted.withValues(alpha: 0.7)),
      filled: true,
      fillColor: const Color(0xFFE5DFDC),
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _plum, width: 1.5),
      ),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          bool valid() {
            final opts = optCtrls
                .map((c) => c.text.trim())
                .where((t) => t.isNotEmpty)
                .toSet();
            return qCtrl.text.trim().isNotEmpty && opts.length >= 2;
          }

          return Dialog(
            backgroundColor: const Color(0xFFEEE8E7),
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFE0BCC4,
                            ).withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.poll_rounded,
                            color: _plum,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Create poll',
                          style: GoogleFonts.nunito(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: qCtrl,
                      maxLength: 100,
                      cursorColor: _plum,
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setLocal(() {}),
                      decoration: deco('Ask a question...'),
                    ),
                    const SizedBox(height: 12),
                    for (int i = 0; i < optCtrls.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: optCtrls[i],
                                maxLength: 60,
                                cursorColor: _plum,
                                onChanged: (_) => setLocal(() {}),
                                decoration: deco('Option ${i + 1}'),
                              ),
                            ),
                            if (optCtrls.length > 2)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: _danger,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setLocal(() => optCtrls.removeAt(i)),
                              ),
                          ],
                        ),
                      ),
                    if (optCtrls.length < 6)
                      TextButton.icon(
                        onPressed: () => setLocal(() {
                          final c = TextEditingController();
                          optCtrls.add(c);
                          all.add(c);
                        }),
                        icon: const Icon(Icons.add_rounded, color: _plum),
                        label: Text(
                          'Add option',
                          style: GoogleFonts.nunito(
                            color: _plum,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFE5DFDC),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.nunito(
                                color: _textDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: valid()
                                  ? _plum
                                  : const Color(0xFFCBBFC3),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: !valid()
                                ? null
                                : () {
                                    final seen = <String>{};
                                    final opts = <String>[];
                                    for (final c in optCtrls) {
                                      final t = c.text.trim();
                                      if (t.isNotEmpty && seen.add(t)) {
                                        opts.add(t);
                                      }
                                    }
                                    Navigator.pop(ctx, {
                                      'q': qCtrl.text.trim(),
                                      'options': opts,
                                    });
                                  },
                            child: Text(
                              'Send poll',
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
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
        },
      ),
    );

    // dispose after the dialog's closing animation
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final c in all) {
        c.dispose();
      }
    });

    if (result == null) return;
    try {
      await _service.sendPoll(
        groupId: widget.groupId,
        senderId: widget.currentUserId,
        question: result['q'] as String,
        options: List<String>.from(result['options'] as List),
        participants: _participants,
      );
    } catch (e) {
      _toast('Failed to send poll: $e');
    }
  }

  Widget _buildPoll(
    String id,
    Map<String, dynamic> m,
    bool isMine,
    String time,
  ) {
    final question = (m['text'] ?? '') as String;
    final options = m['pollOptions'] is List
        ? (m['pollOptions'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final votes = m['votes'] is Map
        ? Map<String, dynamic>.from(m['votes'] as Map)
        : <String, dynamic>{};

    final counts = List<int>.filled(options.length, 0);
    votes.forEach((_, v) {
      if (v is num) {
        final i = v.toInt();
        if (i >= 0 && i < counts.length) counts[i]++;
      }
    });
    final total = counts.fold<int>(0, (a, b) => a + b);
    final mine = votes[widget.currentUserId];
    final myIndex = mine is num ? mine.toInt() : null;

    return Container(
      width: 250,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _plum.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.poll_rounded, size: 16, color: _plum),
              const SizedBox(width: 6),
              Text(
                'Poll',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _plum,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            question,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _service.votePoll(
                  widget.groupId,
                  id,
                  widget.currentUserId,
                  i,
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : counts[i] / total,
                        minHeight: 38,
                        backgroundColor: const Color(0xFFF1EAEC),
                        color: _plum.withValues(alpha: 0.22),
                      ),
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Icon(
                              myIndex == i
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 18,
                              color: _plum,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                options[i],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: myIndex == i
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: _textDark,
                                ),
                              ),
                            ),
                            Text(
                              '${counts[i]}',
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _plum,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                total == 1 ? '1 vote' : '$total votes',
                style: const TextStyle(fontSize: 11, color: _muted),
              ),
              Text(time, style: const TextStyle(fontSize: 10, color: _muted)),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------- block / leave (NEW)
  // Available to every member and admin.

  void _showUserActions(String uid) {
    if (uid.isEmpty || uid == widget.currentUserId) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF7F1F0),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: FutureBuilder<String>(
            future: _nameOf(uid),
            builder: (c, snap) {
              final name = snap.data ?? 'this user';
              return _sheetTile(
                Icons.block_rounded,
                'Block $name',
                "You won't see their messages in your groups",
                () async {
                  Navigator.pop(ctx);
                  try {
                    await _service.blockUser(widget.currentUserId, uid);
                    _toast('Blocked $name');
                  } catch (e) {
                    _toast('Failed to block: $e');
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------- message actions (NEW)

  String _previewOf(Map<String, dynamic> m) {
    final type = (m['type'] ?? 'text') as String;
    switch (type) {
      case 'image':
        return '📷 Photo';
      case 'audio':
        return '🎤 Voice message';
      case 'sticker':
        return '🙂 Sticker';
      case 'poll':
        return '📊 ${m['text'] ?? 'Poll'}';
      case 'file':
        final n = (m['fileName'] ?? '') as String;
        return '📎 ${n.isEmpty ? 'File' : n}';
      default:
        return (m['text'] ?? '') as String;
    }
  }

  Future<void> _startReply(String id, Map<String, dynamic> m) async {
    final name = await _nameOf((m['senderId'] ?? '') as String);
    if (!mounted) return;
    setState(() => _replyTo = {'id': id, 'text': _previewOf(m), 'name': name});
    _focus.requestFocus();
  }

  void _showMessageOptions(String id, Map<String, dynamic> m) {
    final model = MessageModel.fromMap(m, id);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => MessageOptionsSheet(
        message: model,
        currentUserId: widget.currentUserId,
        onReactionSelected: (emoji) => _service.toggleReaction(
          widget.groupId,
          id,
          widget.currentUserId,
          emoji,
        ),
        onReply: () => _startReply(id, m),
        onCopy: () {},
        onUnsend: () {},
        onForward: () => _forward(m),
        onDelete: () => _deleteMessage(id, m),
        // Any member can pin / unpin (system messages can't be pinned).
        onPin: m['type'] != 'system'
            ? (id == _pinnedId ? _unpin : () => _pinMessage(id, m))
            : null,
        pinTitle: id == _pinnedId ? 'Unpin message' : 'Pin message',
        onSeenBy: m['senderId'] == widget.currentUserId
            ? () => _showSeenBy(id, m)
            : null,
      ),
    );
  }

  void _forward(Map<String, dynamic> m) {
    final type = (m['type'] ?? 'text') as String;
    final text = (m['text'] ?? '') as String;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => ForwardContactSheet(
        currentUserId: widget.currentUserId,
        onSelectUser: (targetUserId, targetUserName) async {
          await ChatService().sendMessage(
            widget.currentUserId,
            targetUserId,
            text,
            type: type,
            isForwarded: true,
          );
          if (!mounted) return;
          Navigator.pop(sheetCtx);
          _toast('Forwarded to $targetUserName');
        },
      ),
    );
  }

  Future<void> _deleteMessage(String id, Map<String, dynamic> m) async {
    final isMine = m['senderId'] == widget.currentUserId;

    const card = Color(0xFFEEE8E7);
    const field = Color(0xFFE5DFDC);

    Widget optionTile({
      required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap,
    }) {
      return Material(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 21),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.nunito(fontSize: 12, color: _muted),
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
      );
    }

    final choice = await showDialog<String>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: card,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 16),
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
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: _danger,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete message?',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isMine
                    ? 'Choose how you want to remove this message.'
                    : 'This removes the message only for you.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  color: _muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              optionTile(
                icon: Icons.visibility_off_rounded,
                title: 'Delete for me',
                subtitle: 'Others in the group can still see it',
                color: _plum,
                onTap: () => Navigator.pop(ctx, 'me'),
              ),
              if (isMine) ...[
                const SizedBox(height: 10),
                optionTile(
                  icon: Icons.undo_rounded,
                  title: 'Delete for everyone',
                  subtitle: 'Removed for everyone in the group',
                  color: _danger,
                  onTap: () => Navigator.pop(ctx, 'all'),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: field,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.nunito(
                      color: _textDark,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (choice == null) return;

    try {
      if (choice == 'all') {
        await _service.unsendGroupMessage(widget.groupId, id);
        if (id == _pinnedId) await _service.unpinGroupMessage(widget.groupId);
      } else {
        await _service.deleteMessageForMe(
          widget.groupId,
          id,
          widget.currentUserId,
        );
      }
    } catch (e) {
      _toast('Failed to delete: $e');
    }
  }

  Widget _buildReplyBanner() {
    final r = _replyTo!;
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: const Border(left: BorderSide(color: _plum, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${r['name']}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _plum,
                  ),
                ),
                Text(
                  r['text'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: colors.onSurface),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyTo = null),
          ),
        ],
      ),
    );
  }

  // quoted message shown inside a reply bubble
  Widget _buildQuote(Map<String, dynamic> m, bool isMine) {
    final fg = isMine ? Colors.white : _plum;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: fg, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            (m['replyToSender'] ?? '') as String,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          Text(
            (m['replyToText'] ?? '') as String,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              color: isMine ? Colors.white70 : _textDark,
            ),
          ),
        ],
      ),
    );
  }

  // emoji reactions under a bubble
  Widget _buildReactions(Map<String, dynamic> m) {
    final raw = m['reactions'];
    if (raw is! Map || raw.isEmpty) return const SizedBox.shrink();
    final counts = <String, int>{};
    for (final e in raw.values) {
      counts[e.toString()] = (counts[e.toString()] ?? 0) + 1;
    }
    final label = counts.entries
        .map((e) => e.value > 1 ? '${e.key} ${e.value}' : e.key)
        .join('  ');
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _plum.withValues(alpha: 0.2)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _service.watchGroup(widget.groupId),
      builder: (context, groupSnap) {
        final data = groupSnap.data?.data();
        if (groupSnap.connectionState == ConnectionState.waiting &&
            data == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _plum)),
          );
        }
        if (data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Group not found')),
          );
        }

        _participants = List<String>.from(data['participants'] ?? []);
        final pinned = data['pinnedMessage'] is Map
            ? Map<String, dynamic>.from(data['pinnedMessage'] as Map)
            : null;
        _pinnedId = pinned?['id'] as String?;
        _ensureMemberNames();
        final name = (data['groupName'] ?? 'Group') as String;
        final photo = data['groupPhotoUrl'] as String?;

        if (!_participants.contains(widget.currentUserId)) {
          return Scaffold(
            appBar: AppBar(title: Text(name)),
            body: const Center(child: Text('You are no longer in this group')),
          );
        }

        // Clear the unread badge while the chat is open.
        final unread =
            (data['unreadCount_${widget.currentUserId}'] ?? 0) as int;
        if (unread > 0) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _service.markRead(widget.groupId, widget.currentUserId),
          );
        }

        return Scaffold(
          backgroundColor: colors.surface,
          appBar: AppBar(
            backgroundColor: colors.surface,
            foregroundColor: _textDark,
            elevation: 0,
            titleSpacing: 0,
            leading: _searching
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _closeSearch,
                  )
                : null,
            title: _searching
                ? _buildSearchField()
                : InkWell(
              onTap: _openInfo,
              child: Row(
                children: [
                  GroupAvatar(name: name, photoUrl: photo, radius: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            color: _textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        _buildSubtitle(data),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: _searching
                ? const <Widget>[]
                : [
              IconButton(
                tooltip: 'Search',
                icon: const Icon(Icons.search_rounded, color: _iconColor),
                onPressed: _openSearch,
              ),
              IconButton(
                tooltip: _isMuted ? 'Unmute' : 'Mute',
                icon: Icon(
                  _isMuted
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_none_rounded,
                  color: _iconColor,
                ),
                onPressed: _toggleMute,
              ),
              IconButton(
                icon: const Icon(Icons.info, color: _iconColor),
                onPressed: _openInfo,
              ),
            ],
          ),
          body: Column(
            children: [
              if (pinned != null && !_searching) _buildPinnedBanner(pinned),
              Expanded(child: _buildMessages()),
              if (_sending)
                const LinearProgressIndicator(minHeight: 2, color: _plum),
              if (!_searching) ...[
                if (_mentionQuery != null) _buildMentionList(),
                if (_replyTo != null) _buildReplyBanner(),
                _buildInputBar(),
                if (_showPanel) _buildPanel(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessages() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchMessages(widget.groupId),
      builder: (context, snap) {
        final docs = (snap.data?.docs ?? []).where((d) {
          final del = d.data()['deletedFor'];
          if (d.data()['isUnsent'] == true) return false; // old placeholders
          if (_blocked.contains(d.data()['senderId'])) return false; // blocked
          return !(del is List && del.contains(widget.currentUserId));
        }).toList();
        _markSeen(docs);
        final shown = _searchQuery.isEmpty
            ? docs
            : docs.where((d) => _matchesSearch(d.data())).toList();
        if (shown.isEmpty) {
          return Center(
            child: Text(
              _searchQuery.isEmpty ? 'No messages yet' : 'No results found',
              style: GoogleFonts.nunito(color: _muted),
            ),
          );
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: shown.length,
          itemBuilder: (context, i) =>
              _buildMessage(shown[i].id, shown[i].data()),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final colors = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        child: _recording
            ? _buildRecordingRow()
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.add_photo_alternate,
                        color: _inputIcon,
                        size: 22,
                      ),
                      onPressed: _sending ? null : _sendPhoto,
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.attach_file,
                        color: _inputIcon,
                        size: 22,
                      ),
                      tooltip: 'Send a file',
                      onPressed: _sending ? null : _showAttachSheet,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focus,
                        minLines: 1,
                        maxLines: 4,
                        cursorColor: _plum,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF424242),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintMaxLines: 1,
                          hintStyle: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF8A8587),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          suffixIcon: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              _showPanel
                                  ? Icons.keyboard
                                  : Icons.emoji_emotions_outlined,
                              color: _inputIcon,
                              size: 24,
                            ),
                            onPressed: _togglePanel,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _plum,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _hasText ? Icons.send : Icons.mic,
                          color: Colors.white,
                          size: 18,
                        ),
                        onPressed: _hasText ? _sendText : _startRecording,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRecordingRow() {
    final t =
        '${(_seconds ~/ 60).toString().padLeft(2, '0')}:${(_seconds % 60).toString().padLeft(2, '0')}';
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: _danger),
          onPressed: () => _stopRecording(send: false),
        ),
        const Icon(Icons.graphic_eq, color: _plum),
        const SizedBox(width: 8),
        Text(
          'Recording $t',
          style: GoogleFonts.nunito(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 22,
          backgroundColor: _plum,
          child: IconButton(
            icon: const Icon(Icons.stop, color: Colors.white, size: 22),
            onPressed: () => _stopRecording(send: true),
          ),
        ),
      ],
    );
  }

  /// Emoji tab + Sticker tab, like the 1-to-1 chat.
  Widget _buildPanel() {
    return SizedBox(
      height: 280,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              labelColor: _plum,
              unselectedLabelColor: _inputIcon,
              indicatorColor: _plum,
              tabs: [
                Tab(icon: Icon(Icons.emoji_emotions_outlined)),
                Tab(icon: Icon(Icons.sticky_note_2_outlined)),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  EmojiPicker(
                    textEditingController: _controller,
                    config: const Config(height: 232),
                  ),
                  _stickers.isEmpty
                      ? Center(
                          child: Text(
                            'No stickers found',
                            style: GoogleFonts.nunito(color: _muted),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                              ),
                          itemCount: _stickers.length,
                          itemBuilder: (context, i) => InkWell(
                            onTap: () => _sendSticker(_stickers[i]),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                _stickers[i],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------- messages

  String _formatTime(dynamic ts) {
    if (ts is Timestamp) return DateFormat('h:mm a').format(ts.toDate());
    return '';
  }

  void _openImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
      ),
    );
  }

  // NEW: readable size like "1.5 KB"
  String _formatSize(int b) {
    if (b <= 0) return '';
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // NEW: file name from a URL, used when an old message has no fileName
  String _nameFromUrl(String url) {
    try {
      return Uri.decodeComponent(Uri.parse(url).pathSegments.last);
    } catch (_) {
      return 'File';
    }
  }

  // NEW: look up a user's display name (cached, so each user is read once)
  final Map<String, Future<String>> _nameFutures = {};
  final Map<String, Future<String>> _systemFutures = {};

  Future<String> _nameOf(String uid) {
    return _nameFutures.putIfAbsent(uid, () async {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final n = doc.data()?['name']?.toString().trim();
        if (n != null && n.isNotEmpty) return n;
      } catch (_) {}
      return 'User';
    });
  }

  // NEW: replaces any user IDs inside a system message with real names
  Future<String> _resolveSystemText(String content) {
    return _systemFutures.putIfAbsent(content, () async {
      final ids = RegExp(r'[A-Za-z0-9]{20,}')
          .allMatches(content)
          .map((m) => m.group(0)!)
          .toSet()
          .toList();
      var out = content;
      for (final id in ids) {
        out = out.replaceAll(id, await _nameOf(id));
      }
      return out;
    });
  }

  Widget _buildMessage(String id, Map<String, dynamic> m) {
    final colors = Theme.of(context).colorScheme;
    final type = (m['type'] ?? 'text') as String;
    final content = (m['text'] ?? '') as String;
    final sender = (m['senderId'] ?? '') as String;
    final time = _formatTime(m['timestamp']);

    if (type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: FutureBuilder<String>(
            future: _resolveSystemText(content),
            builder: (context, snap) => Text(
              snap.data ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: _muted, fontSize: 12.5),
            ),
          ),
        ),
      );
    }

    final isMine = sender == widget.currentUserId;
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    final isUnsent = m['isUnsent'] == true;

    Widget body;
    if (isUnsent) {
      body = Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: isMine ? _bubbleBlue.withValues(alpha: 0.45) : _incomingBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.block,
              size: 15,
              color: isMine ? Colors.white : _muted,
            ),
            const SizedBox(width: 6),
            Text(
              'This message was unsent',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: isMine ? Colors.white : _muted,
              ),
            ),
          ],
        ),
      );
    } else if (type == 'image') {
      body = GestureDetector(
        onTap: () => _openImage(content),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Image.network(
                content,
                width: 220,
                fit: BoxFit.cover,
                loadingBuilder: (c, child, p) => p == null
                    ? child
                    : Container(
                        width: 220,
                        height: 220,
                        color: Colors.black12,
                        child: const Center(
                          child: CircularProgressIndicator(color: _plum),
                        ),
                      ),
                errorBuilder: (c, e, s) => Container(
                  width: 220,
                  height: 120,
                  color: Colors.black12,
                  child: const Icon(Icons.broken_image, color: _muted),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    time,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (type == 'sticker') {
      body = Column(
        crossAxisAlignment: isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Image.asset(
            content,
            width: 130,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.broken_image, color: _muted),
          ),
          Text(time, style: const TextStyle(color: _muted, fontSize: 10)),
        ],
      );
    } else if (type == 'audio') {
      body = Container(
        width: 230,
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMine ? _bubbleBlue : _incomingBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: VoiceBubble(
          url: content,
          seconds: (m['duration'] ?? 0) as int,
          time: time,
          isMine: isMine,
        ),
      );
    } else if (type == 'poll') {
      body = _buildPoll(id, m, isMine, time);
    } else if (type == 'file') {
      // NEW: file bubble
      final textColor = isMine ? Colors.white : colors.onSurface;
      final url = ((m['fileUrl'] ?? content) as String);
      final fileName = ((m['fileName'] as String?)?.isNotEmpty ?? false)
          ? m['fileName'] as String
          : _nameFromUrl(url);
      final size = _formatSize(((m['fileSize'] ?? 0) as num).toInt());

      body = InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (url.isEmpty) return;
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          decoration: BoxDecoration(
            color: isMine ? _fileColor : _incomingBubble,
            borderRadius: BorderRadius.circular(18),
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.insert_drive_file, color: textColor, size: 32),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (size.isNotEmpty)
                            Text(
                              size,
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
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    time,
                    style: TextStyle(
                      color: isMine ? Colors.white70 : colors.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      body = Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMine ? _bubbleBlue : _incomingBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (m['replyToText'] != null) _buildQuote(m, isMine),
              _buildMessageText(content, m, isMine, colors),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  time,
                  style: TextStyle(
                    color: isMine ? Colors.white70 : colors.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine)
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 2),
                child: GestureDetector(
                  onTap: () => _showUserActions(sender),
                  child: FutureBuilder<String>(
                    future: _nameOf(sender),
                    builder: (context, snap) => Text(
                      snap.data ?? '',
                      style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: _plum,
                      ),
                    ),
                  ),
                ),
              ),
            GestureDetector(
              onLongPress: isUnsent ? null : () => _showMessageOptions(id, m),
              child: body,
            ),
            _buildReactions(m),
            if (isMine && !isUnsent) _buildSeenLabel(id, m),
          ],
        ),
      ),
    );
  }
>>>>>>> d488486fab56955d176d766d3bcd2eaaca12ce6a
}