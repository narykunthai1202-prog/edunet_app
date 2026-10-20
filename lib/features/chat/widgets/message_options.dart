import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_model.dart';

class MessageOptionsSheet extends StatefulWidget {
  final MessageModel message;
  final String currentUserId;
  final Function(String emoji) onReactionSelected;
  final VoidCallback onReply;
  final VoidCallback onForward;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onUnsend;

  const MessageOptionsSheet({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.onReactionSelected,
    required this.onReply,
    required this.onForward,
    required this.onDelete,
    required this.onCopy,
    required this.onUnsend,
  });

  @override
  State<MessageOptionsSheet> createState() => _MessageOptionsSheetState();
}

class _MessageOptionsSheetState extends State<MessageOptionsSheet> {
  static const List<String> _defaultEmojis = ['❤️', '👍', '😂', '😮', '😢', '🔥'];
  String? _selectedEmoji;

  @override
  void initState() {
    super.initState();
    // Pre-select current user's reaction if it exists
    _selectedEmoji = widget.message.reactions[widget.currentUserId];
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = widget.message.senderId == widget.currentUserId;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1️⃣ Drag Handle
            Container(
              width: 40,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // 2️⃣ Floating Animated Emoji Reaction Capsule
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _defaultEmojis.map((emoji) {
                  final isSelected = _selectedEmoji == emoji;
                  return _EmojiButton(
                    emoji: emoji,
                    isSelected: isSelected,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      widget.onReactionSelected(emoji);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // 3️⃣ Modern Grouped Actions Menu
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: Colors.grey.shade100.withOpacity(0.8),
                child: Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.reply_rounded,
                      color: const Color(0xFF2563EB),
                      title: 'Reply',
                      onTap: () {
                        Navigator.pop(context);
                        widget.onReply();
                      },
                    ),
                    if (widget.message.type != 'image' && !widget.message.isDeleted) ...[
                      _buildDivider(),
                      _buildOptionTile(
                        icon: Icons.copy_rounded,
                        color: const Color(0xFF6366F1),
                        title: 'Copy Text',
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: widget.message.text));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Copied to clipboard'),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                    _buildDivider(),
                    _buildOptionTile(
                      icon: Icons.shortcut_rounded,
                      color: const Color(0xFFF59E0B),
                      title: 'Forward',
                      onTap: () {
                        Navigator.pop(context);
                        widget.onForward();
                      },
                    ),
                    if (isMe && !widget.message.isDeleted) ...[
                      _buildDivider(),
                      _buildOptionTile(
                        icon: Icons.delete_outline_rounded,
                        color: const Color(0xFFEF4444),
                        title: 'Delete Message',
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onDelete();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      endIndent: 16,
      color: Colors.grey.shade300.withOpacity(0.5),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Colors.grey,
        ),
      ),
    );
  }
}

// 🌟 Animated Emoji Button Component
class _EmojiButton extends StatefulWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmojiButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_EmojiButton> createState() => _EmojiButtonState();
}

class _EmojiButtonState extends State<_EmojiButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 1.4 : (widget.isSelected ? 1.25 : 1.0),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: widget.isSelected
              ? BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.15),
                  shape: BoxShape.circle,
                )
              : null,
          child: Text(
            widget.emoji,
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }
}