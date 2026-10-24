import 'dart:async';

import 'package:edunest_app/features/chat/services/cloudinary_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatInputBar extends StatefulWidget {
  final String folder; // e.g. 'chat/$groupId'
  final void Function(String text) onSendText;
  final void Function(String url) onSendImage;
  final void Function(String url, int seconds) onSendAudio;
  final void Function(String url, String name, int size) onSendFile; // NEW

  const ChatInputBar({
    super.key,
    required this.folder,
    required this.onSendText,
    required this.onSendImage,
    required this.onSendAudio,
    required this.onSendFile, // NEW
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _controller = TextEditingController();
  final _recorder = AudioRecorder();
  bool _hasText = false;
  bool _recording = false;
  bool _busy = false;
  int _seconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  void _sendText() {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    widget.onSendText(t);
    _controller.clear();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked == null) return;
    setState(() => _busy = true);
    final bytes = await picked.readAsBytes();
    final url = await CloudinaryService.uploadBytes(
      bytes,
      picked.name,
      folder: widget.folder,
    );
    if (mounted) setState(() => _busy = false);
    if (url != null) widget.onSendImage(url);
  }

  // NEW: pick any file and upload it
  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile();
    if (file == null) return;

    final size = await file.length();
    if (size != null && size > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 10 MB)')),
        );
      }
      return;
    }

    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 10 MB)')),
        );
      }
      return;
    }

    setState(() => _busy = true);
    final url = await CloudinaryService.uploadBytes(
      bytes,
      file.name,
      folder: widget.folder,
    );
    if (mounted) setState(() => _busy = false);

    if (url != null) {
      widget.onSendFile(url, file.name, bytes.length);
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Upload failed')));
    }
  }

  Future<void> _startRecording() async {
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }
    final ts = DateTime.now().millisecondsSinceEpoch;
    String path = '';
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path = '${dir.path}/voice_$ts.m4a';
    }
    await _recorder.start(
      RecordConfig(encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc),
      path: path,
    );
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() => _seconds++),
    );
  }

  Future<void> _stopRecording({required bool send}) async {
    _timer?.cancel();
    final path = await _recorder.stop();
    final secs = _seconds;
    setState(() => _recording = false);
    if (!send || path == null || secs < 1) return;

    setState(() => _busy = true);
    final bytes = await XFile(path).readAsBytes();
    final ext = kIsWeb ? 'webm' : 'm4a';
    final url = await CloudinaryService.uploadBytes(
      bytes,
      'voice_${DateTime.now().millisecondsSinceEpoch}.$ext',
      folder: widget.folder,
    );
    if (mounted) setState(() => _busy = false);
    if (url != null) widget.onSendAudio(url, secs);
  }

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF2563EB);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: _recording ? _recordingRow(blue) : _normalRow(blue),
      ),
    );
  }

  Widget _normalRow(Color blue) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.add_photo_alternate, color: Colors.grey),
          onPressed: _busy ? null : _pickImage,
        ),
        // NEW: attach file button
        IconButton(
          icon: const Icon(Icons.attach_file, color: Colors.grey),
          onPressed: _busy ? null : _pickFile,
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              filled: true,
              fillColor: colors.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              suffixIcon: const Icon(
                Icons.emoji_emotions_outlined,
                color: Colors.grey,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _busy
            ? const SizedBox(
                width: 40,
                height: 40,
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : CircleAvatar(
                backgroundColor: blue,
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
    );
  }

  Widget _recordingRow(Color blue) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _stopRecording(send: false),
        ),
        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 14),
        const SizedBox(width: 8),
        Text(_fmt(_seconds), style: const TextStyle(fontSize: 16)),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text('Recording...', style: TextStyle(color: Colors.grey)),
          ),
        ),
        CircleAvatar(
          backgroundColor: blue,
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white, size: 20),
            onPressed: () => _stopRecording(send: true),
          ),
        ),
      ],
    );
  }
}
