import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_item.dart';
import '../services/todo_service.dart';
import '../widgets/add_edit_todo_sheet.dart';
import '../widgets/todo_list_tile.dart';
import '../theme/app_colors.dart';

/// Filter options for tasks
enum TaskFilter { all, pending, completed }
/// Sorting options for tasks
enum TaskSort { time, alphabetical, status }

/// Screen displaying and managing tasks for a specific calendar day.
class DayTodosScreen extends StatefulWidget {
  final DateTime day;
  final TodoService todoService;

  const DayTodosScreen({
    super.key,
    required this.day,
    required this.todoService,
  });

  @override
  State<DayTodosScreen> createState() => _DayTodosScreenState();
}

class _DayTodosScreenState extends State<DayTodosScreen> {
  TaskFilter _selectedFilter = TaskFilter.all;
  TaskSort _selectedSort = TaskSort.time;
  String _searchQuery = '';
  bool _isSearchActive = false;
  final TextEditingController _quickAddController = TextEditingController();

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _addTodo(BuildContext context) async {
    final todo = await AddEditTodoSheet.show(context, date: widget.day);
    if (todo != null) await widget.todoService.addTodo(todo);
  }

  Future<void> _quickAdd() async {
    final text = _quickAddController.text.trim();
    if (text.isEmpty) return;

    final newTodo = TodoItem(
      // FIX: use the same uuid scheme as everywhere else in the app
      // (was DateTime.now().millisecondsSinceEpoch.toString(), which can
      // collide if two quick-adds happen in the same millisecond).
      id: const Uuid().v4(),
      title: text,
      date: widget.day,
      color: AppColors.todoPalette.first,
      done: false,
    );

    await widget.todoService.addTodo(newTodo);
    _quickAddController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  Future<void> _editTodo(BuildContext context, TodoItem todo) async {
    final updated = await AddEditTodoSheet.show(
      context,
      date: widget.day,
      existing: todo,
    );
    if (updated != null) await widget.todoService.updateTodo(updated);
  }

  Future<void> _deleteTodo(TodoItem todo) =>
      widget.todoService.deleteTodo(todo.id);

  Future<void> _toggleDone(TodoItem todo) =>
      widget.todoService.toggleDone(todo);

  Future<void> _markAllDone(List<TodoItem> todos) async {
    for (final todo in todos) {
      if (!todo.done) {
        await widget.todoService.toggleDone(todo);
      }
    }
  }

  Future<void> _clearCompleted(List<TodoItem> todos) async {
    final completed = todos.where((t) => t.done).toList();
    for (final todo in completed) {
      await widget.todoService.deleteTodo(todo.id);
    }
  }

  Future<void> _movePendingToTomorrow(List<TodoItem> todos) async {
    final pending = todos.where((t) => !t.done).toList();
    final tomorrow = widget.day.add(const Duration(days: 1));

    for (final todo in pending) {
      final updated = TodoItem(
        id: todo.id,
        title: todo.title,
        date: tomorrow,
        time: todo.time,
        color: todo.color,
        done: false,
        // FIX: preserve hasReminder — previously this defaulted to false,
        // which silently cancelled the reminder every time a task was
        // moved to tomorrow.
        hasReminder: todo.hasReminder,
      );
      await widget.todoService.updateTodo(updated);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pending.length} task(s) moved to tomorrow!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_weekdayName(widget.day.weekday)}, ${_monthName(widget.day.month)} ${widget.day.day}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(context, dateLabel),
      body: StreamBuilder<List<TodoItem>>(
        stream: widget.todoService.watchTodosForDay(widget.day),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allTodos = snapshot.data ?? [];

          // 1. Filter tasks
          var filtered = allTodos.where((todo) {
            if (_selectedFilter == TaskFilter.pending) return !todo.done;
            if (_selectedFilter == TaskFilter.completed) return todo.done;
            return true;
          }).toList();

          // 2. Search query filter
          if (_searchQuery.isNotEmpty) {
            filtered = filtered
                .where((t) =>
                    t.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
          }

          // 3. Sort tasks
          filtered.sort((a, b) {
            switch (_selectedSort) {
              case TaskSort.alphabetical:
                return a.title.toLowerCase().compareTo(b.title.toLowerCase());
              case TaskSort.status:
                return (a.done ? 1 : 0).compareTo(b.done ? 1 : 0);
              case TaskSort.time:
              // ignore: unreachable_switch_default
              default:
                if (a.time == null && b.time == null) return 0;
                if (a.time == null) return 1;
                if (b.time == null) return -1;
                return a.time!.compareTo(b.time!);
            }
          });

          final completedCount = allTodos.where((t) => t.done).length;
          final progress =
              allTodos.isNotEmpty ? completedCount / allTodos.length : 0.0;

          return Column(
            children: [
              // Daily Progress Card Header
              if (allTodos.isNotEmpty)
                _buildProgressHeader(completedCount, allTodos.length, progress),

              // Filter & Sort Control Toolbar
              _buildToolbar(allTodos),

              // Task List
              Expanded(
                child: allTodos.isEmpty
                    ? _buildEmptyState(context)
                    : filtered.isEmpty
                        ? _buildFilteredEmptyState()
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final todo = filtered[index];
                              return _buildDismissibleTask(context, todo);
                            },
                          ),
              ),

              // Quick Inline Add Bar at bottom
              _buildQuickAddBar(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addTodo(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Detailed Task',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, String dateLabel) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      foregroundColor: Colors.black87,
      title: _isSearchActive
          ? TextField(
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search tasks...',
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            )
          : Text(
              dateLabel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
      actions: [
        IconButton(
          icon: Icon(_isSearchActive ? Icons.close : Icons.search),
          tooltip: 'Search',
          onPressed: () {
            setState(() {
              _isSearchActive = !_isSearchActive;
              if (!_isSearchActive) _searchQuery = '';
            });
          },
        ),
        StreamBuilder<List<TodoItem>>(
          stream: widget.todoService.watchTodosForDay(widget.day),
          builder: (context, snapshot) {
            final todos = snapshot.data ?? [];
            return PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More options',
              onSelected: (value) {
                if (value == 'mark_all') _markAllDone(todos);
                if (value == 'move_tomorrow') _movePendingToTomorrow(todos);
                if (value == 'clear_completed') _clearCompleted(todos);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'mark_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.blue, size: 20),
                      SizedBox(width: 10),
                      Text('Mark All Done'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'move_tomorrow',
                  child: Row(
                    children: [
                      Icon(Icons.next_plan_outlined,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 10),
                      Text('Move Pending to Tomorrow'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: Row(
                    children: [
                      Icon(Icons.cleaning_services_outlined,
                          color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text('Clear Completed Tasks'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressHeader(int completed, int total, double progress) {
    final percentage = (progress * 100).toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
              Text(
                '$completed of $total done ($percentage%)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: progress == 1.0 ? Colors.green : Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress == 1.0 ? Colors.green : Colors.blueAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(List<TodoItem> allTodos) {
    final pendingCount = allTodos.where((t) => !t.done).length;
    final completedCount = allTodos.where((t) => t.done).length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChoiceChip(
                    label: 'All (${allTodos.length})',
                    filter: TaskFilter.all,
                  ),
                  const SizedBox(width: 6),
                  _buildChoiceChip(
                    label: 'Pending ($pendingCount)',
                    filter: TaskFilter.pending,
                  ),
                  const SizedBox(width: 6),
                  _buildChoiceChip(
                    label: 'Completed ($completedCount)',
                    filter: TaskFilter.completed,
                  ),
                ],
              ),
            ),
          ),
          // Sort Dropdown Button
          PopupMenuButton<TaskSort>(
            icon: const Icon(Icons.sort, size: 22, color: Colors.black54),
            tooltip: 'Sort tasks',
            onSelected: (sort) => setState(() => _selectedSort = sort),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: TaskSort.time,
                child: Text('Sort by Time'),
              ),
              PopupMenuItem(
                value: TaskSort.alphabetical,
                child: Text('Sort Alphabetically'),
              ),
              PopupMenuItem(
                value: TaskSort.status,
                child: Text('Sort by Status'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required TaskFilter filter}) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      selected: isSelected,
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      elevation: 0,
      pressElevation: 1,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
    );
  }

  Widget _buildDismissibleTask(BuildContext context, TodoItem todo) {
    return Dismissible(
      key: Key(todo.id),
      background: _buildSwipeBackground(
        color: todo.done ? Colors.amber.shade700 : Colors.green.shade600,
        icon: todo.done ? Icons.undo_rounded : Icons.check_circle_rounded,
        alignment: Alignment.centerLeft,
        text: todo.done ? 'Mark Undone' : 'Complete',
      ),
      secondaryBackground: _buildSwipeBackground(
        color: Colors.redAccent,
        icon: Icons.delete_outline_rounded,
        alignment: Alignment.centerRight,
        text: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await _showDeleteConfirmation(context, todo);
        } else {
          await _toggleDone(todo);
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteTodo(todo);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(
              color: todo.color,
              width: 5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TodoListTile(
          todo: todo,
          onToggleDone: () => _toggleDone(todo),
          onTap: () => _editTodo(context, todo),
          onDelete: () => _deleteTodo(todo),
        ),
      ),
    );
  }

  Widget _buildSwipeBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerRight) ...[
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
          ],
          Icon(icon, color: Colors.white, size: 24),
          if (alignment == Alignment.centerLeft) ...[
            const SizedBox(width: 8),
            Text(text,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickAddBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 80, 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _quickAddController,
              decoration: InputDecoration(
                hintText: 'Quick add task...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                fillColor: const Color(0xFFF1F3F5),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _quickAdd(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
            onPressed: _quickAdd,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.task_alt_rounded,
                size: 64,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tasks for this day',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enjoy your free time or add a task using quick add below.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredEmptyState() {
    return Center(
      child: Text(
        'No tasks match your filter/search.',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, TodoItem todo) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[month - 1];
  }
}
