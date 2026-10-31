import 'package:flutter/material.dart';

import '../models/message_model.dart';

// Color of YOUR sent messages (plum, matches the mic button)
const Color _kSentColor = Color(0xFF6B4A5B);
// Color of the double-check when the message was seen
const Color _kSeenTick = Color(0xFFF2C6D6);

class ChatTextBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final String formattedTime;

  const ChatTextBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.formattedTime,
  });

  bool _isUrl(String text) {
    return text.startsWith('http://') || text.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.75,
      ),
      decoration: BoxDecoration(
        color: isMe ? const Color.fromARGB(255, 43, 92, 238) : colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isMe)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ↩️ FORWARDED INDICATOR BADGE
          if (message.isForwarded) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.reply_rounded, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Forwarded',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 🖼️ Quoted Reply Preview
          if (message.replyToText != null &&
              message.replyToText!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.2)
                    : colors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(
                    color: isMe ? Colors.white : const Color.fromARGB(255, 192, 187, 190),
                    width: 3,
                  ),
                ),
              ),
              child: _isUrl(message.replyToText!)
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            message.replyToText!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Photo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isMe ? Colors.white70 : colors.onSurface,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      message.replyToText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isMe ? Colors.white70 : colors.onSurface,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ),
          ],

          // Deleted messages are removed from the list before they get here,
          // so the bubble only ever shows the real message text.
          Text(
            message.text,
            style: TextStyle(
              color: isMe ? Colors.white : colors.onSurface,
              fontSize: 15,
            ),
          ),

          if (message.reactions.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: message.reactions.values.map((emoji) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 12)),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : colors.onSurfaceVariant,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  message.isSeen ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.isSeen
                      ? _kSeenTick
                      : Colors.white70,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}