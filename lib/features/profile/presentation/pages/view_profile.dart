import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/home/presentation/components/my_drawer.dart';
import 'package:edunest_app/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:edunest_app/features/notifications/presentation/pages/notification_page.dart';
import 'package:edunest_app/features/post/presentation/components/my_bubble.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/pages/upload_post_page.dart';
import 'package:edunest_app/features/profile/presentation/components/about_section.dart';
import 'package:edunest_app/features/profile/presentation/components/list_view_posts.dart';
import 'package:edunest_app/features/profile/presentation/components/user_info.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_states.dart';
import 'package:edunest_app/features/profile/presentation/pages/edit_profil_page.dart';
import 'package:edunest_app/features/profile/presentation/pages/follow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class ViewProfile extends StatefulWidget {
  final String uid;
  final VoidCallback? onDrawerOpened;
  final VoidCallback? onDrawerClosed;
  const ViewProfile({
    super.key,
    required this.uid,
    required this.onDrawerOpened,
    required this.onDrawerClosed,
  });

  @override
  State<ViewProfile> createState() => _ViewProfileState();
}

class _ViewProfileState extends State<ViewProfile> {
  //cubits
  late final authcubit = context.read<AuthCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  late final postCubit = context.read<PostCubit>();
  
  //current user
  late AppUser? currentUser = authcubit.currentUser;
  //on started
  int _postCount = 0;
  bool _showPosts = true;
  @override
  void initState() {
    super.initState();

    print("UID: ${widget.uid}");

    profileCubit.fetchUserProfile(widget.uid);

    postCubit.fetchPostsByUserId(widget.uid);
    _loadPostCount();
  }

  Future<void> _loadPostCount() async {
    try {
      final count = await profileCubit.getPostCount(widget.uid);

      if (!mounted) return;

      setState(() {
        _postCount = count;
      });
    } catch (e) {
      print("Error getting post count: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileStates>(
      builder: (context, state) {
        //loaded
        if (state is ProfileLoaded) {
          final user = state.profileUser;
          return Scaffold(
            drawer: const MyDrawer(),

            onDrawerChanged: (isOpened) {
              if (isOpened) {
                widget.onDrawerOpened?.call();
              } else {
                widget.onDrawerClosed?.call();
              }
            },
            body: ListView(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final canPop = Navigator.of(context)
                                        .canPop();
                                    return IconButton(
                                      icon: Icon(
                                        canPop ? Icons.arrow_back : Icons.menu,
                                        size: 28,
                                      ),
                                      onPressed: () {
                                        if (canPop) {
                                          Navigator.of(context).pop();
                                        } else {
                                          Scaffold.of(context).openDrawer();
                                        }
                                      },
                                    );
                                  },
                                ),
                                Row(
                                  children: [
                                    // post BUTTON
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const UploadPostPage(),
                                          ),
                                        );
                                      },
                                      icon: const Icon(
                                        Iconsax.add_circle,
                                        size: 23,
                                      ),
                                    ),

                                    // NOTIFICATION BUTTON
                                    BlocBuilder<
                                      NotificationCubit,
                                      List<dynamic>
                                    >(
                                      builder: (context, notifications) {
                                        final unreadCount = notifications
                                            .where(
                                              (notification) =>
                                                  !notification.isRead,
                                            )
                                            .length;

                                        return Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                final user = context
                                                    .read<ProfileCubit>()
                                                    .currentUser;

                                                if (user == null) return;

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        const NotificationPage(),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(
                                                Iconsax.notification,
                                                size: 23,
                                              ),
                                            ),

                                            // RED NUMBER BADGE
                                            if (unreadCount > 0)
                                              Positioned(
                                                right: 2,
                                                top: 2,
                                                child: Container(
                                                  constraints:
                                                      const BoxConstraints(
                                                        minWidth: 18,
                                                        minHeight: 18,
                                                      ),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.white,
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    unreadCount > 99
                                                        ? '99+'
                                                        : unreadCount
                                                              .toString(),
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          UserInfo(
                            imageUrl: user.profileImageUrl,
                            username: user.name,
                            userbios: user.bio,
                            useremail: user.email,
                            usermajor: user.major,
                            postcount: _postCount,
                            followercount: user.followers.length,
                            followingcount: user.following.length,
                            usernickname: user.nickname,
                            ontapfollower: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FollowPage(
                                  followers: user.followers,
                                  following: user.following,
                                ),
                              ),
                            ),
                            ontapeditprofile: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfilePage(user: user),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            MyBubble(
                              text: 'About',
                              iconData: Iconsax.information,
                              isSelected: !_showPosts,
                              onTap: () {
                                setState(() {
                                  _showPosts = false;
                                });
                              },
                            ),
                            const SizedBox(width: 5),
                            MyBubble(
                              text: 'Posts',
                              iconData: Iconsax.book,
                              isSelected: _showPosts,
                              onTap: () {
                                setState(() {
                                  _showPosts = true;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      _showPosts
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: ListViewPosts(uid: widget.uid),
                            )
                          : AboutSection(user: user),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        //loading
        else if (state is ProfileLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (state is ProfileError) {
          return Scaffold(body: Center(child: Text('Error: ${state.message}')));
        } else {
          // ProfileInitial or anything else
          return const Scaffold(body: Center(child: Text('Initializing...')));
        }
      },
    );
  }
}
