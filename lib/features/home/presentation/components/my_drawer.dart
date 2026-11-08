import 'package:edunest_app/core/theme/app_colors.dart';
import 'package:edunest_app/core/theme/app_text_styles.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/archive/presentation/pages/archive_page.dart';
import 'package:edunest_app/core/cubits/theme_cubit.dart';
import 'package:edunest_app/features/faq/presentation/pages/faq_page.dart';
import 'package:edunest_app/features/home/presentation/components/my_drawer_tile.dart';
import 'package:edunest_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:edunest_app/features/post/presentation/pages/post_detail_page.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/profile/presentation/pages/edit_profil_page.dart';
import 'package:edunest_app/features/profile/presentation/pages/saved_resource.dart';
import 'package:edunest_app/features/security_privacy/presentation/pages/security_privacy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  Future<void> _openPage(BuildContext context, Widget page) async {
    Navigator.of(context).pop();
    await Future.delayed(const Duration(milliseconds: 200));

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          final theme = Theme.of(context);
          final isSettingsPage =
              page is FaqPage ||
              page is SecurityPrivacyPage ||
              page is ArchivePage;

          if (!isSettingsPage || theme.brightness == Brightness.dark) {
            return page;
          }

          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                inversePrimary: Colors.black,
                secondary: Colors.black,
              ),
              textTheme: theme.textTheme.apply(
                bodyColor: Colors.black,
                displayColor: Colors.black,
              ),
            ),
            child: page,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.surface,
      elevation: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Brand Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const LinearGradient(
                          colors: [Color(0xFF2E2630), Color(0xFF221C24)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : AppColors.blushGradient,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? AppColors.darkDivider : AppColors.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EduNest',
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Build Bright, Cambodia',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'NAVIGATION',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    MyDrawerTile(
                      icon: Iconsax.edit,
                      title: 'Edit Profile',
                      onTap: () {
                        Navigator.of(context).pop();
                        final currentuser = context
                            .read<ProfileCubit>()
                            .currentUser;
                        if (currentuser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditProfilePage(user: currentuser),
                            ),
                          );
                        }
                      },
                    ),
                    MyDrawerTile(
                      icon: Iconsax.bookmark,
                      title: 'Saved Resources',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await Future.delayed(const Duration(milliseconds: 200));
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SavedResource(
                              onTap: (post) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PostDetailPage(postId: post.id),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    MyDrawerTile(
                      icon: Iconsax.archive,
                      title: 'Archive & Trash',
                      onTap: () => _openPage(context, const ArchivePage()),
                    ),
                    MyDrawerTile(
                      icon: Iconsax.security,
                      title: 'Security & Privacy',
                      onTap: () =>
                          _openPage(context, const SecurityPrivacyPage()),
                    ),
                    MyDrawerTile(
                      icon: Iconsax.info_circle,
                      title: 'Welcome Tour',
                      onTap: () => _openPage(
                        context,
                        OnboardingPage(onFinish: () => Navigator.pop(context)),
                      ),
                    ),

                    // Dark Mode Toggle
                    BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, themeMode) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.cardSubtle,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDark ? AppColors.darkDivider : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.darkPrimary : AppColors.primary).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                themeMode == ThemeMode.dark
                                    ? Iconsax.moon
                                    : Iconsax.sun_1,
                                size: 19,
                                color: isDark ? AppColors.darkPrimary : AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dark Mode',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: themeMode == ThemeMode.dark,
                              activeColor: AppColors.primary,
                              activeTrackColor: AppColors.secondary.withValues(alpha: 0.4),
                              onChanged: (enabled) async {
                                try {
                                  await context.read<ThemeCubit>().setDarkMode(
                                    enabled,
                                  );
                                } catch (error) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not change theme: $error',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    MyDrawerTile(
                      icon: Iconsax.message_question,
                      title: 'Terms & FAQ',
                      onTap: () => _openPage(context, const FaqPage()),
                    ),
                  ],
                ),
              ),

              Divider(
                color: isDark ? AppColors.darkDivider : AppColors.divider,
                height: 16,
              ),

              MyDrawerTile(
                icon: Iconsax.logout,
                title: 'Log Out',
                isDestructive: true,
                onTap: () => context.read<AuthCubit>().logout(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
