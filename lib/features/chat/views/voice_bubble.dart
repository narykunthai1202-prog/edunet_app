// lib/chat/widgets/voice_bubble.dart
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// 🎨 Palette (same as the rest of the app)
const Color _kPlum = Color(0xFF6B4A5B); // main accent
const Color _kRose = Color(0xFFE0BCC4); // dusty rose
const Color _kMuted = Color(0xFF7A6670); // muted text

class VoiceBubble extends StatefulWidget {
  final String url;
  final int seconds;
  final String time;
  final bool isMine;

  const VoiceBubble({
    super.key,
    required this.url,
    required this.seconds,
    required this.time,
    required this.isMine,
  });

  @override
  State<VoiceBubble> createState() => _VoiceBubbleState();
}

class _VoiceBubbleState extends State<VoiceBubble> {
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subs = [];
  bool _playing = false;
  Duration _position = Duration.zero;
  late Duration _duration = Duration(seconds: widget.seconds);

  @override
  void initState() {
    super.initState();
    _subs.add(_player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    }));
    _subs.add(_player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    }));
    _subs.add(_player.onDurationChanged.listen((d) {
      if (mounted && d.inMilliseconds > 0) setState(() => _duration = d);
    }));
    _subs.add(_player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    }));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
    } else if (_position > Duration.zero) {
      await _player.resume();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }

  String _fmt(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final mine = widget.isMine;

    // Mine  -> sits on a plum bubble: rose button + rose progress
    // Other -> sits on a light bubble: plum button + plum progress
    final accent = mine ? _kRose : _kPlum; // button, active track, thumb
    final buttonIcon = mine ? _kPlum : Colors.white;
    final sub = mine ? Colors.white70 : _kMuted;

    final maxMs = _duration.inMilliseconds < 1 ? 1 : _duration.inMilliseconds;
    final posMs = _position.inMilliseconds.clamp(0, maxMs).toDouble();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _toggle,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: buttonIcon,
                  size: 24,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                  overlayShape: SliderComponentShape.noOverlay,
                  activeTrackColor: accent,
                  inactiveTrackColor: accent.withValues(alpha: 0.35),
                  thumbColor: accent,
                ),
                child: Slider(
                  min: 0,
                  max: maxMs.toDouble(),
                  value: posMs,
                  onChanged: (v) =>
                      _player.seek(Duration(milliseconds: v.toInt())),
                ),
              ),
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                _fmt(_playing || _position > Duration.zero
                    ? _position
                    : _duration),
                style: TextStyle(color: sub, fontSize: 10),
              ),
            ),
            Text(widget.time, style: TextStyle(color: sub, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}