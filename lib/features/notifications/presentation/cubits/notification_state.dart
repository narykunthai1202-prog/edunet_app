abstract class NotificationState {}

class Markallread extends NotificationState {
  final String notificationId;
  Markallread({required this.notificationId});
}
