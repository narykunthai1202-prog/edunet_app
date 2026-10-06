import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../theme/app_colors.dart';
import 'todo_chip.dart';

/// One cell in the month grid: the day number on top, then up to a
/// few colored TodoChips underneath. Tapping anywhere on the cell opens
/// the full day page (handled by the parent via [onOpenDay]).
class DayCell extends StatelessWidget {
  final DateTime day;
  final bool inCurrentMonth;
  final bool isToday;
  final bool isSunday;
  final List<TodoItem> todos;
  final VoidCallback onOpenDay;
  final void Function(TodoItem) onEditTodo;
  final void Function(TodoItem) onDeleteTodo;

  const DayCell({
    super.key,
    required this.day,
    required this.inCurrentMonth,
    required this.isToday,
    required this.isSunday,
    required this.todos,
    required this.onOpenDay,
    required this.onEditTodo,
    required this.onDeleteTodo,
  });

  static const int _maxVisibleChips = 4;

  @override
  Widget build(BuildContext context) {
    final visible = todos.take(_maxVisibleChips).toList();
    final overflowCount = todos.length - visible.length;

    return GestureDetector(
      onTap: onOpenDay,
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.gridLine),
            left: BorderSide(color: AppColors.gridLine),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: _DayNumber(day: day, inCurrentMonth: inCurrentMonth, isToday: isToday, isSunday: isSunday)),
            const SizedBox(height: 4),
            ...visible.map(
              (todo) => TodoChip(
                todo: todo,
                onTap: () => onEditTodo(todo),
                onLongPress: () => onDeleteTodo(todo),
              ),
            ),
            if (overflowCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+$overflowCount more',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayNumber extends StatelessWidget {
  final DateTime day;
  final bool inCurrentMonth;
  final bool isToday;
  final bool isSunday;

  const _DayNumber({
    required this.day,
    required this.inCurrentMonth,
    required this.isToday,
    required this.isSunday,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: isToday
          ? const BoxDecoration(color: AppColors.todayCircle, shape: BoxShape.circle)
          : null,
      child: Text(
        '${day.day}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
          color: isToday
              ? Colors.white
              : !inCurrentMonth
                  ? AppColors.outsideMonthText
                  : isSunday
                      ? AppColors.sunday
                      : Colors.black87,
        ),
      ),
    );
  }
}
