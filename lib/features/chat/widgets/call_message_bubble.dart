import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

/// Messenger-style call card with a "Call back" button.
/// Use it in your message list when message['type'] == 'call'.
class CallMessageBubble extends StatelessWidget {
  final Map<String, dynamic> data;
  final String myId;

  const CallMessageBubble({super.key, required this.data, required this.myId});

  String _duration(int s) => s < 60 ? '$s sec' : '${s ~/ 60} min';

  @override
  Widget build(BuildContext context) {
    final isVideo = data['isVideo'] == true;
    final seconds = (data['seconds'] as num?)?.toInt() ?? 0;
    final callerId = (data['callerId'] ?? data['senderId'])?.toString();
    final calleeId = data['calleeId']?.toString();
    final isMine = callerId == myId;
    final peerId = isMine ? calleeId : callerId;
    final missed = seconds == 0;

    final title = isVideo ? 'Video call' : 'Audio call';
    final subtitle =
        missed ? (isMine ? 'No answer' : 'Missed call') : _duration(seconds);

    final dark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = dark ? const Color(0xFF303030) : Colors.grey.shade200;
    final textColor = dark ? Colors.white : Colors.black87;
    final subColor = dark ? Colors.white60 : Colors.black54;

    IconData icon;
    if (missed) {
      icon = Icons.call_missed;
    } else if (isVideo) {
      icon = Icons.videocam;
    } else {
      icon = isMine ? Icons.call_made : Icons.call_received;
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 250,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: dark ? Colors.white24 : Colors.black12,
                  child: Icon(
                    icon,
                    color: (missed && !isMine) ? Colors.redAccent : textColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      Text(subtitle,
                          style: TextStyle(color: subColor, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: dark ? Colors.white12 : Colors.black12,
                  foregroundColor: textColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: peerId == null
                    ? null
                    : () {
                        ZegoUIKitPrebuiltCallInvitationService().send(
                          invitees: [ZegoCallUser(peerId, peerId)],
                          isVideoCall: isVideo,
                        );
                      },
                child: const Text('Call back'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}