import 'package:flutter/material.dart';
import 'screens/calendar_screen.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({super.key});

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  @override
  Widget build(BuildContext context) {
    return const CalendarScreen(); // បង្ហាញផ្ទាំង Todo List / Calendar
  }
}