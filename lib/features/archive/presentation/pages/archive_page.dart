import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/post/data/firebase_post_repo.dart';
import '../cubits/archive_cubit.dart';
import '../cubits/archive_states.dart';
import '../components/deleted_post_tile.dart';
import '../components/liked_post_tile.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final currentUserId = context.read<AuthCubit>().currentUser?.uid ?? '';
        return ArchiveCubit(postRepo: FirebasePostRepo())
          ..fetchArchive(currentUserId);
      },
      child: const _ArchiveView(),
    );
  }
}

class _ArchiveView extends StatefulWidget {
  const _ArchiveView();

  @override
  State<_ArchiveView> createState() => _ArchiveViewState();
}

class _ArchiveViewState extends State<_ArchiveView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = context.read<AuthCubit>().currentUser;
    final uid = currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.inversePrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Archive',
          style: TextStyle(
            color: colorScheme.inversePrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242227) : colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: colorScheme.secondary,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.trash, size: 16),
                      SizedBox(width: 8),
                      Text('Recently Deleted'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.zero,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Iconsax.heart, size: 16),
                      SizedBox(width: 8),
                      Text('Liked Posts'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: BlocConsumer<ArchiveCubit, ArchiveState>(
        listener: (context, state) {
          if (state is ArchiveActionSuccessState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ArchiveErrorState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ArchiveLoadingState) {
            return Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            );
          }

          if (state is ArchiveErrorState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.warning_2, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.inversePrimary),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        context.read<ArchiveCubit>().fetchArchive(uid),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final deletedPosts = state is ArchiveLoadedState
              ? state.deletedPosts
              : state is ArchiveActionSuccessState
                  ? state.deletedPosts
                  : [];

          final likedPosts = state is ArchiveLoadedState
              ? state.likedPosts
              : state is ArchiveActionSuccessState
                  ? state.likedPosts
                  : [];

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Recently Deleted
              RefreshIndicator(
                color: colorScheme.primary,
                onRefresh: () =>
                    context.read<ArchiveCubit>().fetchArchive(uid),
                child: deletedPosts.isEmpty
                    ? _buildEmptyState(
                        context,
                        icon: Iconsax.trash,
                        title: 'No recently deleted posts',
                        subtitle:
                            'Posts you delete will stay here for up to 30 days before being permanently removed.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: deletedPosts.length,
                        itemBuilder: (context, index) {
                          final post = deletedPosts[index];
                          return DeletedPostTile(
                            key: ValueKey(post.id),
                            post: post,
                            onRestore: () => context
                                .read<ArchiveCubit>()
                                .restorePost(post.id, uid),
                            onPermanentlyDelete: () => context
                                .read<ArchiveCubit>()
                                .permanentlyDeletePost(post.id, uid),
                          );
                        },
                      ),
              ),

              // Tab 2: Liked Posts
              RefreshIndicator(
                color: colorScheme.primary,
                onRefresh: () =>
                    context.read<ArchiveCubit>().fetchArchive(uid),
                child: likedPosts.isEmpty
                    ? _buildEmptyState(
                        context,
                        icon: Iconsax.heart,
                        title: 'No liked posts yet',
                        subtitle:
                            'Posts you react to with Love will appear here in chronological order.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: likedPosts.length,
                        itemBuilder: (context, index) {
                          final post = likedPosts[index];
                          return LikedPostTile(
                            key: ValueKey(post.id),
                            post: post,
                            onUnlike: () => context
                                .read<ArchiveCubit>()
                                .unlikePost(post, uid),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242227) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 36, color: colorScheme.primary),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.secondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
