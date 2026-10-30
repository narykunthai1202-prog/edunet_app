import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/archive/presentation/pages/archive_page.dart';
import 'package:edunest_app/core/cubits/theme_cubit.dart';
import 'package:edunest_app/features/faq/presentation/pages/faq_page.dart';
import 'package:edunest_app/features/home/presentation/components/my_drawer_tile.dart';
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

    Navigator.push(context, MaterialPageRoute(builder: (context) => page));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.tertiary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(7),
                        child: Image.asset(
                          'images/edunestlogo.png',
                          fit: BoxFit.contain,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EduNest',
                            style: TextStyle(
                              color: colorScheme.inversePrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Your learning space',
                            style: TextStyle(
                              color: colorScheme.secondary,
                              fontSize: 12,
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
                  'MENU',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfilePage(user: currentuser!),
                          ),
                        );
                      },
                    ),
                    MyDrawerTile(
                      icon: Iconsax.bookmark,
                      title: 'Saved Resource',
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
                      title: 'Archive',
                      onTap: () => _openPage(context, const ArchivePage()),
                    ),
                    MyDrawerTile(
                      icon: Iconsax.alarm,
                      title: 'Reminder',
                      onTap: () {},
                    ),
                    MyDrawerTile(
                      icon: Iconsax.security,
                      title: 'Privacy and Security',
                      onTap: () =>
                          _openPage(context, const SecurityPrivacyPage()),
                    ),
                    BlocBuilder<ThemeCubit, ThemeMode>(
                      builder: (context, themeMode) => Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiary.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Icon(
                                themeMode == ThemeMode.dark
                                    ? Iconsax.moon
                                    : Iconsax.sun_1,
                                size: 19,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Dark Mode',
                                style: TextStyle(
                                  color: colorScheme.inversePrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: themeMode == ThemeMode.dark,
                              activeTrackColor: colorScheme.primary,
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
              Divider(color: colorScheme.outline.withValues(alpha: 0.3)),
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
