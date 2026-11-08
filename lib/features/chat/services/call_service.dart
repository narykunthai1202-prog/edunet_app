
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:zego_uikit_signaling_plugin/zego_uikit_signaling_plugin.dart';

class CallService {
  // From the Zego console (https://console.zegocloud.com)
  static const int _appID =  1321526681;
  static const String _appSign = 'e1d8087b9726d2d5e5c9df59d45f737d5229d52775dff106de803443d47146be'; 

  static bool _started = false;

  /// Call once right after the user logs in (and again on app start if the
  /// user is already logged in). Without this, the call buttons do nothing.
  static Future<void> init({
    required String userId,
    required String userName,
  }) async {
    if (kIsWeb) return; // call invitations are not set up for web here
    if (_started) return;
    try {
      await ZegoUIKitPrebuiltCallInvitationService().init(
        appID: _appID,
        appSign: _appSign,
        userID: userId,
        userName: userName,
        plugins: [ZegoUIKitSignalingPlugin()],
        // Look of the "Calling..." and "Incoming call..." screens
        uiConfig: ZegoCallInvitationUIConfig(
          inviter: ZegoCallInvitationInviterUIConfig(
            backgroundBuilder: (context, size, info) => _gradient(size),
            spacingBetweenAvatarAndName: 18,
            spacingBetweenNameAndCallingText: 8,
            cancelButton: ZegoCallButtonUIConfig(
              size: const Size(76, 76),
              textStyle: _buttonText,
            ),
          ),
          invitee: ZegoCallInvitationInviteeUIConfig(
            backgroundBuilder: (context, size, info) => _gradient(size),
            spacingBetweenAvatarAndName: 18,
            spacingBetweenNameAndCallingText: 8,
            acceptButton: ZegoCallButtonUIConfig(
              size: const Size(76, 76),
              textStyle: _buttonText,
            ),
            declineButton: ZegoCallButtonUIConfig(
              size: const Size(76, 76),
              textStyle: _buttonText,
            ),
          ),
        ),
        // Call screen settings used by the invitation service itself
        // (this replaces the need for a separate CallScreen page).
        requireConfig: (ZegoCallInvitationData data) {
          final isGroup = data.invitees.length > 1;
          final isVideo = data.type == ZegoCallInvitationType.videoCall;
          final config = isGroup
              ? (isVideo
                    ? ZegoUIKitPrebuiltCallConfig.groupVideoCall()
                    : ZegoUIKitPrebuiltCallConfig.groupVoiceCall())
              : (isVideo
                    ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                    : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall());
          // same look while the call is running (voice calls only)
          if (!isVideo) {
            config.audioVideoView.backgroundBuilder =
                (context, size, user, extraInfo) => _gradient(size);
          }
          return config;
        },
        events: ZegoUIKitPrebuiltCallEvents(
          onCallEnd: (ZegoCallEndEvent event, VoidCallback defaultAction) {
            debugPrint(
              'CALL END reason=${event.reason} kicker=${event.kickerUserID}',
            );
            defaultAction.call();
          },
        ),
      );
      _started = true;
    } catch (e) {
      debugPrint('Zego init failed: $e');
    }
  }

  /// Call on logout.
  static Future<void> uninit() async {
    if (!_started) return;
    await ZegoUIKitPrebuiltCallInvitationService().uninit();
    _started = false;
  }

  // ------------------------------------------------------------- styling

  static const _plum = Color(0xFF6B4A5B);
  static const _rose = Color(0xFFE0BCC4);

  static const TextStyle _buttonText = TextStyle(
    color: Colors.white70,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );

  /// Soft plum gradient with two blurred glows, matching the app colours.
  static Widget _gradient(Size size) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3A2A32), Color(0xFF2A1C24), Color(0xFF140D12)],
            ),
          ),
        ),
        Positioned(
          top: -size.width * 0.35,
          left: -size.width * 0.25,
          child: _glow(size.width * 0.9, _plum.withValues(alpha: 0.55)),
        ),
        Positioned(
          bottom: -size.width * 0.4,
          right: -size.width * 0.3,
          child: _glow(size.width * 1.0, _rose.withValues(alpha: 0.22)),
        ),
      ],
    );
  }

  static Widget _glow(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}