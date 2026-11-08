import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

// 🎨 Palette (same as the rest of the app)
const Color _kPlum = Color(0xFF6B4A5B); // my bubble / accents
const Color _kRose = Color(0xFFE0BCC4); // dusty rose
const Color _kField = Color(0xFFE5DFDC); // other person's bubble
const Color _kBorder = Color(0xFFDDD2CF); // other person's bubble border
const Color _kTextDark = Color(0xFF3A2A32); // dark plum-brown text
const Color _kMuted = Color(0xFF7A6670); // muted text

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
  StreamSubscription<PlayerState>? _stateSubscription;
  Duration _position = Duration.zero;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _player.positionStream.listen((value) {
      if (mounted) setState(() => _position = value);
    });

    // Rebuild when play/pause changes, and reset when the clip finishes.
    _stateSubscription = _player.playerStateStream.listen((state) async {
      if (state.processingState == ProcessingState.completed) {
        await _player.pause();
        await _player.seek(Duration.zero);
      }
      if (mounted) setState(() {});
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
      if (mounted) {
        setState(() => _error = 'Audio could not be loaded: ${error.message}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Audio playback failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mine = widget.isMine;
    final total = Duration(milliseconds: widget.durationMs);
    final fraction = total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    // Colors depend on whose message it is
    final bubbleColor = mine ? _kPlum : _kField;
    final buttonBg = mine ? _kRose : _kPlum;
    final buttonIcon = mine ? _kPlum : Colors.white;
    final progressFill = mine ? _kRose : _kPlum;
    final progressTrack = mine
        ? Colors.white.withValues(alpha: 0.25)
        : _kPlum.withValues(alpha: 0.18);
    final textColor = mine ? Colors.white : _kTextDark;
    final subTextColor = mine ? Colors.white70 : _kMuted;

    return Semantics(
      label: 'Voice message, ${_format(total)} long',
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 14, 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(20),
          border: mine ? null : Border.all(color: _kBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Round play / pause button
            Material(
              color: buttonBg,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _loading ? null : _togglePlayback,
                child: Tooltip(
                  message: _player.playing
                      ? 'Pause voice message'
                      : 'Play voice message',
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: _loading
                          ? SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: buttonIcon,
                              ),
                            )
                          : Icon(
                              _player.playing
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: buttonIcon,
                              size: 26,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Progress bar
            SizedBox(
              width: 120,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 4,
                  backgroundColor: progressTrack,
                  valueColor: AlwaysStoppedAnimation<Color>(progressFill),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Duration (counts up while playing)
            Text(
              _format(_player.playing ? _position : total),
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Tooltip(
                  message: _error!,
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: subTextColor,
                  ),
                ),
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