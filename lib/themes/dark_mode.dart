import 'package:flutter/material.dart';

final ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF211F23),
    primary: Color(0xFFD3B8C9),
    secondary: Color(0xFFB8AAB3),
    tertiary: Color(0xFF343137),
    inversePrimary: Color(0xFFF2E8EE),
  ),
  scaffoldBackgroundColor: const Color(0xFF171619),
  canvasColor: const Color(0xFF171619),
  cardColor: const Color(0xFF2B282D),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF171619),
    foregroundColor: Color(0xFFF2E8EE),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: Color(0xFF211F23),
    modalBackgroundColor: Color(0xFF211F23),
  ),
  dialogTheme: const DialogThemeData(
    backgroundColor: Color(0xFF2B282D),
    titleTextStyle: TextStyle(
      color: Color(0xFFF2E8EE),
      fontSize: 20,
      fontWeight: FontWeight.w500,
    ),
    contentTextStyle: TextStyle(color: Color(0xFFD4CDD2), fontSize: 16),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    hintStyle: TextStyle(color: Color(0xFFB9AFB7)),
    labelStyle: TextStyle(color: Color(0xFFD4CDD2)),
  ),
  iconTheme: const IconThemeData(color: Color(0xFFF2E8EE)),
  dividerTheme: const DividerThemeData(color: Color(0xFF49454B)),
);
