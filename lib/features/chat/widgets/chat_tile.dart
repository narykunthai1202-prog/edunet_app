import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'chat_palette.dart';
import 'group_avatar.dart';
import 'presence.dart';

/// A rounded chat row with profile, latest message, and unread state.
class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.displayName,
    this.photoUrl,
    required this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isFavorite = false,
    this.isMuted = false,
    this.peerId, // the other person (null for groups) -> shows the green dot
    required this.onTap,
    this.onLongPress,
  });

  final String displayName;
  final String? photoUrl;
  final String lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final bool isPinned;
  final bool isFavorite;
  final bool isMuted;
  final String? peerId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Today -> 9:09 PM, yesterday -> Yesterday, this year -> Oct 6,
  /// older -> Oct 6, 2025
  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;

    if (diff == 0) return DateFormat('h:mm a').format(t);
    if (diff == 1) return 'Yesterday';
    if (t.year == now.year) return DateFormat('MMM d').format(t);
    return DateFormat('MMM d, y').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = unreadCount > 0;

    return Material(
      color: hasUnread ? ChatPalette.unreadSurface : ChatPalette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasUnread ? ChatPalette.rose : ChatPalette.border,
            ),
          ),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  GroupAvatar(
                    name: displayName,
                    photoUrl: photoUrl,
                    radius: 27,
                  ),
                  if (peerId != null)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: OnlineBadge(userId: peerId!, size: 14),
                    ),
                ],
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                              color: ChatPalette.ink,
                            ),
                          ),
                        ),
                        if (isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(left: 5),
                            child: Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        if (isPinned)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.push_pin_rounded,
                              size: 13,
                              color: ChatPalette.mauve,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: hasUnread
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: hasUnread
                            ? ChatPalette.ink
                            : ChatPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lastMessageTime == null
                        ? ''
                        : _formatTime(lastMessageTime!),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                      color: hasUnread
                          ? ChatPalette.plum
                          : ChatPalette.muted,
                    ),
                  ),
                  const SizedBox(height: 7),
                  if (hasUnread)
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isMuted
                            ? ChatPalette.mauve
                            : ChatPalette.plum,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else if (isMuted)
                    const Icon(
                      Icons.notifications_off_rounded,
                      size: 15,
                      color: ChatPalette.mauve,
                    )
                  else
                    const SizedBox(height: 16),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
