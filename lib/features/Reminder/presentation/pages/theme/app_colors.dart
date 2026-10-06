import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Colors.white;
  static const Color todayCircle = Color(0xFF3B82F6); // blue
  static const Color sunday = Color(0xFFE04B4B); // red weekday label
  static const Color gridLine = Color(0xFFEFEFEF);
  static const Color outsideMonthText = Color(0xFFD0D0D0);

  static const List<Color> todoPalette = [
    Color(0xFFE8A0BF), // pink
    Color(0xFF9B8FE0), // purple
    Color(0xFF8FC7E8), // light blue
    Color(0xFFF4A0A0), // red / salmon
    Color(0xFFA0D8B3), // green
  ];
}

/// Alias so `todoColorPalette` can be accessed directly without `AppColors.`
const List<Color> todoColorPalette = AppColors.todoPalette;
