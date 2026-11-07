import 'package:flutter/material.dart';

import '../models/todo_item.dart';
import '../services/todo_service.dart';
import '../widgets/add_edit_todo_sheet.dart';
import '../widgets/month_grid.dart';
import 'day_todos_screen.dart';
import 'reminders_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TodoService _todoService = TodoService();

  final DateTime _today = DateTime.now();

  late DateTime _visibleMonth = DateTime(_today.year, _today.month);

  late DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _today;
  }

  // Change month with left / right chevrons
  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(
        _visibleMonth.year,
        _visibleMonth.month + delta,
      );
      if (_visibleMonth.year == _today.year &&
          _visibleMonth.month == _today.month) {
        _selectedDay = _today;
      }
    });
  }

  // Open selected day tasks view
  void _openDay(DateTime day) {
    setState(() {
      _selectedDay = day;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DayTodosScreen(
          day: day,
          todoService: _todoService,
        ),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  // Create task for selected day (or today)
  Future<void> _quickAdd() async {
    final targetDate = _selectedDay ?? _today;
    final todo = await AddEditTodoSheet.show(
      context,
      date: targetDate,
    );

    if (todo != null) {
      await _todoService.addTodo(todo);
    }
  }

  // Confirm delete task
  Future<void> _confirmDelete(TodoItem todo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Delete task?'),
        content: Text(todo.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _todoService.deleteTodo(todo.id);
    }
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

  String _monthName(int month) {
    const names = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return names[month - 1];
  }

  // 1. TOP HEADER: Month & Year + Prev / Next / Reminders bell
  Widget _buildHeader() {
    final monthLabel =
        '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeMonth(-1),
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFF1E232C),
            iconSize: 26,
            splashRadius: 20,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                monthLabel,
                key: ValueKey(monthLabel),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E232C),
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeMonth(1),
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFF1E232C),
            iconSize: 26,
            splashRadius: 20,
          ),
          IconButton(
            tooltip: 'Reminders',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RemindersScreen(
                    todoService: _todoService,
                  ),
                ),
              );
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1E232C),
              size: 24,
            ),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  // 2. WEEKDAY HEADER ROW: Sun (red), Mon, Tue, Wed, Thu, Fri, Sat in a rounded pill
  Widget _buildWeekdayHeader() {
    const labels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(7, (i) {
          final isSunday = i == 0;
          return Expanded(
            child: Text(
              labels[i],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSunday
                    ? const Color(0xFFE53935)
                    : const Color(0xFF1E232C),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 3. MAIN CALENDAR CARD: 6 rows x 7 days with subtle grid lines
  Widget _buildCalendarCard(Map<String, List<TodoItem>> todosByDay) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: MonthGrid(
        visibleMonth: _visibleMonth,
        today: _today,
        selectedDay: _selectedDay,
        todosByDay: todosByDay,
        onSelectDay: (day) {
          setState(() {
            _selectedDay = day;
          });
        },
        onOpenDay: _openDay,
        onEditTodo: (todo) => _openDay(todo.date),
        onDeleteTodo: _confirmDelete,
      ),
    );
  }

  // 4. FLOATING CREATE BUTTON: Circular muted rosy taupe button with plus icon
  Widget _buildCreateButton() {
    return SizedBox(
      width: 56,
      height: 56,
      child: FloatingActionButton(
        heroTag: 'calendar_create_button',
        onPressed: _quickAdd,
        elevation: 4,
        backgroundColor: const Color(0xFF9E8E8E),
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),

      // MAIN CONTENT
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // 1. Top Month Header
                _buildHeader(),

                // 2. Weekday Pill Card
                _buildWeekdayHeader(),

                // 3. Calendar Grid Card
                Expanded(
                  child: StreamBuilder<List<TodoItem>>(
                    stream: _todoService.watchTodosForMonth(_visibleMonth),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                          ),
                        );
                      }

                      final todos = snapshot.data ?? [];
                      final todosByDay = <String, List<TodoItem>>{};

                      for (final todo in todos) {
                        todosByDay
                            .putIfAbsent(_dayKey(todo.date), () => [])
                            .add(todo);
                      }

                      return _buildCalendarCard(todosByDay);
                    },
                  ),
                ),

                // Space for the app's floating bottom navigation bar
                const SizedBox(height: 84),
              ],
            ),

            // Floating Action Button overlapping the calendar's bottom right
            // and floating comfortably above the bottom navigation bar
            Positioned(
              right: 22,
              bottom: 80,
              child: _buildCreateButton(),
            ),
          ],
        ),
      ),
    );
  }
}
