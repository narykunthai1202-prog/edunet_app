import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/todo_item.dart';
import 'notification_services.dart';

/// All Firestore reads/writes for tasks live here.
///
/// Data layout in Firestore:
///   users/{uid}/todos/{todoId}
///
/// IMPORTANT: this reads the uid straight from `FirebaseAuth.instance
/// .currentUser`, NOT from a custom AuthService. This is intentional so
/// this file works with WHATEVER login method your teammate's account
/// system uses (email/password, Google Sign-In, etc.) without needing to
/// know their AuthService's method names — once a user is signed in via
/// any provider, `FirebaseAuth.instance.currentUser` is always available.
///
/// Storing todos underneath each user's own uid is what makes the
/// security rules in firestore.rules simple: "you can only touch
/// documents under your own uid". This also lives happily alongside your
/// teammate's `users/{uid}` profile document (Email/Id/Name/Wallet
/// fields) — the `todos` subcollection never touches those fields.
class TodoService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Throws if called before a real user is signed in. Every screen in
  /// this module already assumes a signed-in user (see app.dart), same
  /// as it would with a custom AuthService.
  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
        'TodoService used before a user is signed in. Make sure this '
        'screen is only shown after your login flow completes.',
      );
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _todosRef =>
      _db.collection('users').doc(_uid).collection('todos');

  /// Live stream of every todo in the given month.
  Stream<List<TodoItem>> watchTodosForMonth(DateTime month) {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 1);

    return _todosRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TodoItem.fromDoc).toList());
  }

  /// Live stream of every todo on one specific day, used by the day
  /// detail page.
  Stream<List<TodoItem>> watchTodosForDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    return _todosRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TodoItem.fromDoc).toList());
  }

  /// Live stream of every upcoming task (today onward) that has a
  /// reminder enabled, sorted chronologically. Used by RemindersScreen.
  ///
  /// NOTE: this query (range filter + equality filter + orderBy) needs a
  /// Firestore COMPOSITE INDEX. The first time you run this, Firestore
  /// will print a console error with a direct link to create it — click
  /// that link once and it'll work from then on.
  Stream<List<TodoItem>> watchUpcomingReminders() {
    final startOfToday = DateTime.now();
    final start = DateTime(startOfToday.year, startOfToday.month, startOfToday.day);

    return _todosRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('hasReminder', isEqualTo: true)
        .orderBy('date')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(TodoItem.fromDoc).toList());
  }

  Future<void> addTodo(TodoItem todo) async {
    await _todosRef.doc(todo.id).set(todo.toMap());
    await NotificationService.scheduleForTodo(todo);
  }

  Future<void> updateTodo(TodoItem todo) async {
    await _todosRef.doc(todo.id).update(todo.toMap());
    await NotificationService.scheduleForTodo(todo);
  }

  Future<void> toggleDone(TodoItem todo) async {
    await _todosRef.doc(todo.id).update({'done': !todo.done});
    // Once a task is marked done there's no need to still remind about it.
    if (!todo.done) await NotificationService.cancelForTodo(todo);
  }

  Future<void> deleteTodo(String todoId) async {
    await _todosRef.doc(todoId).delete();
    await NotificationService.cancelById(todoId);
  }
}
