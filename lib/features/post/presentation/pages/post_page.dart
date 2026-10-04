import 'package:edunest_app/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:edunest_app/features/notifications/presentation/pages/notification_page.dart';
import 'package:edunest_app/features/post/presentation/components/post_tab_bar.dart';
import 'package:edunest_app/features/post/presentation/components/post_tile.dart';
import 'package:edunest_app/features/post/presentation/components/post_bar.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_states.dart';
import 'package:edunest_app/features/post/presentation/pages/upload_post_page.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/search/presentation/pages/search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});
  @override
  State<PostPage> createState() => _PostPageState();
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyTabBarDelegate({required this.child, this.height = 60});

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context)
          .scaffoldBackgroundColor, // avoid transparent overlap
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}

class _PostPageState extends State<PostPage> {
  //post cubit
  late final postCubit = context.read<PostCubit>();
  int selectedTap = 0;
  
  //on started
  @override
  void initState() {
    super.initState();
    fetchforyou();
    selectedTap = 0;
  }

  void fetchforyou() {
    final user = context.read<ProfileCubit>().currentUser;
    if (user == null) return;
    postCubit.fetchAllPostsbypublic();
  }

  void fetchfollowing() {
    final user = context.read<ProfileCubit>().currentUser;
    if (user == null) return;
    postCubit.fetchAllPostsbyfollowing(user.uid);
  }

  void fetchallposts() {
    postCubit.fetchAllPosts();
  }

  //delete post
  Future<void> deletePost(String postId) async {
    await postCubit.deletePost(postId);

    if (selectedTap == 0) {
      fetchforyou();
    } else {
      fetchfollowing();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
          child: CustomScrollView(
            slivers: [
              // Header + search bar — this scrolls away
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Row(
                          children: [
                            Image.asset(
                              'images/edunestlogo.png',
                              width: 150,
                              height: 60,
                              color: const Color.fromARGB(255, 69, 48, 42),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // SEARCH BUTTON
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SearchPage(),
                                  ),
                                );
                              },
                              icon: const Icon(Iconsax.search_normal, size: 23),
                            ),

                            // NOTIFICATION BUTTON
                            BlocBuilder<NotificationCubit, List<dynamic>>(
                              builder: (context, notifications) {
                                final unreadCount = notifications
                                    .where(
                                      (notification) => !notification.isRead,
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
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
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
                                                : unreadCount.toString(),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
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

                    MySearchBar(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UploadPostPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Sticky "For you" / "Following" bar — this stays pinned
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  height: 65,
                  child: PostTabBar(
                    selectedTab: selectedTap,
                    onTabSelected: (tab) {
                      if (selectedTap == tab) return;

                      setState(() {
                        selectedTap = tab;
                      });

                      if (tab == 0) {
                        fetchforyou();
                      } else {
                        fetchfollowing();
                      }
                    },
                  ),
                ),
              ),

              // Posts list
              BlocBuilder<PostCubit, PostState>(
                builder: (context, state) {
                  if (state is PostLoadingState) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is PostLoadedState) {
                    final allPosts = state.posts;

                    if (allPosts.isEmpty) {
                      return const SliverFillRemaining(
                        child: Center(child: Text('No posts available.')),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final post = allPosts[index];
                        return PostTile(
                          post: post,
                          onDeletePressed: () => deletePost(post.id),
                        );
                      }, childCount: allPosts.length),
                    );
                  }

                  if (state is PostErrorState) {
                    return SliverFillRemaining(
                      child: Center(child: Text(state.message)),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
