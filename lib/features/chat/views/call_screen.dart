import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({
    super.key,
    required this.channelId,
    required this.currentUserId,
    required this.currentUserName,
    required this.isVideoCall,
  });

  // Dynamic parameters passed from the active chat/user session
  final String channelId;       // Unique ID for the room or group chat
  final String currentUserId;   // Unique ID of the logged-in user (e.g., user.uid)
  final String currentUserName; // Display name of the logged-in user
  final bool isVideoCall;

  // Replace these with your credentials from https://console.zegocloud.com
  static const int zegoAppId = 1321526681;
  static const String zegoAppSign = 'e1d8087b9726d2d5e5c9df59d45f737d5229d52775dff106de803443d47146be';

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isVideoCall ? 'Video Call' : 'Voice Call'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.phone_disabled, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Calling features are currently supported on mobile devices (Android / iOS).',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Passes dynamic runtime parameters directly to ZegoUIKitPrebuiltCall
    return ZegoUIKitPrebuiltCall(
      appID: zegoAppId,
      appSign: zegoAppSign,
      userID: currentUserId,
      userName: currentUserName,
      callID: channelId,
      config: isVideoCall
          ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
          : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall(),
    );
  }
}