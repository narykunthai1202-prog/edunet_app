import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// A soft pastel gradient background that matches the modern iOS-inspired EduNest theme.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool showFloatingOrbs;

  const GradientBackground({
    super.key,
    required this.child,
    this.showFloatingOrbs = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        // Base subtle gradient
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isDark
                ? const LinearGradient(
                    colors: [AppColors.darkBackground, AppColors.darkSurface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : AppColors.blushGradient,
          ),
        ),

        // Optional decorative soft glowing orbs for subtle glass depth
        if (showFloatingOrbs && !isDark) ...[
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.secondary.withValues(alpha: 0.22),
                    AppColors.secondary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 240,
            left: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryLight.withValues(alpha: 0.15),
                    AppColors.primaryLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Content
        child,
      ],
    );
  }
}
