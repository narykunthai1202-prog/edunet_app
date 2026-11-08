import 'package:flutter/material.dart';

/// The official EduNest design system color palette.
/// A balanced palette of misty rose, eucalyptus, cream, and coffee.
class AppColors {
  AppColors._();

  // Primary & Accent Colors
  static const Color primary = Color(0xFF5F7D6E); // Eucalyptus
  static const Color primaryLight = Color(0xFFDCE7DF); // Pale eucalyptus
  static const Color primaryDark = Color(0xFF486454); // Deep eucalyptus
  static const Color secondary = Color(0xFFF2CFCF); // Misty rose
  static const Color accent = Color(0xFFAA7180); // Muted rose

  // Background & Surface
  static const Color background = Color(0xFFF7F2E8); // Warm cream
  static const Color surface = Color(0xFFFFFCF6); // Soft cream
  static const Color surfaceLight = Color(0xFFEAF0E9); // Eucalyptus tint
  static const Color card = Color(0xFFFFFCF6);
  static const Color cardSubtle = Color(0xFFF2CFCF); // Misty rose

  // Text Colors
  static const Color textPrimary = Color(0xFF443025); // Coffee
  static const Color textSecondary = Color(0xFF705B4B); // Soft coffee
  static const Color textMuted = Color(0xFF927E6C);
  static const Color textLight = Colors.white;

  // Borders & Dividers
  static const Color divider = Color(0xFFE7DDCF);
  static const Color border = Color(0xFFD6C7B5);
  static const Color borderFocused = primary; // Focused border

  // Status & Feedback
  static const Color success = Color(0xFF4CAF50); // Muted green
  static const Color warning = Color(0xFFFFA726); // Soft amber
  static const Color error = Color(0xFFE53935); // Soft red
  static const Color info = Color(0xFF42A5F5); // Soft blue

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, Color(0xFF86A292)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blushGradient = LinearGradient(
    colors: [background, Color(0xFFF2CFCF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [surface, Color(0xFFEAF0E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF282329), Color(0xFF1E1A1E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Dark Mode Palette
  static const Color darkBackground = Color(0xFF2D241D);
  static const Color darkSurface = Color(0xFF382D25);
  static const Color darkCard = Color(0xFF44352B);
  static const Color darkTextPrimary = Color(0xFFF7F2E8);
  static const Color darkTextSecondary = Color(0xFFD1C2B2);
  static const Color darkDivider = Color(0xFF665444);
  static const Color darkPrimary = Color(0xFF9AB7A5);
}
