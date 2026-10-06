import 'package:flutter/material.dart';
import '../models/todo_item.dart';

/// The little colored bar you see stacked under a day number in the
/// month grid. Tapping it edits the task; long-pressing deletes it.
class TodoChip extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const TodoChip({
    super.key,
    required this.todo,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: todo.color.withValues(alpha: 0.18),
          border: Border(left: BorderSide(color: todo.color, width: 3)),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(3),
            bottomRight: Radius.circular(3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            todo.time != null ? '${todo.time} ${todo.title}' : todo.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.black87,
              decoration: todo.done ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }
}
