import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceDraft {
  const VoiceDraft({
    required this.path,
    required this.durationMs,
    required this.bytes,
    required this.mimeType,
  });

  final String path;
  final int durationMs;
  final int bytes;
  final String mimeType;
}

class VoiceRecorderController {
  VoiceRecorderController() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  Timer? _timer;
  int _elapsedMs = 0;

  bool get isRecording => _timer != null;
  int get elapsedMs => _elapsedMs;

  /// Call after the user deliberately presses and holds/taps Record.
  Future<void> start() async {
    final allowed = await _recorder.hasPermission();
    if (!allowed) {
      throw StateError('Microphone permission was not granted.');
    }

    String path = '';
    RecordConfig config;

    if (kIsWeb) {
      // Web uses Opus/WebM encoding and an empty path string to trigger Blob URL generation
      config = const RecordConfig(
        encoder: AudioEncoder.opus,
        numChannels: 1,
        sampleRate: 44100,
        bitRate: 64000,
      );
    } else {
      // Native platforms use path_provider and AAC-LC encoding
      final directory = await getTemporaryDirectory();
      final fileName = 'voice_${DateTime.now().microsecondsSinceEpoch}.m4a';
      path = '${directory.path}/$fileName';

      config = const RecordConfig(
        encoder: AudioEncoder.aacLc,
        numChannels: 1,
        sampleRate: 44100,
        bitRate: 64000,
      );
    }

    await _recorder.start(
      config,
      path: path,
    );

    _elapsedMs = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _elapsedMs += 100;
    });
  }

  /// Stops the recorder but keeps the temporary file/Blob for preview/upload.
  Future<VoiceDraft?> stop() async {
    _timer?.cancel();
    _timer = null;

    final path = await _recorder.stop();
    if (path == null || path.isEmpty) return null;

    if (kIsWeb) {
      // Web: Read byte size directly from local Blob URL via HTTP GET
      final response = await http.get(Uri.parse(path));
      
      return VoiceDraft(
        path: path,
        durationMs: _elapsedMs,
        bytes: response.bodyBytes.length,
        mimeType: 'audio/webm',
      );
    } else {
      // Mobile/Desktop: Check native File existence and length
      final file = File(path);
      if (!await file.exists()) return null;

      return VoiceDraft(
        path: path,
        durationMs: _elapsedMs,
        bytes: await file.length(),
        mimeType: 'audio/mp4',
      );
    }
  }

  /// Use for a cancelled draft; `cancel()` also removes the recorder output.
  Future<void> cancel() async {
    _timer?.cancel();
    _timer = null;
    _elapsedMs = 0;
    await _recorder.cancel();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    await _recorder.dispose();
  }
}