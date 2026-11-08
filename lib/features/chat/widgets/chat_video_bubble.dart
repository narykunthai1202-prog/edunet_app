import 'package:flutter/material.dart';

import 'video_player_screen.dart';

/// Shows a video message as a thumbnail with a play button.
/// Tapping it opens the full-screen player.
///
/// Use it in chat_bubble.dart when message.type == 'video':
///
/// ChatVideoBubble(
///   url: message.fileUrl ?? message.text,
///   isMe: isMe,
///   formattedTime: formattedTime,
/// )
class ChatVideoBubble extends StatelessWidget {
  final String url;
  final bool isMe;
  final String formattedTime;

  const ChatVideoBubble({
    super.key,
    required this.url,
    required this.isMe,
    required this.formattedTime,
  });

  /// Cloudinary can make a thumbnail of a video: take the frame at 0 seconds,
  /// resize it, and change the file ending to .jpg.
  String get _thumbnailUrl {
    var thumb = url.replaceFirst('/upload/', '/upload/so_0,w_400,c_limit/');
    thumb = thumb.replaceFirst(RegExp(r'\.[a-zA-Z0-9]+$'), '.jpg');
    return thumb;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoPlayerScreen(url: url)),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                _thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Colors.black87,
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white54,
                    size: 48,
                  ),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.black12,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
              // Dark overlay + play button
              Container(color: Colors.black26),
              const Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.black54,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              // Time label
              Positioned(
                right: 8,
                bottom: 6,
                child: Text(
                  formattedTime,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}