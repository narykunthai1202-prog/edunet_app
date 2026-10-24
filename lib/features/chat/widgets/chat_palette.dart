import 'package:flutter/material.dart';

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
    final colors = Theme.of(context).colorScheme;
    if (Theme.of(context).brightness == Brightness.dark) {
      return ChatPalette._(
        canvas: colors.surface,
        surface: colors.surfaceContainerHighest,
        rose: colors.primary,
        mauve: colors.secondary,
        plum: colors.primary,
        ink: colors.onSurface,
        muted: colors.onSurfaceVariant,
        border: colors.outlineVariant,
        unreadSurface: colors.secondaryContainer,
        onSelected: colors.onPrimary,
        headerGradient: const LinearGradient(
          colors: [Color(0xFF49323F), Color(0xFF403842), Color(0xFF35313A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      );
    }

    return const ChatPalette._(
      canvas: Color(0xFFE5DFDE),
      surface: Color(0xFFEFE9E9),
      rose: Color(0xFFDDABB4),
      mauve: Color(0xFFA79D9D),
      plum: Color(0xFF5C3A4D),
      ink: Color(0xFF33282E),
      muted: Color(0xFF796E73),
      border: Color(0xFFD8CECF),
      unreadSurface: Color(0xFFF3E5E8),
      onSelected: Colors.white,
      headerGradient: LinearGradient(
        colors: [Color(0xFF5C3A4D), Color(0xFF806573), Color(0xFFA78E91)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }
}
