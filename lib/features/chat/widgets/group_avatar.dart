// lib/chat/widgets/group_avatar.dart
import 'package:flutter/material.dart';

class GroupAvatar extends StatelessWidget {
  final String? photoUrl;
  final String name;
  final double radius;

  const GroupAvatar({
    super.key,
    required this.name,
    this.photoUrl,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE0E7FF),
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: const Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }
}