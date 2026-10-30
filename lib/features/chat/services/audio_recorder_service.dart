
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  /// Check permissions and start recording
  Future<void> startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      if (kIsWeb) {
        // Web does not use local file system paths
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: '',
        );
      } else {
        // Native platforms (Android, iOS, Desktop)
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );
      }
    }
  }

  /// Stop recording and return path (File path on mobile, Blob URL on Web)
  Future<String?> stopRecording() async {
    final path = await _audioRecorder.stop();
    return path;
  }

  /// Optional: Cancel recording without saving
  Future<void> cancelRecording() async {
    await _audioRecorder.stop();
  }

  /// Clean up recorder resources
  void dispose() {
    _audioRecorder.dispose();
  }
}