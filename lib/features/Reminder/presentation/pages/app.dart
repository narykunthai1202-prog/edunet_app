import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'screens/calendar_screen.dart';

// TODO (merge step): replace this import with your teammate's actual
// login screen widget.
// import 'package:your_app/screens/login_screen.dart';

class TodoCalendarApp extends StatelessWidget {
  const TodoCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Todo Calendar',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      // This listens to Firebase Auth directly (not a custom AuthService),
      // so it reacts correctly no matter which sign-in method your
      // teammate's account system uses.
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. Still checking if someone is already logged in.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // 2. Someone is signed in -> show the calendar/todo feature.
          if (snapshot.hasData && snapshot.data != null) {
            return const CalendarScreen();
          }

          // 3. Nobody is signed in.
          //
          // MERGE STEP: this is where your app's real entry point should
          // decide what to show (splash screen, onboarding, or login).
          // For a standalone test of this module, replace the line below
          // with your teammate's LoginScreen():
          //
          //   return const LoginScreen();
          //
          // Left as a placeholder here since that widget isn't part of
          // this package.
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Not signed in.\n\nReplace this with your '
                  "teammate's LoginScreen() in app.dart.",
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
