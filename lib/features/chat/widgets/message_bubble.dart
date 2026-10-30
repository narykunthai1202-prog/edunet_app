import 'package:flutter/material.dart';
import '../models/message_model.dart'; // Make sure path points to your MessageModel

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    // Extract unique reaction emojis from the map
    final reactionsMap = message.reactions;
    final reactionEmojis = reactionsMap.values.toSet().join(' ');

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Stack(
          clipBehavior: Clip.none, // Allows reaction badge to float outside the bubble
          children: [
            // 1. The Main Message Bubble
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 16),
                ),
              ),
              child: Text(
                message.text, // Uses message text from model
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),

            // 2. The Reaction Badge Overlay
            if (reactionsMap.isNotEmpty)
              Positioned(
                bottom: -10,
                right: isMe ? 10 : null,
                left: isMe ? null : 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(blurRadius: 2, color: Colors.black26),
                    ],
                  ),
                  child: Text(
                    reactionEmojis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}