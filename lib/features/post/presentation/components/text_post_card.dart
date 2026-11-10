
import 'package:edunest_app/core/theme/app_colors.dart';
import 'package:edunest_app/core/theme/app_text_styles.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TextPostCard extends StatelessWidget {
  final String username;
  final String? profileImageUrl;
  final String text;
  final Widget? textContent;
  final String timestamp;
  final VoidCallback? onlike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final Widget? trailing;
  final bool isLiked;
  final String likecount;
  final String commentcount;
  final VoidCallback? onprofiletap;
  final bool isSaved;
  final String savedcount;
  final String privacy;

  const TextPostCard({
    super.key,
    required this.username,
    required this.text,
    this.textContent,
    required this.timestamp,
    this.profileImageUrl,
    this.onlike,
    required this.isLiked,
    this.onComment,
    this.onSave,
    this.onShare,
    this.onMore,
    this.trailing,
    required this.likecount,
    required this.commentcount,
    this.onprofiletap,
    required this.isSaved,
    required this.savedcount,
    required this.privacy,
  });

  @override
  Widget build(BuildContext context) {
    final isDark =
        Theme.of(context).brightness == Brightness.dark;

    final primaryText = isDark
        ? AppColors.darkTextPrimary
        : AppColors.textPrimary;

    final secondaryText = isDark
        ? AppColors.darkTextSecondary
        : AppColors.textSecondary;

    final dividerColor = isDark
        ? AppColors.darkDivider
        : AppColors.divider;

    final cardColor = isDark
        ? AppColors.darkCard
        : AppColors.surface;

    final privacyIcon = switch (privacy) {
      'Public' => Iconsax.global,
      'Friend' => Iconsax.people,
      _ => Iconsax.lock,
    };

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dividerColor,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: isDark ? 0.18 : 0.035,
            ),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onprofiletap,
                  child: Row(
                    children: [
                      CircleProfile(
                        imageurl: profileImageUrl ?? '',
                        size: 25,
                      ),
                      const SizedBox(width: 10),

                      Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: primaryText,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),

                          Row(
                            children: [
                              Text(
                                timestamp,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: secondaryText,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.circle,
                                size: 3,
                                color: secondaryText,
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                privacyIcon,
                                size: 12,
                                color: secondaryText,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
          ),

          // Post content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
            child: textContent ??
                Text(
                  text,
                  textAlign: TextAlign.start,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: primaryText,
                  ),
                ),
          ),

          // Divider
          Divider(
            color: dividerColor,
            height: 1,
            thickness: 0.7,
          ),

          // Action bar
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            child: Row(
              children: [
                // Like
                _PostAction(
                  icon: isLiked
                      ? Iconsax.heart5
                      : Iconsax.heart,
                  count: likecount,
                  color: isLiked
                      ? AppColors.accent
                      : secondaryText,
                  textColor: isLiked
                      ? AppColors.accent
                      : primaryText,
                  onTap: onlike,
                ),

                const SizedBox(width: 14),

                // Comment
                _PostAction(
                  icon: Iconsax.message,
                  count: commentcount,
                  color: secondaryText,
                  textColor: primaryText,
                  onTap: onComment,
                ),

                const SizedBox(width: 14),

                // Save
                _PostAction(
                  icon: isSaved
                      ? Iconsax.bookmark5
                      : Iconsax.bookmark,
                  count: savedcount,
                  color: isSaved
                      ? AppColors.primary
                      : secondaryText,
                  textColor: isSaved
                      ? AppColors.primary
                      : primaryText,
                  onTap: onSave,
                ),

                const Spacer(),

                // Share
                GestureDetector(
                  onTap: onShare,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Iconsax.send_2,
                      size: 19,
                      color: secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostAction extends StatelessWidget {
  final IconData icon;
  final String count;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _PostAction({
    required this.icon,
    required this.count,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 3,
          vertical: 5,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: color,
            ),
            const SizedBox(width: 5),
            Text(
              count,
              style: AppTextStyles.labelSmall.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}