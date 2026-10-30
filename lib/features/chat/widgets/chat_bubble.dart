import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart'; // NEW
import '../models/message_model.dart';
import 'chat_extras.dart';

class ChatBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onDelete;
  final VoidCallback? onForward;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onDelete,
    this.onForward,
  });

  String _formatTime(DateTime time) {
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  bool get _isImage => message.type == 'image';
  bool get _isSticker => message.type == 'sticker';
  bool get _isVideo => message.type == 'video';
  bool get _isMedia => _isImage || _isVideo;
  bool get _isFile => message.type == 'file';

  void _showOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Quick emoji reactions
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['❤️', '👍', '😂', '🔥', '😮', '😢'].map((emoji) {
                      return InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Reacted with $emoji')),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(),

                // Forward
                ListTile(
                  leading:
                      const Icon(Icons.shortcut_rounded, color: Colors.black87),
                  title: const Text('Forward'),
                  onTap: () {
                    Navigator.pop(context);
                    if (onForward != null) onForward!();
                  },
                ),

                // Copy (not shown for stickers)
                if (!_isSticker)
                  ListTile(
                    leading:
                        const Icon(Icons.copy_rounded, color: Colors.black87),
                    title: Text(
                        (_isMedia || _isFile) ? 'Copy Link' : 'Copy Text'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            (_isMedia || _isFile)
                                ? 'Link copied to clipboard'
                                : 'Copied to clipboard',
                          ),
                        ),
                      );
                    },
                  ),

                // Delete (only my messages)
                if (isMe)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                    title: const Text('Delete Message',
                        style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // NEW: file message bubble
  Widget _fileBubble() {
    final name = message.fileName ?? 'File';
    final size = message.fileSize ?? 0;
    final textColor = isMe ? Colors.white : Colors.black87;
    final url =
        (message.fileUrl != null && message.fileUrl!.isNotEmpty)
            ? message.fileUrl!
            : message.text;

    String fmt(int b) {
      if (b < 1024) return '$b B';
      if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
      return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
    }

    return InkWell(
      onTap: () => launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: textColor, size: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    fmt(size),
                    style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isSticker) {
      return StickerBubble(path: message.text);
    }

    if (_isVideo) {
      return VideoBubble(url: message.text);
    }

    // NEW: file branch
    if (_isFile) {
      return _fileBubble();
    }

    if (_isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          message.text,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 220,
              height: 180,
              color: Colors.black12,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 220,
              height: 120,
              color: Colors.black12,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 36, color: Colors.grey),
                  SizedBox(height: 4),
                  Text('Failed to load image',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          },
        ),
      );
    }

    // Text (emoji works here too)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        message.text,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Stickers have no colored bubble, like in most chat apps
    final bool noBubble = _isSticker;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () => _showOptionsSheet(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: noBubble
              ? EdgeInsets.zero
              : EdgeInsets.all(_isMedia ? 4 : 10),
          decoration: noBubble
              ? null
              : BoxDecoration(
                  color:
                      isMe ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Forwarded banner
              if (message.isForwarded) ...[
                Padding(
                  padding: const EdgeInsets.only(
                      left: 4, right: 4, top: 2, bottom: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationY(3.14159),
                        child: Icon(
                          Icons.reply_rounded,
                          size: 14,
                          color: (isMe && !noBubble)
                              ? Colors.white70
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Forwarded message',
                          style: TextStyle(
                            color: (isMe && !noBubble)
                                ? Colors.white70
                                : const Color(0xFF475569),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Content (text / image / sticker / video / file)
              _buildContent(),

              const SizedBox(height: 4),

              // Timestamp & status
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: _isMedia ? 6 : 2,
                    bottom: _isMedia ? 2 : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: (isMe && !noBubble)
                              ? Colors.white70
                              : Colors.grey[600],
                          fontSize: 10,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isSeen
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 14,
                          color: message.isSeen
                              ? Colors.lightBlueAccent
                              : (noBubble ? Colors.grey : Colors.white70),
                        ),
                      ],
                    ],
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