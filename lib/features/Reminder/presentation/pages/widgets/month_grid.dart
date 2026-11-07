import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import 'day_cell.dart';

const List<String> weekdayLabels = [
  'Sun',
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
];

/// Renders the calendar grid showing ONLY the days of [visibleMonth].
/// Days outside the month are left blank and non-interactive.
/// When days have todos, they show as a list of chips inside the cell.
/// The grid can scroll down smoothly to accommodate days with multiple tasks.
class MonthGrid extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime today;
  final DateTime? selectedDay;
  final Map<String, List<TodoItem>> todosByDay;
  final void Function(DateTime day) onOpenDay;
  final void Function(DateTime day)? onSelectDay;
  final void Function(TodoItem todo)? onEditTodo;
  final void Function(TodoItem todo)? onDeleteTodo;

  const MonthGrid({
    super.key,
    required this.visibleMonth,
    required this.today,
    this.selectedDay,
    required this.todosByDay,
    required this.onOpenDay,
    this.onSelectDay,
    this.onEditTodo,
    this.onDeleteTodo,
  });

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  /// Builds a list of weeks, where each week has 7 slots.
  /// Slots outside [visibleMonth] are null.
  /// Only returns weeks that contain at least one day in [visibleMonth].
  List<List<DateTime?>> _buildGridWeeks() {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final firstWeekday = firstOfMonth.weekday % 7; // Sunday = 0, Monday = 1, ...
    final totalDays = _daysInMonth(visibleMonth);

    final totalSlots = firstWeekday + totalDays;
    final totalWeeks = (totalSlots / 7).ceil();

    final weeks = <List<DateTime?>>[];
    int currentDay = 1;

    for (int w = 0; w < totalWeeks; w++) {
      final week = <DateTime?>[];
      for (int d = 0; d < 7; d++) {
        final slotIndex = w * 7 + d;
        if (slotIndex < firstWeekday || currentDay > totalDays) {
          week.add(null);
        } else {
          week.add(DateTime(visibleMonth.year, visibleMonth.month, currentDay));
          currentDay++;
        }
      }
      weeks.add(week);
    }

    return weeks;
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final weeks = _buildGridWeeks();
    const gridLineColor = Color(0xFFEFF0F4);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: List.generate(weeks.length, (rowIndex) {
          final week = weeks[rowIndex];
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(7, (colIndex) {
                final day = week[colIndex];

                if (day == null) {
                  return Expanded(
                    child: DayCell(
                      day: null,
                      onOpenDay: () {},
                      border: Border(
                        right: colIndex < 6
                            ? const BorderSide(color: gridLineColor, width: 1.0)
                            : BorderSide.none,
                        bottom: rowIndex < weeks.length - 1
                            ? const BorderSide(color: gridLineColor, width: 1.0)
                            : BorderSide.none,
                      ),
                    ),
                  );
                }

                final isTodayDay = _isSameDay(day, today);
                final isSelectedDay = selectedDay != null
                    ? _isSameDay(day, selectedDay!)
                    : isTodayDay;
                final isSunday = colIndex == 0;
                final dayTodos = todosByDay[_dayKey(day)] ?? [];

                return Expanded(
                  child: DayCell(
                    day: day,
                    isSelected: isSelectedDay,
                    isToday: isTodayDay,
                    isSunday: isSunday,
                    todos: dayTodos,
                    border: Border(
                      right: colIndex < 6
                          ? const BorderSide(color: gridLineColor, width: 1.0)
                          : BorderSide.none,
                      bottom: rowIndex < weeks.length - 1
                          ? const BorderSide(color: gridLineColor, width: 1.0)
                          : BorderSide.none,
                    ),
                    onOpenDay: () {
                      if (onSelectDay != null) {
                        onSelectDay!(day);
                      }
                      onOpenDay(day);
                    },
                    onEditTodo: onEditTodo,
                    onDeleteTodo: onDeleteTodo,
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }
}
