import 'dart:async';
import 'dart:io';

import 'package:edunest_app/features/chat/services/chat_service.dart';
import 'package:edunest_app/features/chat/widgets/chat_extras.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/voice_message_sender.dart';
import '../controllers/voice_recorder_controller.dart';
import '../services/cloudinary_service.dart';

class ChatInputField extends StatefulWidget {
  const ChatInputField({
    super.key,
    required this.conversationId,
    required this.currentUserId,
    required this.receiverId,
    required this.onSendMessage,
    this.onPickImage,
    this.onSendFile, // NEW (optional, so other screens don't break)
  });

  final String conversationId;
  final String currentUserId;
  final String receiverId;
  final Function(String) onSendMessage;
  final VoidCallback? onPickImage;

  // NEW: FIX - this belongs to the widget, not to the State class
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
  bool _isUploadingFile = false; // NEW

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

  // NEW: pick any file, upload it to Cloudinary, hand it to the screen
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
      final video = await ImagePicker().pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 2),
      );
      if (video == null) return;

      setState(() => _isUploadingVideo = true);

      await _chatService.sendVideoMessage(
        chatId: widget.conversationId,
        senderId: widget.currentUserId,
        receiverId: widget.receiverId,
        video: video,
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: Colors.grey[300],
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
                      color: const Color(0xFF2563EB),
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
                      color: const Color(0xFF8B5CF6),
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
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
  // Voice recording (unchanged)
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, -2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isUploadingVideo || _isUploadingFile)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 3),
              ),
            if (_isRecording)
              _buildRecordingComposer()
            else if (_pendingVoiceDraft != null)
              _buildVoiceDraftComposer(_pendingVoiceDraft!)
            else
              _buildTextComposer(hasText),

            // Emoji + sticker panel
            if (_showPanel && !_isRecording && _pendingVoiceDraft == null)
              EmojiStickerPanel(
                controller: _controller,
                onStickerSelected: _sendSticker,
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
              color: Colors.grey),
          tooltip: 'Attach photo or video',
          onPressed: _isUploadingVideo ? null : _showAttachMenu,
        ),
        // NEW: paperclip (only shown when the screen supports files)
        if (widget.onSendFile != null)
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            tooltip: 'Send a file',
            onPressed: _isUploadingFile ? null : _pickFile,
          ),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _handleSendText(),
            decoration: InputDecoration(
              hintText: 'Type a message...',
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _showPanel
                      ? Icons.keyboard_alt_outlined
                      : Icons.emoji_emotions_outlined,
                  color: _showPanel
                      ? const Color(0xFF2563EB)
                      : Colors.grey[600],
                ),
                tooltip: 'Emoji & stickers',
                onPressed: _togglePanel,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _roundActionButton(
          tooltip: hasText ? 'Send message' : 'Record voice message',
          icon: hasText ? Icons.send : Icons.mic,
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
        const Icon(Icons.graphic_eq, color: Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Recording ${_formatDuration(Duration(milliseconds: _recorder.elapsedMs))}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        _roundActionButton(
          tooltip: 'Stop recording',
          icon: Icons.stop,
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
        const Icon(Icons.mic, color: Color(0xFF2563EB)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Voice message • ${_formatDuration(Duration(milliseconds: draft.durationMs))}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        _roundActionButton(
          tooltip: 'Send voice message',
          icon: Icons.send,
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
        radius: 20,
        backgroundColor: const Color(0xFF2563EB),
        child: IconButton(
          icon: isLoading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon, color: Colors.white, size: 18),
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