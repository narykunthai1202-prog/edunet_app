import 'package:edunest_app/features/post/presentation/components/post_tile.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListViewPostByprivacy extends StatefulWidget {
  final String uid;
  final String? viewerUid;
  final VoidCallback? onOwnProfileTap;


  const ListViewPostByprivacy({super.key, required this.uid, this.onOwnProfileTap, this.viewerUid });

  @override
  State<ListViewPostByprivacy> createState() => _ListViewPostByprivacyState();
}

class _ListViewPostByprivacyState extends State<ListViewPostByprivacy> {

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      context.read<PostCubit>().getVisiblePostsByUserId(widget.uid, widget.viewerUid);
    });
  }

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
