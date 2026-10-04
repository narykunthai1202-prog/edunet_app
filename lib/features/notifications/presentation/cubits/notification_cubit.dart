import 'dart:async';

import 'package:edunest_app/features/notifications/data/repositories/firebase_notification_repo.dart';
import 'package:edunest_app/features/notifications/domain/entities/notification.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NotificationCubit extends Cubit<List<Notification>> {
  final FirebaseNotificationRepo notificationRepo;

  StreamSubscription<List<Notification>>? _subscription;

  NotificationCubit({required this.notificationRepo}) : super([]);

  // Fetch notifications for the current user
  void fetchNotifications(String userId) {
    // Cancel previous user's stream first
    _subscription?.cancel();
    _subscription = null;

    // Clear old user's notifications
    emit([]);

    // Listen to the new user's notifications
    _subscription = notificationRepo.getNotifications(userId).listen((
      notifications,
    ) {
      if (!isClosed) {
        emit(notifications);
      }
    });
  }

  // Clear notifications and STOP the current stream
  Future<void> clearNotifications() async {
    await _subscription?.cancel();
    _subscription = null;

    if (!isClosed) {
      emit([]);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    await notificationRepo.markAsRead(notificationId);

    emit(
      state.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }

        return notification;
      }).toList(),
    );
  }

  Future<void> markAllAsRead() async {
    final unreadNotifications = state
        .where((notification) => !notification.isRead)
        .toList();

    for (final notification in unreadNotifications) {
      await notificationRepo.markAsRead(notification.id);
    }

    emit(
      state.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList(),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;

    return super.close();
  }
}
