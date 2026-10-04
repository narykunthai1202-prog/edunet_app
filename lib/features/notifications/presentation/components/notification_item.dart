import 'package:edunest_app/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:edunest_app/features/post/presentation/pages/post_detail_page.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:edunest_app/features/profile/presentation/pages/other_view_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationItem extends StatelessWidget {
  final dynamic notification;

  const NotificationItem({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final bool isUnread = !notification.isRead;
    return GestureDetector(
      onTap: () async {
        // Mark notification as read
        if (!notification.isRead) {
          try {
            await context.read<NotificationCubit>().markAsRead(notification.id);
          } catch (e) {
            debugPrint('Failed to mark notification as read: $e');
          }
        }

        // Open the related page
        if (context.mounted) {
          _openNotificationPage(context);
        }
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFFFF7F8) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? const Color(0xFFF3E1E4) : const Color(0xFFF4F4F4),
            width: 0.8,
          ),
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleProfile(
              imageurl: notification.senderProfileImageurl ?? '',
              size: 28,
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF3D3033),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: Color(0xFF75686B),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    _notificationTime(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFAAA0A2),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            if (isUnread)
              Container(
                margin: const EdgeInsets.only(top: 5, right: 2),
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFC58F9A),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openNotificationPage(BuildContext context) {
    switch (notification.type) {
      case 'like':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostDetailPage(postId: notification.postId, onopenlikes: true),
          ),
        );
        break;
      case 'comment':
        // Open the post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostDetailPage(postId: notification.postId, onpencomment: true),
          ),
        );
        break;

      case 'follow':
        // Open sender's profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherViewProfile(uid: notification.senderId),
          ),
        );
        break;
      case 'save':
        // Open the post
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailPage(postId: notification.postId),
          ),
        );
        break;

      default:
        // Do nothing if notification has no destination
        break;
    }
  }

  String _notificationTime(dynamic createdAt) {
    if (createdAt == null) {
      return '';
    }

    try {
      DateTime time;

      if (createdAt is DateTime) {
        time = createdAt;
      } else {
        time = createdAt.toDate();
      }

      final now = DateTime.now();
      final difference = now.difference(time);

      if (difference.inSeconds < 60) {
        return 'Just now';
      }

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      }

      if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      }

      if (difference.inDays == 1) {
        return 'Yesterday';
      }

      if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      }

      return '${time.day}/${time.month}/${time.year}';
    } catch (e) {
      return '';
    }
  }
}
