import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// One task, shown as a colored bar in the month grid and as a full
/// row on the day detail page.
class TodoItem {
  final String id;
  final String title;
  final DateTime date; // normalized to y/m/d, no time component
  final String? time; // optional display label, e.g. "5:30am"
  final Color color;
  final bool done;
  final bool hasReminder; // whether a local notification should fire at `time`

  TodoItem({
    required this.id,
    required this.title,
    required this.date,
    required this.color,
    this.time,
    this.done = false,
    this.hasReminder = false,
  });

  /// A stable integer id derived from the string uuid, needed because
  /// flutter_local_notifications requires an int id per scheduled
  /// notification (so we can cancel/reschedule the exact same one).
  int get notificationId => id.hashCode & 0x7FFFFFFF;

  /// True only when there's actually something to schedule: a reminder
  /// was requested AND a time was given.
  bool get shouldScheduleReminder => hasReminder && time != null;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'time': time,
      'color': color.toARGB32(),
      'done': done,
      'hasReminder': hasReminder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TodoItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final ts = (data['date'] as Timestamp).toDate();
    return TodoItem(
      id: doc.id,
      title: data['title'] as String? ?? '',
      date: DateTime(ts.year, ts.month, ts.day),
      time: data['time'] as String?,
      color: Color(data['color'] as int? ?? AppColors.todoPalette.first.toARGB32()),
      done: data['done'] as bool? ?? false,
      hasReminder: data['hasReminder'] as bool? ?? false,
    );
  }

  TodoItem copyWith({
    String? title,
    DateTime? date,
    String? time,
    Color? color,
    bool? done,
    bool? hasReminder,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      date: date ?? this.date,
      time: time ?? this.time,
      color: color ?? this.color,
      done: done ?? this.done,
      hasReminder: hasReminder ?? this.hasReminder,
    );
  }
}
