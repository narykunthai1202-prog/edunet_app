import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/message_model.dart';

// 🎨 Sheet colors (edit here to restyle the whole sheet)
const Color _kSheetBg = Color(0xFFE3DDDA); // warm beige-gray (like your feed)
const Color _kCard = Color(0xFFEEE8E7); // soft cream-pink (like your post cards)
const Color _kBadge = Color(0xFFE0BCC4); // dusty rose icon badge
const Color _kPlum = Color(0xFF6B4A5B); // icons + selected emoji
const Color _kTextDark = Color(0xFF3A2A32); // dark plum-brown text
const Color _kMuted = Color(0xFF9A8890); // chevrons / handle
const Color _kDelete = Color(0xFFC2674B); // terracotta (destructive)

class MessageOptionsSheet extends StatefulWidget {
  final MessageModel message;
  final String currentUserId;
  final Function(String emoji) onReactionSelected;
  final VoidCallback onReply;
  final VoidCallback onForward;
  final VoidCallback onDelete;
  final VoidCallback onCopy;
  final VoidCallback onUnsend;

  // NEW (optional, used by the group chat only).
  // If null, the tile is simply not shown, so the 1-to-1 chat is unchanged.
  final VoidCallback? onPin;
  final String pinTitle;
  final VoidCallback? onSeenBy;

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
    this.onPin,
    this.pinTitle = 'Pin message',
    this.onSeenBy,
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        decoration: BoxDecoration(
          color: _kSheetBg.withValues(alpha: 0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
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
                color: _kMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),

            // 2️⃣ Emoji Reaction Capsule
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: _kCard,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
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

            // 3️⃣ Grouped Actions Menu
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                color: _kCard,
                child: Column(
                  children: [
                    _buildOptionTile(
                      icon: Icons.reply_rounded,
                      title: 'Reply',
                      onTap: () {
                        Navigator.pop(context);
                        widget.onReply();
                      },
                    ),
                    if (widget.message.type != 'image' &&
                        !widget.message.isDeleted) ...[
                      _buildDivider(),
                      _buildOptionTile(
                        icon: Icons.copy_rounded,
                        title: 'Copy Text',
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: widget.message.text),
                          );
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text('Copied to clipboard'),
                                ],
                              ),
                              backgroundColor: _kPlum,
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
                      title: 'Forward',
                      onTap: () {
                        Navigator.pop(context);
                        widget.onForward();
                      },
                    ),

                    // NEW: group only - who has seen this message
                    if (widget.onSeenBy != null) ...[
                      _buildDivider(),
                      _buildOptionTile(
                        icon: Icons.done_all_rounded,
                        title: 'Seen by',
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSeenBy!();
                        },
                      ),
                    ],

                    // NEW: group only - pin / unpin (admins)
                    if (widget.onPin != null) ...[
                      _buildDivider(),
                      _buildOptionTile(
                        icon: Icons.push_pin_rounded,
                        title: widget.pinTitle,
                        onTap: () {
                          Navigator.pop(context);
                          widget.onPin!();
                        },
                      ),
                    ],

                    // Delete is available on every message now:
                    // your own = "for me" or "for everyone",
                    // other person's = "for me" only (handled in chat_view).
                    if (!widget.message.isDeleted) ...[
                      _buildDivider(),
                      _buildOptionTile(
                        icon: Icons.delete_outline_rounded,
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
      color: _kMuted.withValues(alpha: 0.25),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final iconColor = isDestructive ? _kDelete : _kPlum;
    final badgeColor = isDestructive
        ? _kDelete.withValues(alpha: 0.15)
        : _kBadge.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDestructive ? _kDelete : _kTextDark,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: _kMuted,
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
                  color: _kBadge.withValues(alpha: 0.8),
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