import 'package:edunest_app/features/notifications/domain/entities/notification.dart';

abstract class NotificationRepo {
  Future<void> createNotification(Notification notification);

  Stream<List<Notification>> getNotifications(String userId);

  Future<void> markAsRead(String notificationId);

  Future<Notification?> getLikeNotification(
    String postId,
    String senderId,
    String receiverId,
  );
  Future<Notification?> getCommentNotification(
    String postId,
    String senderId,
    String receiverId,
  );
  Future<Notification?> getfollowNotification(
    String senderId,
    String receiverId,
  );
  Future<Notification?> getSavedNotification(
    String postId,
    String senderId,
    String receiverId,
  );
  Future<void> deleteNotification(String notificationId);
}
