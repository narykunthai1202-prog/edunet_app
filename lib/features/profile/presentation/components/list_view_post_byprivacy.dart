import 'package:edunest_app/features/post/presentation/components/post_tile.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListViewPostByprivacy extends StatefulWidget {
  final String uid;
  final String? viewerUid;
  final VoidCallback? onOwnProfileTap;

  const ListViewPostByprivacy({
    super.key,
    required this.uid,
    this.onOwnProfileTap,
    this.viewerUid,
  });

  @override
  State<ListViewPostByprivacy> createState() =>
      _ListViewPostByprivacyState();
}

class _ListViewPostByprivacyState extends State<ListViewPostByprivacy> {
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final posts = await context.read<PostCubit>().getVisiblePostsByUserId(
        widget.uid,
        widget.viewerUid,
      );

      if (!mounted) return;

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _posts = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_posts.isEmpty) {
      return const Center(
        child: Text('No Posts Yet'),
      );
    }

    return ListView.builder(
      itemCount: _posts.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: (context, index) {
        final post = _posts[index];

        return PostTile(
          post: post,
          onDeletePressed: () {
            context.read<PostCubit>().deletePost(post.id);

            setState(() {
              _posts.removeWhere((p) => p.id == post.id);
            });
          },
        );
      },
    );
  }
}