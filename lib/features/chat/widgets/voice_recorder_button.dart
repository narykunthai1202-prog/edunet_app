import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

// 🎨 Palette (same as the rest of the app)
const Color _kPlum = Color(0xFF6B4A5B); // idle mic button
const Color _kRose = Color(0xFFE0BCC4); // soft glow while recording
const Color _kDanger = Color(0xFFC2674B); // recording / stop (terracotta)

class VoiceRecorderButton extends StatefulWidget {
  final Function(String path) onRecordingComplete;

  const VoiceRecorderButton({super.key, required this.onRecordingComplete});

  @override
  State<VoiceRecorderButton> createState() => _VoiceRecorderButtonState();
}

class _VoiceRecorderButtonState extends State<VoiceRecorderButton> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
        return;
      }

      String savePath = '';
      final RecordConfig config = kIsWeb
          ? const RecordConfig(encoder: AudioEncoder.opus)
          : const RecordConfig(encoder: AudioEncoder.aacLc);

      // Only invoke path_provider on native platforms (Android, iOS, Desktop)
      if (!kIsWeb) {
        final dir = await getTemporaryDirectory();
        savePath =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      }

      // Empty path string on Web triggers browser Blob URL generation
      await _audioRecorder.start(config, path: savePath);
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      debugPrint('Error starting record: $e');
      if (mounted) setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecording() async {
    try {
      final String? path = await _audioRecorder.stop();
      if (mounted) setState(() => _isRecording = false);

      if (path != null && path.isNotEmpty) {
        widget.onRecordingComplete(path);
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      if (mounted) setState(() => _isRecording = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (_isRecording) {
          _stopRecording();
        } else {
          _startRecording();
        }
      },
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _isRecording ? _kDanger : _kPlum,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (_isRecording ? _kDanger : _kRose).withValues(alpha: 0.5),
              blurRadius: _isRecording ? 14 : 8,
              spreadRadius: _isRecording ? 2 : 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}