import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class MyDrawerTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final void Function()? onTap;
  final bool isDestructive;

  const MyDrawerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color foregroundColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary);

    final Color iconBg = isDestructive
        ? AppColors.error.withValues(alpha: 0.12)
        : (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.12);

    final Color iconColor = isDestructive
        ? AppColors.error
        : (isDark ? AppColors.darkPrimary : AppColors.primary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 19, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: foregroundColor,
                      fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
