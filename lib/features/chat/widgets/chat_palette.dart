import 'package:flutter/material.dart';

abstract final class ChatPalette {
  static const canvas = Color(0xFFE5DFDE);
  static const surface = Color(0xFFEFE9E9);
  static const rose = Color(0xFFDDABB4);
  static const mauve = Color(0xFFA79D9D);
  static const plum = Color(0xFF5C3A4D);
  static const ink = Color(0xFF33282E);
  static const muted = Color(0xFF796E73);
  static const border = Color(0xFFD8CECF);
  static const unreadSurface = Color(0xFFF3E5E8);

  static const headerGradient = LinearGradient(
    colors: [Color(0xFF5C3A4D), Color(0xFF806573), Color(0xFFA78E91)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
