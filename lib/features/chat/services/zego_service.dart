
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

import 'chat_service.dart';

/// Give THIS key to your MaterialApp:  MaterialApp(navigatorKey: navigatorKey, ...)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const int kZegoAppID = 1321526681;

// Either run with:  flutter run --dart-define=ZEGO_APP_SIGN=your_sign
// or paste your AppSign as the defaultValue below (keep it private,
// never upload it to GitHub).
const String kZegoAppSign = String.fromEnvironment(
  'ZEGO_APP_SIGN',
  defaultValue: 'e1d8087b9726d2d5e5c9df59d45f737d5229d52775dff106de803443d47146be',
);

/// Details of the call that is in progress.
class ActiveCall {
  static String? peerId; // the other user
  static bool iAmInviter = false;
  static bool isVideo = false;
  static DateTime? startedAt; // when the call page opened
}

/// Saves a "call" message in the chat using your normal ChatService.
Future<void> saveCallMessage({
  required String myId,
  required String peerId,
  required int seconds,
  required bool isVideo,
}) async {
  try {
    final kind = isVideo ? 'Video' : 'Voice';
    final String text;
    if (seconds <= 0) {
      text = 'Missed ${kind.toLowerCase()} call';
    } else if (seconds < 60) {
      text = '$kind call • $seconds sec';
    } else {
      text = '$kind call • ${seconds ~/ 60} min';
    }
    await ChatService().sendMessage(myId, peerId, text, type: 'call');
  } catch (e) {
    debugPrint('saveCallMessage error: $e');
  }
}

class ZegoCallManager {
  static StreamSubscription<User?>? _sub;
  static String? _initedFor;

  /// Call ONCE in main(), right after Firebase.initializeApp().
  /// It starts Zego when a user is signed in and stops it on sign-out.
  static void setup() {
    if (kIsWeb) return; // Zego call invitations are mobile only
    ZegoUIKitPrebuiltCallInvitationService().setNavigatorKey(navigatorKey);

    _sub?.cancel();
    _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        if (_initedFor != null) {
          _initedFor = null;
          try {
            await ZegoUIKitPrebuiltCallInvitationService().uninit();
          } catch (e) {
            debugPrint('Zego uninit error: $e');
          }
        }
        return;
      }
      if (_initedFor == user.uid) return;
      _initedFor = user.uid;
      await _start(user);
    });
  }

  static Future<void> _start(User user) async {
    if (kZegoAppSign.isEmpty) {
      debugPrint(
        'Zego skipped: ZEGO_APP_SIGN is empty. Paste it as defaultValue '
        'in zego_service.dart or run with --dart-define=ZEGO_APP_SIGN=...',
      );
      return;
    }

    // show the real name in the call screen, not the long user id
    var name = user.uid;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final n = doc.data()?['name']?.toString().trim();
      if (n != null && n.isNotEmpty) name = n;
    } catch (_) {}

    final userId = user.uid;
    try {
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: kZegoAppID,
        appSign: kZegoAppSign,
        userID: userId,
        userName: name,
        plugins: [ZegoUIKitSignalingPlugin()], // <- this was missing
        events: ZegoUIKitPrebuiltCallEvents(
          onError: (e) => debugPrint('Zego call error: $e'),
          onCallEnd: (event, defaultAction) async {
            final seconds = ActiveCall.startedAt == null
                ? 0
                : DateTime.now().difference(ActiveCall.startedAt!).inSeconds;
            debugPrint(
              'Zego call ended, reason: ${event.reason}, seconds: $seconds',
            );

            // Only the caller writes, so you don't get two messages.
            if (ActiveCall.iAmInviter && ActiveCall.peerId != null) {
              await saveCallMessage(
                myId: userId,
                peerId: ActiveCall.peerId!,
                seconds: seconds,
                isVideo: ActiveCall.isVideo,
              );
            }
            ActiveCall.startedAt = null;
            defaultAction.call();
          },
        ),
        requireConfig: (ZegoCallInvitationData data) {
          ActiveCall.iAmInviter = data.inviter?.id == userId;
          ActiveCall.peerId = ActiveCall.iAmInviter
              ? (data.invitees.isNotEmpty ? data.invitees.first.id : null)
              : data.inviter?.id;
          ActiveCall.isVideo = data.type == ZegoCallInvitationType.videoCall;
          ActiveCall.startedAt = DateTime.now();

          final isGroup = data.invitees.length > 1;
          final isVideo = data.type == ZegoCallInvitationType.videoCall;
          if (isGroup) {
            return isVideo
                ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                : ZegoUIKitPrebuiltCallConfig.groupVoiceCall();
          }
          return isVideo
              ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
              : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();
        },
      );
      debugPrint('Zego init OK for $userId');
    } catch (e) {
      _initedFor = null; // allow a retry
      debugPrint('Zego init error: $e');
    }
  }
}