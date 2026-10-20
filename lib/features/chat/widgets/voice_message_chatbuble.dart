import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.audioUrl,
    required this.durationMs,
    required this.isMine,
  });

  final String audioUrl;
  final int durationMs;
  final bool isMine;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final _player = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  Duration _position = Duration.zero;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _player.positionStream.listen((value) {
      if (mounted) setState(() => _position = value);
    });
  }

  Future<void> _togglePlayback() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_player.playing) {
        await _player.pause();
      } else {
        // Calling setUrl more than once is safe, but avoid it if already loaded.
        if (_player.audioSource == null) {
          await _player.setUrl(widget.audioUrl);
        }
        await _player.play();
      }
    } on PlayerException catch (error) {
      setState(() => _error = 'Audio could not be loaded: ${error.message}');
    } catch (_) {
      setState(() => _error = 'Audio playback failed. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = Duration(milliseconds: widget.durationMs);
    final fraction = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Semantics(
      label: 'Voice message, ${_format(total)} long',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.isMine ? Colors.blue : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: _player.playing ? 'Pause voice message' : 'Play voice message',
              onPressed: _loading ? null : _togglePlayback,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(_player.playing ? Icons.pause : Icons.play_arrow),
            ),
            SizedBox(
              width: 130,
              child: LinearProgressIndicator(value: fraction),
            ),
            const SizedBox(width: 8),
            Text(_format(_player.playing ? _position : total)),
            if (_error != null) const Padding(
              padding: EdgeInsets.only(left: 6),
              child: Icon(Icons.error_outline, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  String _format(Duration value) {
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}