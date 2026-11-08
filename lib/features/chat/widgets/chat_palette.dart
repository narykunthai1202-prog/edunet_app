import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ChatPalette {
  final Color canvas;
  final Color surface;
  final Color rose;
  final Color mauve;
  final Color plum;
  final Color ink;
  final Color muted;
  final Color border;
  final Color unreadSurface;
  final Color onSelected;
  final LinearGradient headerGradient;

  const ChatPalette._({
    required this.canvas,
    required this.surface,
    required this.rose,
    required this.mauve,
    required this.plum,
    required this.ink,
    required this.muted,
    required this.border,
    required this.unreadSurface,
    required this.onSelected,
    required this.headerGradient,
  });

  factory ChatPalette.of(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      return const ChatPalette._(
        canvas: AppColors.darkBackground,
        surface: AppColors.darkCard,
        rose: AppColors.darkPrimary,
        mauve: AppColors.secondary,
        plum: AppColors.darkPrimary,
        ink: AppColors.darkTextPrimary,
        muted: AppColors.darkTextSecondary,
        border: AppColors.darkDivider,
        unreadSurface: Color(0xFF33232A),
        onSelected: Colors.white,
        headerGradient: LinearGradient(
          colors: [Color(0xFF382531), Color(0xFF261A22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }

    return const ChatPalette._(
      canvas: AppColors.background,
      surface: AppColors.surface,
      rose: AppColors.primary,
      mauve: AppColors.secondary,
      plum: AppColors.primaryDark,
      ink: AppColors.textPrimary,
      muted: AppColors.textSecondary,
      border: AppColors.divider,
      unreadSurface: AppColors.cardSubtle,
      onSelected: Colors.white,
      headerGradient: AppColors.primaryGradient,
    );
  }
}
