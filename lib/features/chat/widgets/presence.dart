import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/chat/services/chat_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// 🎨 Presence colors (edit here to restyle online / offline everywhere)
// ---------------------------------------------------------------------------
const Color _onlineDot = Color.fromARGB(255, 15, 196, 66); // soft sage green
const Color _onlineText = Color(0xFF6B4A5B); // warm plum for "Online"
const Color _offlineText = Color(0xFF9A8890); // muted mauve-gray for "Offline"
const Color _badgeRing = Color(0xFFEFE8E7); // ring around the avatar dot

// ---------------------------------------------------------------------------
// READING: is this user online?
// ---------------------------------------------------------------------------

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

/// Small soft-green dot with a ring. Shows nothing while the user is offline.
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
            color: _onlineDot,
            shape: BoxShape.circle,
            border: Border.all(color: _badgeRing, width: 2.5),
          ),
        );
      },
    );
  }
}

/// "● Online" (soft green dot, warm plum text) or "Offline" (muted), for headers.
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
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: _onlineDot,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              online ? 'Online' : 'Offline',
              style: GoogleFonts.nunito(
                fontSize: 12.5,
                fontWeight: online ? FontWeight.w600 : FontWeight.w500,
                color: online ? _onlineText : _offlineText,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// WRITING: keep the signed-in user online while the app is open
// ---------------------------------------------------------------------------

/// Keeps the signed-in user "online" for the WHOLE time the app is open,
/// not only while a chat screen is open.
///
///  - user signs in / app opens   -> online
///  - app comes back to front     -> online
///  - app goes to background,
///    tab hidden, app closed      -> offline
///  - user signs out              -> offline
///
/// Wrap your home screen (the page with the bottom navigation bar) once:
///
///   return AppPresenceTracker(child: Scaffold(...));
class AppPresenceTracker extends StatefulWidget {
  const AppPresenceTracker({super.key, required this.child});

  final Widget child;

  @override
  State<AppPresenceTracker> createState() => _AppPresenceTrackerState();
}

class _AppPresenceTrackerState extends State<AppPresenceTracker>
    with WidgetsBindingObserver {
  final ChatService _service = ChatService();
  StreamSubscription<User?>? _authSub;
  String? _uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Handles the first sign-in AND account switches / sign-outs.
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      final newUid = user?.uid;

      // previous account is no longer using the app
      if (_uid != null && _uid != newUid) {
        _set(_uid!, false);
      }

      _uid = newUid;
      if (newUid != null) _set(newUid, true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final uid = _uid;
    if (uid == null) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _set(uid, true);
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _set(uid, false);
        break;
      case AppLifecycleState.inactive:
        // short interruptions (notification bar, window focus): stay online
        break;
    }
  }

  Future<void> _set(String uid, bool online) async {
    try {
      await _service.updateUserPresence(uid, online);
    } catch (e) {
      debugPrint('Presence update failed: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSub?.cancel();
    final uid = _uid;
    if (uid != null) _set(uid, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}