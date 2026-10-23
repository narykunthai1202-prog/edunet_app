// lib/chat/widgets/group_avatar.dart
import 'package:flutter/material.dart';

import 'chat_palette.dart';

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
      backgroundColor: ChatPalette.rose.withValues(alpha: 0.35),
      backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
      child: hasPhoto
          ? null
          : Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: ChatPalette.plum,
                fontWeight: FontWeight.bold,
                fontSize: radius * 0.8,
              ),
            ),
    );
  }
}