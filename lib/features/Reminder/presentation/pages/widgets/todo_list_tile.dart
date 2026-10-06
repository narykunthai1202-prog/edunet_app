import 'package:flutter/material.dart';
import '../models/todo_item.dart';

/// A full-size row for one task, used on DayTodosScreen (as opposed to
/// the tiny TodoChip used inside the month grid). Tap the checkbox to
/// mark done, tap the row to edit, swipe to delete.
class TodoListTile extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onToggleDone;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TodoListTile({
    super.key,
    required this.todo,
    required this.onToggleDone,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade400,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    color: todo.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Checkbox(value: todo.done, onChanged: (_) => onToggleDone()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 15,
                          decoration: todo.done ? TextDecoration.lineThrough : null,
                          color: todo.done ? Colors.grey : Colors.black87,
                        ),
                      ),
                      if (todo.time != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            todo.time!,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
