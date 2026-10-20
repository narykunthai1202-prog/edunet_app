import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

const Color _onlineGreen = Color(0xFF22C55E);

/// Reads the "is this user online?" flag from a user document.
/// Understands `isOnline: true`, `online: true` or `status: 'online'`.
bool isUserOnline(Map<String, dynamic>? data) {
  if (data == null) return false;

  final flag = data['isOnline'] ?? data['online'];
  if (flag is bool) return flag;

  final status = data['status'];
  if (status is String) return status.toLowerCase() == 'online';

  return false;
}

/// Live online/offline state of one user (users/{userId}).
Stream<bool> watchUserOnline(String userId) => FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .snapshots()
    .map((snap) => isUserOnline(snap.data()));

/// Small green dot with a white ring. Shows nothing while the user is offline.
/// Put it in the corner of an avatar (inside a Stack).
class OnlineBadge extends StatefulWidget {
  const OnlineBadge({super.key, required this.userId, this.size = 15});

  final String userId;
  final double size;

  @override
  State<OnlineBadge> createState() => _OnlineBadgeState();
}

class _OnlineBadgeState extends State<OnlineBadge> {
  late final Stream<bool> _stream = watchUserOnline(widget.userId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _stream,
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _onlineGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
          ),
        );
      },
    );
  }
}

/// "● Online" (green) or "Offline" (grey) text, for headers.
class PresenceLabel extends StatefulWidget {
  const PresenceLabel({super.key, required this.userId});

  final String userId;

  @override
  State<PresenceLabel> createState() => _PresenceLabelState();
}

class _PresenceLabelState extends State<PresenceLabel> {
  late final Stream<bool> _stream = watchUserOnline(widget.userId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _stream,
      builder: (context, snap) {
        final online = snap.data == true;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (online) ...[
              const CircleAvatar(radius: 4, backgroundColor: _onlineGreen),
              const SizedBox(width: 5),
            ],
            Text(
              online ? 'Online' : 'Offline',
              style: TextStyle(
                fontSize: 12,
                fontWeight: online ? FontWeight.w600 : FontWeight.w400,
                color: online ? _onlineGreen : Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }
}