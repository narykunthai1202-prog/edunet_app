import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../services/todo_service.dart';
import '../theme/app_colors.dart';
import 'day_todos_screen.dart';

/// A dedicated page listing every upcoming reminder, across every day —
/// unlike the month grid (which only shows one month) or the day page
/// (which only shows one day). This is the "what's coming up" view.
class RemindersScreen extends StatelessWidget {
  final TodoService todoService;

  const RemindersScreen({super.key, required this.todoService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Reminders'),
      ),
      body: StreamBuilder<List<TodoItem>>(
        stream: todoService.watchUpcomingReminders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reminders = snapshot.data ?? [];

          if (reminders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No upcoming reminders.\nTurn on "Remind me" when adding '
                      'a task with a time and it will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            );
          }

          // Group flat list by date so we can show date headers, similar
          // to how a native reminders app groups by day.
          final grouped = <String, List<TodoItem>>{};
          for (final r in reminders) {
            grouped.putIfAbsent(_dateLabel(r.date), () => []).add(r);
          }

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: grouped.entries.expand((entry) {
              return [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                ...entry.value.map((todo) => _ReminderTile(
                      todo: todo,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DayTodosScreen(day: todo.date, todoService: todoService),
                        ),
                      ),
                    )),
              ];
            }).toList(),
          );
        },
      ),
    );
  }

  String _dateLabel(DateTime date) {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final diff = date.difference(todayOnly).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}

class _ReminderTile extends StatelessWidget {
  final TodoItem todo;
  final VoidCallback onTap;

  const _ReminderTile({required this.todo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 10,
        height: 10,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(color: todo.color, shape: BoxShape.circle),
      ),
      title: Text(todo.title),
      subtitle: todo.time != null ? Text(todo.time!) : null,
      trailing: const Icon(Icons.notifications_active, size: 18, color: AppColors.todayCircle),
    );
  }
}
