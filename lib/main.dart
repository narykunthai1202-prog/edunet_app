import 'package:edunest_app/app.dart';
import 'package:edunest_app/core/cubits/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final initialThemeMode = await ThemeCubit.loadSavedThemeMode();
  runApp(MyApp(initialThemeMode: initialThemeMode));
}
