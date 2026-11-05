import 'dart:async';
import 'dart:io';

import 'package:edunest_app/features/chat/services/chat_service.dart';
import 'package:edunest_app/features/chat/widgets/chat_extras.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/voice_message_sender.dart';
import '../controllers/voice_recorder_controller.dart';
import '../services/cloudinary_service.dart';
import 'video_preview_screen.dart';

// Theme colors (replace with your theme file colors if you have them)
const Color _plum = Color(0xFF6B4A5E);
const Color _plumSoft = Color(0xFF8A6F7E); // muted icons
const Color _pillBeige = Color(0xFFF1EBE8); // input bar background
const Color _sheetBeige = Color(0xFFF7F2F0); // attach menu background
const Color _mauve = Color(0xFFA0728A); // second accent (video)

class ChatInputField extends StatefulWidget {
  const ChatInputField({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.receiverId,
    required this.onSendMessage,
    this.onPickImage,
    this.onSendFile, // optional, so other screens don't break
  });

  final String conversationId;
  final String currentUserId;
  final String receiverId;
  final Function(String) onSendMessage;
  final VoidCallback? onPickImage;

  final void Function(String url, String name, int size)? onSendFile;

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final VoiceRecorderController _recorder = VoiceRecorderController();
  final VoiceMessageSender _voiceMessageSender = VoiceMessageSender();
  final ChatService _chatService = ChatService();
  Timer? _recordingUiTimer;
  VoiceDraft? _pendingVoiceDraft;
  bool _isRecording = false;
  bool _isSendingVoice = false;
  bool _showPanel = false;
  bool _isUploadingVideo = false;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    // Emoji picker edits the controller directly, so listen for changes
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
    // Close the panel when the keyboard opens
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _showPanel) {
        setState(() => _showPanel = false);
      }
    });
  }

  // Pick any file, upload it to Cloudinary, hand it to the screen
  Future<void> _pickFile() async {
    if (_isUploadingFile) return;
    setState(() => _isUploadingFile = true);
    try {
      final file =
          await CloudinaryService.pickAndUploadFile(folder: 'chat/files');
      if (file == null) return;
      widget.onSendFile?.call(file.url, file.name, file.size);
    } catch (e) {
      _showError('Could not send file: $e');
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  void _togglePanel() {
    if (_showPanel) {
      setState(() => _showPanel = false);
      _focusNode.requestFocus(); // bring keyboard back
    } else {
      _focusNode.unfocus(); // hide keyboard
      setState(() => _showPanel = true);
    }
  }

  void _handleSendText() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    widget.onSendMessage(text);
    _controller.clear();
  }

  // ---------------------------------------------------------------------
  // Stickers & video
  // ---------------------------------------------------------------------
  Future<void> _sendSticker(String path) async {
    try {
      await _chatService.sendStickerMessage(
        chatId: widget.conversationId,
        senderId: widget.currentUserId,
        receiverId: widget.receiverId,
        stickerPath: path,
      );
    } catch (e) {
      _showError('Sticker was not sent: $e');
    }
  }

  Future<void> _pickAndSendVideo() async {
  try {
    // 1. Pick (no upload yet)
    final video = await CloudinaryService.pickVideo();
    if (video == null) return;
    if (!mounted) return;

    // 2. Preview, with Cancel and Send buttons
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => VideoPreviewScreen(file: video)),
    );
    if (ok != true) return;

    setState(() => _isUploadingVideo = true);

    // 3. Upload to Cloudinary
    final uploaded = await CloudinaryService.uploadVideo(video);
    if (uploaded == null) {
      _showError('Video upload failed. Please try again.');
      return;
    }

    // 4. Save the message in Firestore
    await _chatService.sendVideoMessage(
      chatId: widget.conversationId,
      senderId: widget.currentUserId,
      receiverId: widget.receiverId,
      videoUrl: uploaded.url,
      fileName: uploaded.name,
      fileSize: uploaded.size,
    );
  } catch (e) {
    _showError('Video was not sent: $e');
  } finally {
    if (mounted) setState(() => _isUploadingVideo = false);
  }
}
  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _sheetBeige,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _attachOption(
                      icon: Icons.photo_rounded,
                      label: 'Photo',
                      color: _plum,
                      onTap: () {
                        Navigator.pop(ctx);
                        widget.onPickImage?.call();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _attachOption(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      color: _mauve,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickAndSendVideo();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Voice recording (logic unchanged)
  // ---------------------------------------------------------------------
  Future<void> _startRecording() async {
    try {
      setState(() => _showPanel = false);
      await _recorder.start();
      if (!mounted) return;

      _recordingUiTimer?.cancel();
      _recordingUiTimer = Timer.periodic(
        const Duration(milliseconds: 200),
        (_) {
          if (mounted) setState(() {});
        },
      );

      setState(() => _isRecording = true);
    } catch (error, stackTrace) {
      debugPrint('VOICE MESSAGE SEND ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);
      _showError('Voice message was not sent: $error');
    }
  }

  Future<void> _stopRecording() async {
    _recordingUiTimer?.cancel();
    _recordingUiTimer = null;

    try {
      final draft = await _recorder.stop();
      if (!mounted) return;

      setState(() {
        _isRecording = false;
        _pendingVoiceDraft = draft;
      });

      if (draft == null) {
        _showError('No voice message was recorded. Please try again.');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isRecording = false);
      _showError('Could not finish the voice recording.');
    }
  }

  Future<void> _discardVoiceDraft() async {
    _recordingUiTimer?.cancel();
    _recordingUiTimer = null;

    try {
      if (_isRecording) {
        await _recorder.cancel();
      }

      final draft = _pendingVoiceDraft;
      if (draft != null && !kIsWeb) {
        // Skip File delete on Web since Web uses memory blobs
        final file = File(draft.path);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {
      // The UI should still clear even if a temporary file is already gone.
    } finally {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _pendingVoiceDraft = null;
        });
      }
    }
  }

  Future<void> _sendVoiceDraft() async {
    final draft = _pendingVoiceDraft;
    if (draft == null || _isSendingVoice) return;

    setState(() => _isSendingVoice = true);

    try {
      await _voiceMessageSender.send(
        conversationId: widget.conversationId,
        senderId: widget.currentUserId,
        receiverId: widget.receiverId,
        draft: draft,
      );

      if (!mounted) return;
      setState(() => _pendingVoiceDraft = null);
    } catch (e, stackTrace) {
      debugPrint('VOICE SEND ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSendingVoice = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _recordingUiTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    unawaited(_recorder.dispose());
    super.dispose();
  }

  // ---------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isUploadingVideo || _isUploadingFile)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: _plum,
                  backgroundColor: _pillBeige,
                ),
              ),

            // Floating pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: _pillBeige,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isRecording
                  ? _buildRecordingComposer()
                  : (_pendingVoiceDraft != null
                      ? _buildVoiceDraftComposer(_pendingVoiceDraft!)
                      : _buildTextComposer(hasText)),
            ),

            // Emoji + sticker panel
            if (_showPanel && !_isRecording && _pendingVoiceDraft == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: EmojiStickerPanel(
                  controller: _controller,
                  onStickerSelected: _sendSticker,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextComposer(bool hasText) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.add_photo_alternate_rounded,
              color: _plumSoft),
          tooltip: 'Attach photo or video',
          onPressed: _isUploadingVideo ? null : _showAttachMenu,
        ),
        // Paperclip (only shown when the screen supports files)
        if (widget.onSendFile != null)
          IconButton(
            icon: const Icon(Icons.attach_file, color: _plumSoft),
            tooltip: 'Send a file',
            onPressed: _isUploadingFile ? null : _pickFile,
          ),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _handleSendText(),
            cursorColor: _plum,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPanel
                      ? Icons.keyboard_alt_outlined
                      : Icons.emoji_emotions_outlined,
                  color: _showPanel ? _plum : _plumSoft,
                ),
                tooltip: 'Emoji & stickers',
                onPressed: _togglePanel,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        _roundActionButton(
          tooltip: hasText ? 'Send message' : 'Record voice message',
          icon: hasText ? Icons.send_rounded : Icons.mic_rounded,
          onPressed: hasText ? _handleSendText : _startRecording,
        ),
      ],
    );
  }

  Widget _buildRecordingComposer() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.red),
          tooltip: 'Cancel recording',
          onPressed: _discardVoiceDraft,
        ),
        const Icon(Icons.graphic_eq, color: _plum),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Recording ${_formatDuration(Duration(milliseconds: _recorder.elapsedMs))}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A2A33),
            ),
          ),
        ),
        _roundActionButton(
          tooltip: 'Stop recording',
          icon: Icons.stop_rounded,
          onPressed: _stopRecording,
        ),
      ],
    );
  }

  Widget _buildVoiceDraftComposer(VoiceDraft draft) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Discard voice message',
          onPressed: _isSendingVoice ? null : _discardVoiceDraft,
        ),
        const Icon(Icons.mic_rounded, color: _plum),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Voice message • ${_formatDuration(Duration(milliseconds: draft.durationMs))}',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A2A33),
            ),
          ),
        ),
        _roundActionButton(
          tooltip: 'Send voice message',
          icon: Icons.send_rounded,
          onPressed: _isSendingVoice ? null : _sendVoiceDraft,
          isLoading: _isSendingVoice,
        ),
      ],
    );
  }

  Widget _roundActionButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: CircleAvatar(
        radius: 22,
        backgroundColor: _plum,
        child: IconButton(
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}