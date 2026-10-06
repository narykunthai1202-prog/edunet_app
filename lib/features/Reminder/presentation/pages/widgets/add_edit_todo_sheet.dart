import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/todo_item.dart';
import '../theme/app_colors.dart';

/// Bottom sheet to create or edit one task for a specific date.
/// Returns the finished TodoItem via Navigator.pop, or null if cancelled.
class AddEditTodoSheet extends StatefulWidget {
  final DateTime date;
  final TodoItem? existing;

  const AddEditTodoSheet({super.key, required this.date, this.existing});

  /// Convenience helper so screens don't repeat the showModalBottomSheet
  /// boilerplate every time.
  static Future<TodoItem?> show(
    BuildContext context, {
    required DateTime date,
    TodoItem? existing,
  }) {
    return showModalBottomSheet<TodoItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditTodoSheet(date: date, existing: existing),
    );
  }

  @override
  State<AddEditTodoSheet> createState() => _AddEditTodoSheetState();
}

class _AddEditTodoSheetState extends State<AddEditTodoSheet> {
  late final TextEditingController _titleController;
  late Color _selectedColor;
  late bool _hasReminder;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existing?.title ?? '');
    _selectedColor = widget.existing?.color ?? AppColors.todoPalette.first;
    _hasReminder = widget.existing?.hasReminder ?? false;
    _selectedTime = _parseTime(widget.existing?.time);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  /// Parses a stored time string like "5:30 PM" or "17:30" back into a
  /// TimeOfDay so the picker opens pre-filled when editing a task.
  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(am|pm)?$', caseSensitive: false)
        .firstMatch(raw.trim());
    if (match == null) return null;
    int hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final meridiem = match.group(3)?.toLowerCase();
    if (meridiem == 'pm' && hour != 12) hour += 12;
    if (meridiem == 'am' && hour == 12) hour = 0;
    if (hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Formats a TimeOfDay as "5:30 PM" — a consistent 12-hour format that
  /// NotificationService's parser understands regardless of the device's
  /// locale/24-hour setting.
  String _formatTime(TimeOfDay time) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour12:$minute $period';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppColors.todayCircle,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _hasReminder = true; // picking a time is a strong signal they want a reminder
      });
    }
  }

  void _clearTime() {
    setState(() {
      _selectedTime = null;
      _hasReminder = false;
    });
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final todo = TodoItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      title: title,
      date: widget.date,
      time: _selectedTime != null ? _formatTime(_selectedTime!) : null,
      color: _selectedColor,
      done: widget.existing?.done ?? false,
      hasReminder: _hasReminder && _selectedTime != null,
    );
    Navigator.of(context).pop(todo);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -6))],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(isEditing ? 'Edit task' : 'New task',
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Task title',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 14),

            // --- The time picker button ---
            _TimePickerButton(
              time: _selectedTime,
              formattedTime: _selectedTime != null ? _formatTime(_selectedTime!) : null,
              onTap: _pickTime,
              onClear: _clearTime,
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              child: _selectedTime == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ReminderSwitchCard(
                        enabled: _hasReminder,
                        time: _formatTime(_selectedTime!),
                        onChanged: (value) => setState(() => _hasReminder = value),
                      ),
                    ),
            ),

            const SizedBox(height: 18),
            const Text('Color', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 10),
            Row(
              children: AppColors.todoPalette.map((color) {
                final selected = color.toARGB32() == _selectedColor.toARGB32();
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: selected ? 36 : 30,
                      height: selected ? 36 : 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected ? Border.all(color: Colors.black87, width: 2.5) : null,
                        boxShadow: selected
                            ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8)]
                            : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.todayCircle,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _save,
                child: Text(
                  isEditing ? 'Save changes' : 'Add task',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The polished "time" button itself: a rounded, tappable pill that opens
/// the native time picker. Shows a clock icon + "Add time" when empty, or
/// the chosen time with a small clear (x) button once one is picked.
class _TimePickerButton extends StatelessWidget {
  final TimeOfDay? time;
  final String? formattedTime;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _TimePickerButton({
    required this.time,
    required this.formattedTime,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasTime = time != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: hasTime ? AppColors.todayCircle.withValues(alpha: 0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasTime ? AppColors.todayCircle.withValues(alpha: 0.35) : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 20,
              color: hasTime ? AppColors.todayCircle : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasTime ? formattedTime! : 'Add a time',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasTime ? FontWeight.w600 : FontWeight.w400,
                  color: hasTime ? Colors.black87 : Colors.grey.shade600,
                ),
              ),
            ),
            if (hasTime)
              InkWell(
                onTap: onClear,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded, size: 18, color: Colors.grey.shade500),
                ),
              )
            else
              Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

/// Small card that appears once a time is picked, letting the person
/// confirm whether they actually want a push notification at that time.
class _ReminderSwitchCard extends StatelessWidget {
  final bool enabled;
  final String time;
  final ValueChanged<bool> onChanged;

  const _ReminderSwitchCard({
    required this.enabled,
    required this.time,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
            size: 18,
            color: enabled ? AppColors.todayCircle : Colors.grey.shade400,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              enabled ? 'Remind me at $time' : 'No reminder notification',
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: AppColors.todayCircle,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
