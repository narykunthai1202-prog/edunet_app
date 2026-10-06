import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../theme/app_colors.dart';
import 'day_cell.dart';

const List<String> weekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/// Renders the weekday header row plus the 6-week grid of days for one
/// month. Purely presentational — all data and navigation come from the
/// parent (CalendarScreen) through callbacks.
class MonthGrid extends StatelessWidget {
  final DateTime visibleMonth;
  final DateTime today;
  final Map<String, List<TodoItem>> todosByDay;
  final void Function(DateTime day) onOpenDay;
  final void Function(TodoItem todo) onEditTodo;
  final void Function(TodoItem todo) onDeleteTodo;

  const MonthGrid({
    super.key,
    required this.visibleMonth,
    required this.today,
    required this.todosByDay,
    required this.onOpenDay,
    required this.onEditTodo,
    required this.onDeleteTodo,
  });

  /// 42 cells (6 weeks x 7 days), including the trailing/leading days of
  /// neighboring months, so every week row is always full.
  List<DateTime> _buildGridDays() {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final firstWeekday = firstOfMonth.weekday % 7; // Sunday = 0
    final gridStart = firstOfMonth.subtract(Duration(days: firstWeekday));
    return List.generate(42, (i) => gridStart.add(Duration(days: i)));
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final gridDays = _buildGridDays();

    return Column(
      children: [
        _WeekdayHeaderRow(),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: List.generate(6, (week) {
                final weekDays = gridDays.sublist(week * 7, week * 7 + 7);
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: weekDays.asMap().entries.map((entry) {
                      final index = entry.key;
                      final day = entry.value;
                      return Expanded(
                        child: DayCell(
                          day: day,
                          inCurrentMonth: day.month == visibleMonth.month,
                          isToday: _isSameDay(day, today),
                          isSunday: index == 0,
                          todos: todosByDay[_dayKey(day)] ?? [],
                          onOpenDay: () => onOpenDay(day),
                          onEditTodo: onEditTodo,
                          onDeleteTodo: onDeleteTodo,
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(7, (i) {
          final isSunday = i == 0;
          return Expanded(
            child: Center(
              child: Text(
                weekdayLabels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSunday ? AppColors.sunday : Colors.grey.shade600,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
