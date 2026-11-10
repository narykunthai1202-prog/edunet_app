import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class AppWidget {
  static TextStyle boldTextFeildStyle() {
    return AppTextStyles.titleMedium.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle HeadLineTextFeildStyle() {
    return AppTextStyles.displaySmall.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle LightTextFeildStyle() {
    return AppTextStyles.bodyMedium.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w400,
    );
  }

  static TextStyle semiBooldTextFeildStyle() {
    return AppTextStyles.titleSmall.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
  }
}
