import 'package:flutter/material.dart';

class ChatCategoryChips extends StatelessWidget {
  const ChatCategoryChips({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Chip(
            label: const Text('All'),
            backgroundColor: const Color(0xFF2563EB), // Electric Blue
            labelStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: const Text('Unread 1'),
            backgroundColor: const Color(0xFFF1F5F9),
            labelStyle: const TextStyle(color: Colors.blueGrey),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(width: 8),
          Chip(
            label: const Text('Favorites 4'),
            backgroundColor: const Color(0xFFF1F5F9),
            labelStyle: const TextStyle(color: Colors.blueGrey),
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}