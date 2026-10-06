import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'services/notification_services.dart';

// MERGE STEP: 'firebase_options.dart' is NOT included in this package
// because it is machine-generated per Firebase project (contains real API
// keys) and must point at your TEAMMATE's project, not a new one. Run:
//     flutterfire configure
// inside the merged project (choose your teammate's existing Firebase
// project when prompted), then uncomment the two lines below.
//
// import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    // options: DefaultFirebaseOptions.currentPlatform, // <-- uncomment after flutterfire configure
  );

  // No anonymous sign-in here anymore — your teammate's real login screen
  // (wired in app.dart) is responsible for authenticating the user.

  await NotificationService.init();

  runApp(const TodoCalendarApp());
}
