import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';

class MyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? profileImageUrl;

  const MyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profileImageUrl,
  });

  static const _items = [
    Iconsax.home_2,
    Iconsax.book_1,
    Iconsax.calendar_tick,
    Iconsax.message_text_1,
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.divider,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < _items.length; i++)
              _NavIcon(
                icon: _items[i],
                isSelected: currentIndex == i,
                onTap: () => onTap(i),
                isDark: isDark,
              ),

            // Profile Button
            GestureDetector(
              onTap: () => onTap(_items.length),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                width: currentIndex == _items.length ? 44 : 38,
                height: currentIndex == _items.length ? 44 : 38,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: currentIndex == _items.length
                      ? AppColors.primaryGradient
                      : null,
                  border: currentIndex == _items.length
                      ? null
                      : Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.divider,
                          width: 1.5,
                        ),
                  boxShadow: currentIndex == _items.length
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.32),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(child: _buildProfileAvatar(context, isDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, bool isDark) {
    if (profileImageUrl == null || profileImageUrl!.trim().isEmpty) {
      return Container(
        color: isDark ? AppColors.darkCard : AppColors.cardSubtle,
        child: Icon(
          Icons.person_rounded,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          size: 20,
        ),
      );
    }

    return Image.network(
      profileImageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: isDark ? AppColors.darkCard : AppColors.cardSubtle,
          child: Icon(
            Icons.person_rounded,
            color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            size: 20,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: isDark ? AppColors.darkCard : AppColors.cardSubtle,
          child: const Center(
            child: SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: isSelected ? 48 : 42,
        height: isSelected ? 48 : 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected ? AppColors.primaryGradient : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            size: isSelected ? 22 : 21,
            color: isSelected
                ? Colors.white
                : (isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}
