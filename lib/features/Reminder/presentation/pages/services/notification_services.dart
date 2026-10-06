
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/todo_item.dart';
// import 'package:edunest_app/features/Reminder/presentation/pages/app.dart';
import 'package:flutter_timezone/flutter_timezone.dart';


/// Everything about local push reminders lives here — nothing else in
/// the app touches flutter_local_notifications directly. A screen just
/// calls NotificationService.scheduleForTodo(todo) or .cancelForTodo(id)
/// after saving/deleting a task in Firestore.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  /// Call once at app startup (see main.dart). Sets up the notification
  /// channel, requests permission, and configures the local timezone so
  /// scheduled times fire at the correct wall-clock time on the device.
  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
   final timezone = await FlutterTimezone.getLocalTimezone();
tz.setLocalLocation(tz.getLocation(timezone.identifier));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Android 13+ requires this explicit runtime permission request.
    await _plugin
        .resolvePlatformSpecificImplementation< 
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Schedules (or re-schedules, since the id is stable per todo) a
  /// notification for the given task at its stored `time`. Does nothing
  /// if the task has no reminder enabled or no time set.
  static Future<void> scheduleForTodo(TodoItem todo) async {
    await cancelForTodo(todo);
    if (!todo.shouldScheduleReminder) return;

    final scheduledDate = _resolveScheduledDate(todo);
    if (scheduledDate == null) return; // couldn't parse the time string

    // Don't schedule reminders that are already in the past.
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      todo.notificationId,
      todo.title,
      todo.time != null ? 'Scheduled for ${todo.time}' : 'Task reminder',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'todo_reminders',
          'Task reminders',
          channelDescription: 'Reminders for tasks in your calendar',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelForTodo(TodoItem todo) {
    return _plugin.cancel(todo.notificationId);
  }

  static Future<void> cancelById(String todoId) {
    return _plugin.cancel(todoId.hashCode & 0x7FFFFFFF);
  }

  /// Parses todo.date + todo.time (e.g. "5:30am", "17:30", "9pm") into a
  /// concrete DateTime. Returns null if the time string can't be parsed —
  /// callers should just skip scheduling in that case rather than crash.
  static DateTime? _resolveScheduledDate(TodoItem todo) {
    final raw = todo.time?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) return null;

    final match = RegExp(r'^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?$').firstMatch(raw);
    if (match == null) return null;

    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2) ?? '0');
    final meridiem = match.group(3);

    if (meridiem == 'pm' && hour != 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;

    return DateTime(todo.date.year, todo.date.month, todo.date.day, hour, minute);
  }
}
