import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/core/cubits/theme_cubit.dart';
import 'package:edunest_app/features/home/presentation/components/my_drawer_tile.dart';
import 'package:edunest_app/features/post/presentation/pages/post_detail_page.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/profile/presentation/pages/edit_profil_page.dart';
import 'package:edunest_app/features/profile/presentation/pages/saved_resource.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // logo / avatar
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40.0),
                child: Column(
                  children: [
                    Image.asset(
                      'images/edunestlogo.png',
                      width: 500,
                      height: 100,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
              ),

              Divider(color: colorScheme.outline.withValues(alpha: 0.3)),
              const SizedBox(height: 8),

              MyDrawerTile(
                icon: Iconsax.edit,
                title: 'Edit Profile',
                onTap: () {
                  Navigator.of(context).pop();
                  final currentuser = context.read<ProfileCubit>().currentUser;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(user: currentuser!),
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
                onTap: () {},
              ),
              MyDrawerTile(
                icon: Iconsax.alarm,
                title: 'Reminder',
                onTap: () {},
              ),
              MyDrawerTile(
                icon: Iconsax.security,
                title: 'Privacy and Security',
                onTap: () {},
              ),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, themeMode) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: Text(
                    'Dark Mode',
                    style: TextStyle(color: colorScheme.inversePrimary),
                  ),
                  value: themeMode == ThemeMode.dark,
                  onChanged: (enabled) async {
                    try {
                      await context.read<ThemeCubit>().setDarkMode(enabled);
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Could not change theme: $error'),
                        ),
                      );
                    }
                  },
                ),
              ),
              MyDrawerTile(
                icon: Iconsax.message_question,
                title: 'Terms & FAQ',
                onTap: () {},
              ),
              const Spacer(),

              MyDrawerTile(
                icon: Iconsax.logout,
                title: 'Log Out',
                onTap: () => context.read<AuthCubit>().logout(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
