// lib/chat/views/group_chat_view.dart
import 'dart:async';

import 'package:edunest_app/features/chat/views/voice_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart'; // NEW

import '../services/cloudinary_service.dart';
import '../services/group_service.dart';
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
  static const _blue = Color(0xFF2563EB);

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

  @override
  void initState() {
    super.initState();
    _loadStickers();
    _focus.addListener(() {
      if (_focus.hasFocus && _showPanel) setState(() => _showPanel = false);
    });
    _controller.addListener(() {
      final has = _controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _controller.dispose();
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
    _controller.clear();
    await _service.sendMessage(
      groupId: widget.groupId,
      senderId: widget.currentUserId,
      text: text,
      participants: _participants,
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
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (data == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Group not found')),
          );
        }

        _participants = List<String>.from(data['participants'] ?? []);
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
            foregroundColor: colors.onSurface,
            elevation: 0,
            titleSpacing: 0,
            title: InkWell(
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
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${_participants.length} members',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.info, color: colors.primary),
                onPressed: _openInfo,
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(child: _buildMessages()),
              if (_sending) const LinearProgressIndicator(minHeight: 2),
              _buildInputBar(),
              if (_showPanel) _buildPanel(),
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
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (context, i) => _buildMessage(docs[i].data()),
        );
      },
    );
  }

  Widget _buildInputBar() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: SafeArea(
        top: false,
        child: _recording
            ? _buildRecordingRow()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate,
                      color: Colors.grey,
                    ),
                    onPressed: _sending ? null : _sendPhoto,
                  ),
                  // NEW: attach file
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.grey),
                    tooltip: 'Send a file',
                    onPressed: _sending ? null : _sendFile,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      style: const TextStyle(fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPanel
                                ? Icons.keyboard
                                : Icons.emoji_emotions_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: _togglePanel,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _blue,
                    child: IconButton(
                      icon: Icon(
                        _hasText ? Icons.send : Icons.mic,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _hasText ? _sendText : _startRecording,
                    ),
                  ),
                ],
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
          icon: const Icon(Icons.close, color: Colors.red),
          onPressed: () => _stopRecording(send: false),
        ),
        const Icon(Icons.graphic_eq, color: _blue),
        const SizedBox(width: 8),
        Text(
          'Recording $t',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const Spacer(),
        CircleAvatar(
          radius: 22,
          backgroundColor: _blue,
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
              labelColor: _blue,
              indicatorColor: _blue,
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
                      ? const Center(
                          child: Text(
                            'No stickers found',
                            style: TextStyle(color: Colors.grey),
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
                              borderRadius: BorderRadius.circular(6),
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

  Widget _buildMessage(Map<String, dynamic> m) {
    final colors = Theme.of(context).colorScheme;
    final type = (m['type'] ?? 'text') as String;
    final content = (m['text'] ?? '') as String;
    final sender = (m['senderId'] ?? '') as String;
    final time = _formatTime(m['timestamp']);

    if (type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            content,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      );
    }

    final isMine = sender == widget.currentUserId;
    final maxWidth = MediaQuery.of(context).size.width * 0.72;

    Widget body;
    if (type == 'image') {
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
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                errorBuilder: (c, e, s) => Container(
                  width: 220,
                  height: 120,
                  color: Colors.black12,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
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
                const Icon(Icons.broken_image, color: Colors.grey),
          ),
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      );
    } else if (type == 'audio') {
      body = Container(
        width: 230,
        padding: const EdgeInsets.fromLTRB(10, 8, 12, 6),
        decoration: BoxDecoration(
          color: isMine ? _blue : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: VoiceBubble(
          url: content,
          seconds: (m['duration'] ?? 0) as int,
          time: time,
          isMine: isMine,
        ),
      );
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
            color: isMine ? _blue : colors.surfaceContainerHighest,
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
          color: isMine ? _blue : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                content,
                style: TextStyle(
                  color: isMine ? Colors.white : colors.onSurface,
                  fontSize: 15,
                ),
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
                child: Text(
                  sender,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _blue,
                  ),
                ),
              ),
            body,
          ],
        ),
      ),
    );
  }
}
