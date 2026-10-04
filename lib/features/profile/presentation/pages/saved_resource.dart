import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/components/post_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SavedResource extends StatefulWidget {
  final void Function(Post post)? onTap;

  const SavedResource({super.key, this.onTap});

  @override
  State<SavedResource> createState() => _SavedResourceState();
}

class _SavedResourceState extends State<SavedResource> {
  late Future<List<Post>> savedPostsFuture;

  @override
  void initState() {
    super.initState();

    final user = context.read<AuthCubit>().currentUser;

    savedPostsFuture = user == null
        ? Future.value([])
        : context.read<PostCubit>().fetchSavedPosts(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Favorite'), centerTitle: true),
      body: FutureBuilder<List<Post>>(
        future: savedPostsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          if (posts.isEmpty) {
            return const Center(child: Text('No saved posts yet'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];

              return GestureDetector(
                onTap: () {
                  widget.onTap?.call(post);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: PostTile(post: post, onDeletePressed: null),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
