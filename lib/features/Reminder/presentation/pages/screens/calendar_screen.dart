import 'package:flutter/material.dart';
import '../models/todo_item.dart';
import '../services/todo_service.dart';
import '../widgets/add_edit_todo_sheet.dart';
import '../widgets/month_grid.dart';
import 'day_todos_screen.dart';
import 'reminders_screen.dart';

/// The home page: a month grid of days with colored task previews.
/// Tapping a day pushes DayTodosScreen (a separate page) for that day.
/// This screen only wires data + navigation together — all the actual
/// grid layout lives in widgets/month_grid.dart and widgets/day_cell.dart.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TodoService _todoService = TodoService();
  final DateTime _today = DateTime.now();
  late DateTime _visibleMonth = DateTime(_today.year, _today.month);

  void _changeMonth(int delta) {
    setState(() => _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta));
  }

  void _openDay(DateTime day) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DayTodosScreen(day: day, todoService: _todoService),
      ),
    );
  }

  /// Quick-add entry point from the calendar's own floating button — lets
  /// someone set a task + reminder for today without drilling into a day
  /// page first. Uses the same sheet (and same time-picker button) as
  /// everywhere else, so behavior stays consistent everywhere.
  Future<void> _quickAddForToday() async {
    final todo = await AddEditTodoSheet.show(context, date: _today);
    if (todo != null) await _todoService.addTodo(todo);
  }

  Future<void> _confirmDelete(TodoItem todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text(todo.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await _todoService.deleteTodo(todo.id);
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(monthLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
        leading: IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changeMonth(-1)),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changeMonth(1)),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Reminders',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RemindersScreen(todoService: _todoService)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<TodoItem>>(
        stream: _todoService.watchTodosForMonth(_visibleMonth),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final todos = snapshot.data ?? [];
          final todosByDay = <String, List<TodoItem>>{};
          for (final t in todos) {
            todosByDay.putIfAbsent(_dayKey(t.date), () => []).add(t);
          }

          return MonthGrid(
            visibleMonth: _visibleMonth,
            today: _today,
            todosByDay: todosByDay,
            onOpenDay: _openDay,
            onEditTodo: (todo) => _openDay(todo.date),
            onDeleteTodo: _confirmDelete,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _quickAddForToday,
        child: const Icon(Icons.add),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return names[month - 1];
  }
}
