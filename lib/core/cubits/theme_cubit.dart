import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  static const _darkModeKey = 'dark_mode_enabled';

  ThemeCubit(super.initialState);

  static Future<ThemeMode> loadSavedThemeMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_darkModeKey) ?? false
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> setDarkMode(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_darkModeKey, enabled);
    if (!saved) {
      throw StateError('Could not save the selected theme.');
    }

    emit(enabled ? ThemeMode.dark : ThemeMode.light);
  }
}
