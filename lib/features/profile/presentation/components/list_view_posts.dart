import 'package:edunest_app/features/post/presentation/components/post_tile.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListViewPosts extends StatefulWidget {
  final String uid;
  final VoidCallback? onOwnProfileTap;

  const ListViewPosts({super.key, required this.uid, this.onOwnProfileTap});

  @override
  State<ListViewPosts> createState() => _ListViewPostsState();
}

class _ListViewPostsState extends State<ListViewPosts> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCubit, PostState>(
      builder: (context, state) {
        if (state is PostLoadedState) {
          final userPosts = state.posts
              .where((post) => post.userId == widget.uid)
              .toList();

          if (userPosts.isEmpty) {
            return const Center(child: Text('No Posts Yet'));
          }

          return ListView.builder(
            itemCount: userPosts.length,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final post = userPosts[index];

              return PostTile(
                post: post,

                onDeletePressed: () {
                  context.read<PostCubit>().deletePost(post.id);
                },
              );
            },
          );
        } else if (state is PostLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else {
          return const Center(child: Text('No Posts'));
        }
      },
    );
  }
}
