import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'group_avatar.dart';
import 'presence.dart';

/// One row of the chat list: flat, clean, with a thin divider.
/// Same constructor as before, so ChatListView does not need extra changes.
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

  static const _blue = Color(0xFF2563EB);
  static const _ink = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);

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

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GroupAvatar(
                        name: displayName, photoUrl: photoUrl, radius: 28),
                    if (peerId != null)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: OnlineBadge(userId: peerId!),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // name + preview
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
                                fontSize: 16,
                                fontWeight: hasUnread
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: _ink,
                              ),
                            ),
                          ),
                          if (isFavorite)
                            const Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Icon(Icons.star_rounded,
                                  size: 16, color: Color(0xFFF59E0B)),
                            ),
                          if (isPinned)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.push_pin_rounded,
                                  size: 14, color: Color(0xFF94A3B8)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              hasUnread ? FontWeight.w600 : FontWeight.w400,
                          color: hasUnread ? _ink : _muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // time + ONE small badge (unread count, otherwise muted bell)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lastMessageTime == null
                          ? ''
                          : _formatTime(lastMessageTime!),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            hasUnread ? FontWeight.w700 : FontWeight.w400,
                        color: hasUnread ? _blue : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (hasUnread)
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMuted ? const Color(0xFF94A3B8) : _blue,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else if (isMuted)
                      const Icon(Icons.notifications_off_rounded,
                          size: 16, color: Color(0xFF94A3B8))
                    else
                      const SizedBox(height: 18),
                  ],
                ),
              ],
            ),
          ),
          // thin divider that starts after the avatar
          const Divider(
            height: 1,
            thickness: 1,
            indent: 90,
            endIndent: 16,
            color: Color(0xFFF1F5F9),
          ),
        ],
      ),
    );
  }
}