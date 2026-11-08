
import 'package:edunest_app/app.dart';
import 'package:edunest_app/core/cubits/theme_cubit.dart';
import 'package:edunest_app/features/chat/services/zego_service.dart'; // NEW
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'config/firebase_options.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:edunest_app/features/onboarding/presentation/pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // NEW: starts call invitations (Zego) for the signed-in user
  ZegoCallManager.setup();

  final initialThemeMode = await ThemeCubit.loadSavedThemeMode();
  final prefs = await SharedPreferences.getInstance();
  final bool seenOnboarding = prefs.getBool(OnboardingPage.prefKey) ?? false;

  runApp(MyApp(
    initialThemeMode: initialThemeMode,
    seenOnboarding: seenOnboarding,
  ));
}
