import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/notifications/domain/entities/notification.dart';
import 'package:edunest_app/features/notifications/domain/repositories/notification_repo.dart';

class FirebaseNotificationRepo implements NotificationRepo {
  final FirebaseFirestore _firestore;
  FirebaseNotificationRepo({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  final String collectionName = 'notifications';

  @override
  Future<void> createNotification(Notification notification) async {
    try {
      await _firestore
          .collection(collectionName)
          .doc(notification.id)
          .set(notification.toMap(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create or update notification: $e');
    }
  }

  @override
  Stream<List<Notification>> getNotifications(String userId) {
    return _firestore
        .collection(collectionName)
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return Notification.fromMap({...doc.data(), 'id': doc.id});
          }).toList();
        });
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(collectionName).doc(notificationId).update({
      'isRead': true,
    });
  }

  @override
  Future<Notification?> getLikeNotification(
    String postId,
    String senderId,
    String receiverId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('postId', isEqualTo: postId)
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('type', isEqualTo: 'like')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;

      return Notification.fromMap({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get like notification: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection(collectionName).doc(notificationId).delete();
    } catch (e) {
      throw Exception('failed to delete notification: $e');
    }
  }

  @override
  Future<Notification?> getCommentNotification(
    String postId,
    String senderId,
    String receiverId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('postId', isEqualTo: postId)
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('type', isEqualTo: 'comment')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;

      return Notification.fromMap({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get comment notification: $e');
    }
  }

  @override
  Future<Notification?> getfollowNotification(
    String senderId,
    String receiverId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('type', isEqualTo: 'follow')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;

      return Notification.fromMap({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get like notification: $e');
    }
  }

  @override
  Future<Notification?> getSavedNotification(
    String postId,
    String senderId,
    String receiverId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('type', isEqualTo: 'save')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;

      return Notification.fromMap({...doc.data(), 'id': doc.id});
    } catch (e) {
      throw Exception('Failed to get like notification: $e');
    }
  }
}
