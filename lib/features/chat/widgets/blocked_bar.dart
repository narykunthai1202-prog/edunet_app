// lib/chat/widgets/blocked_bar.dart
import 'package:flutter/material.dart';

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
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                children: [
                  Text('You blocked $name',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    "You can't message or call this profile unless you unblock them",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _btn('Unblock', Colors.black, onUnblock)),
                      const SizedBox(width: 10),
                      Expanded(child: _btn('Delete', Colors.red, onDelete)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, Color color, VoidCallback onTap) {
    return TextButton(
      style: TextButton.styleFrom(
        backgroundColor: const Color(0xFFF1F4F9),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      child: Text(label,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 15)),
    );
  }
}