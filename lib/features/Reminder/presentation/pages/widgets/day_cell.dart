import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import 'todo_chip.dart';

/// One cell in the month grid:
/// - If [day] is null, renders an empty cell with grid borders (days outside the current month).
/// - If [day] is present:
///   - Centered day number.
///   - Red for Sunday.
///   - Dark charcoal for weekdays/Saturday.
///   - Vibrant solid blue circle with white bold text when selected.
///   - List of colored [TodoChip]s underneath for any tasks/reminders on that day.
class DayCell extends StatelessWidget {
  final DateTime? day;
  final bool isSelected;
  final bool isToday;
  final bool isSunday;
  final List<TodoItem> todos;
  final VoidCallback onOpenDay;
  final void Function(TodoItem todo)? onEditTodo;
  final void Function(TodoItem todo)? onDeleteTodo;
  final Border border;

  const DayCell({
    super.key,
    this.day,
    this.isSelected = false,
    this.isToday = false,
    this.isSunday = false,
    this.todos = const [],
    required this.onOpenDay,
    this.onEditTodo,
    this.onDeleteTodo,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return Container(
        constraints: const BoxConstraints(minHeight: 90),
        decoration: BoxDecoration(
          border: border,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpenDay,
      child: Container(
        constraints: const BoxConstraints(minHeight: 90),
        padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 5),
        decoration: BoxDecoration(
          border: border,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _buildDayNumber()),
            if (todos.isNotEmpty) ...[
              const SizedBox(height: 3),
              ...todos.map(
                (todo) => TodoChip(
                  todo: todo,
                  onTap: () => onEditTodo != null ? onEditTodo!(todo) : onOpenDay(),
                  onLongPress: () => onDeleteTodo != null ? onDeleteTodo!(todo) : null,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDayNumber() {
    final currentDay = day!;

    if (isSelected) {
      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: Color(0xFF1E75E8), // Solid blue circle matching mockup
          shape: BoxShape.circle,
        ),
        child: Text(
          '${currentDay.day}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    final Color textColor = isSunday
        ? const Color(0xFFE53935) // Clean red for Sunday
        : const Color(0xFF1E232C); // Dark charcoal for weekdays

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      child: Text(
        '${currentDay.day}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
