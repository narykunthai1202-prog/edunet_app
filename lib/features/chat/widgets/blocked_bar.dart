// lib/features/chat/widgets/blocked_bar.dart
// Contains BOTH bars:
//  - BlockedBar   : shown to the person who blocked ("You blocked X")
//  - BlockedByBar : shown to the person who was blocked
import 'package:flutter/material.dart';

// Theme colors (same palette as your profile screen)
const Color _plum = Color(0xFF6B4A5B);
const Color _card = Color(0xFFF7F1F0);
const Color _field = Color(0xFFEBE3E1);
const Color _textDark = Color(0xFF3A2A32);
const Color _muted = Color(0xFF7A6670);
const Color _danger = Color(0xFFC2674B);

/// Rounded card that sits at the bottom of the chat.
class _BlockCard extends StatelessWidget {
  final Widget child;
  const _BlockCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: _plum.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: child,
        ),
      ),
    );
  }
}

/// Round icon badge used in both bars.
class _Badge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _Badge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}

/// Shown to the user who blocked: "You blocked X" + Unblock / Delete.
class BlockedBar extends StatelessWidget {
  final String name;
  final VoidCallback onUnblock;
  final VoidCallback onDelete;

  const BlockedBar({
    super.key,
    required this.name,
    required this.onUnblock,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _BlockCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Badge(icon: Icons.block_rounded, color: _danger),
          const SizedBox(height: 12),
          Text(
            'You blocked $name',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "You can't message or call this profile unless you unblock them",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _btn(
                  label: 'Unblock',
                  icon: Icons.lock_open_rounded,
                  background: _plum,
                  foreground: Colors.white,
                  onTap: onUnblock,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _btn(
                  label: 'Delete',
                  icon: Icons.delete_outline_rounded,
                  background: _field,
                  foreground: _danger,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _btn({
    required String label,
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return TextButton.icon(
      style: TextButton.styleFrom(
        backgroundColor: background,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: foreground, size: 19),
      label: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Shown to the user who has been blocked. No unblock button, and it
/// doesn't reveal who blocked whom.
class BlockedByBar extends StatelessWidget {
  const BlockedByBar({super.key});

  @override
  Widget build(BuildContext context) {
    return _BlockCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _Badge(icon: Icons.lock_outline_rounded, color: _plum),
          SizedBox(height: 12),
          Text(
            "You can't reply to this conversation",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Messages and calls are unavailable right now',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}