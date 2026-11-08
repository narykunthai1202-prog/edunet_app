import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

/// Shows the picked video BEFORE it is sent.
/// Pops with `true` when the user taps Send, `false` (or null) otherwise.
///
/// final ok = await Navigator.push<bool>(
///   context,
///   MaterialPageRoute(builder: (_) => VideoPreviewScreen(file: video)),
/// );
/// if (ok != true) return;   // user cancelled
class VideoPreviewScreen extends StatefulWidget {
  final XFile file;
  const VideoPreviewScreen({super.key, required this.file});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  late final VideoPlayerController _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();

    // On web the picked file path is a blob URL, on mobile it is a real path.
    _controller = kIsWeb
        ? VideoPlayerController.networkUrl(Uri.parse(widget.file.path))
        : VideoPlayerController.file(File(widget.file.path));

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.play();
    }).catchError((_) {
      if (mounted) setState(() => _failed = true);
    });

    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.value;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Preview'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _failed
                  ? const Text(
                      'Could not load this video',
                      style: TextStyle(color: Colors.white),
                    )
                  : !value.isInitialized
                      ? const CircularProgressIndicator()
                      : GestureDetector(
                          onTap: () => value.isPlaying
                              ? _controller.pause()
                              : _controller.play(),
                          child: AspectRatio(
                            aspectRatio: value.aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                VideoPlayer(_controller),
                                if (!value.isPlaying)
                                  const Icon(
                                    Icons.play_circle_fill,
                                    size: 64,
                                    color: Colors.white70,
                                  ),
                              ],
                            ),
                          ),
                        ),
            ),
          ),
          if (value.isInitialized) ...[
            VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _format(value.position),
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    _format(value.duration),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _failed
                          ? null
                          : () => Navigator.pop(context, true),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Send'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}