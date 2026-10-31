import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/message_model.dart';

class ChatAudioBubble extends StatefulWidget {
  final MessageModel? message;
  final String? audioUrl;
  final bool isMe;
  final String formattedTime;

  const ChatAudioBubble({
    super.key,
    this.message,
    this.audioUrl,
    required this.isMe,
    required this.formattedTime,
  });

  @override
  State<ChatAudioBubble> createState() => _ChatAudioBubbleState();
}

class _ChatAudioBubbleState extends State<ChatAudioBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Helper getter to extract the audio URL regardless of how it was passed
  String get _effectiveAudioUrl {
    if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
      return widget.audioUrl!;
    }
    if (widget.message != null && widget.message!.text.isNotEmpty) {
      return widget.message!.text;
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _loadAudioSource();
  }

  @override
  void didUpdateWidget(covariant ChatAudioBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioUrl != widget.audioUrl ||
        oldWidget.message?.text != widget.message?.text) {
      _loadAudioSource();
    }
  }

  void _setupAudioListeners() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _audioPlayer.onDurationChanged.listen((newDuration) {
      if (mounted) {
        setState(() => _duration = newDuration);
      }
    });

    _audioPlayer.onPositionChanged.listen((newPosition) {
      if (mounted) {
        setState(() => _position = newPosition);
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _position = Duration.zero;
          _isPlaying = false;
        });
      }
    });
  }

  Future<void> _loadAudioSource() async {
    final url = _effectiveAudioUrl;
    if (url.isEmpty) return;

    try {
      await _audioPlayer.setSource(UrlSource(url));
      final dur = await _audioPlayer.getDuration();
      if (dur != null && mounted) {
        setState(() => _duration = dur);
      }
    } catch (e) {
      debugPrint('Error loading audio source: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _togglePlay() async {
    if (_effectiveAudioUrl.isEmpty) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isMe ? Colors.white : const Color(0xFF2563EB);
    final secondaryColor = widget.isMe ? Colors.white70 : Colors.black54;

    final remainingDuration = _duration - _position;
    final displayTime = _isPlaying
        ? (remainingDuration.isNegative ? Duration.zero : remainingDuration)
        : _duration;

    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 240,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isMe ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(widget.isMe ? 16 : 0),
            bottomRight: Radius.circular(widget.isMe ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    color: primaryColor,
                    size: 36,
                  ),
                  onPressed: _togglePlay,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderThemeData(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      trackHeight: 3,
                      thumbColor: primaryColor,
                      activeTrackColor: primaryColor,
                      inactiveTrackColor: secondaryColor.withAlpha(50),
                    ),
                    child: Slider(
                      min: 0,
                      max: _duration.inMilliseconds > 0
                          ? _duration.inMilliseconds.toDouble()
                          : 1.0,
                      value: _position.inMilliseconds
                          .clamp(0, _duration.inMilliseconds)
                          .toDouble(),
                      onChanged: (val) async {
                        final position = Duration(milliseconds: val.toInt());
                        await _audioPlayer.seek(position);
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(displayTime),
                    style: TextStyle(fontSize: 10, color: secondaryColor),
                  ),
                  Text(
                    widget.formattedTime,
                    style: TextStyle(fontSize: 10, color: secondaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}