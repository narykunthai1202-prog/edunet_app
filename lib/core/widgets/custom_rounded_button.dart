import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum ButtonVariant { primary, secondary, outlined, ghost }

class CustomRoundedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const CustomRoundedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 54,
    this.borderRadius = 27,
    this.padding,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget childWidget = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                icon!,
                const SizedBox(width: 8),
              ],
              Text(
                text,
                style: AppTextStyles.button.copyWith(
                  color: _getTextColor(isDark),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

    Decoration decoration;
    if (variant == ButtonVariant.primary) {
      decoration = BoxDecoration(
        gradient: onPressed == null
            ? null
            : AppColors.primaryGradient,
        color: onPressed == null
            ? (isDark ? Colors.white12 : Colors.grey.shade300)
            : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.28),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      );
    } else if (variant == ButtonVariant.secondary) {
      decoration = BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.cardSubtle,
        borderRadius: BorderRadius.circular(borderRadius),
      );
    } else if (variant == ButtonVariant.outlined) {
      decoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark ? AppColors.darkPrimary : AppColors.primary,
          width: 1.4,
        ),
      );
    } else {
      decoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: childWidget),
          ),
        ),
      ),
    );
  }

  Color _getTextColor(bool isDark) {
    if (onPressed == null) {
      return isDark ? Colors.white38 : Colors.grey.shade500;
    }
    switch (variant) {
      case ButtonVariant.primary:
        return Colors.white;
      case ButtonVariant.secondary:
        return isDark ? AppColors.darkTextPrimary : AppColors.primary;
      case ButtonVariant.outlined:
        return isDark ? AppColors.darkPrimary : AppColors.primary;
      case ButtonVariant.ghost:
        return isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    }
  }
}
