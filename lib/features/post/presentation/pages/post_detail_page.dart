import 'package:edunest_app/features/post/domain/entities/post.dart';

import 'package:edunest_app/features/post/presentation/components/post_tile.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final bool onpencomment;
  final bool onopenlikes;
  const PostDetailPage({
    super.key,
    required this.postId,
    this.onpencomment = false,
    this.onopenlikes = false,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  Post? post;
  ProfileUser? currentUser;
  bool isLoading = true;
  late final postCubit = context.read<PostCubit>();
  late final prifleCubit = context.read<ProfileCubit>();

  @override
  void initState() {
    super.initState();

    loadPost();
  }

  Future<void> loadPost() async {
    final result = await context.read<PostCubit>().getPostById(widget.postId);

    if (!mounted) return;

    setState(() {
      post = result;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Iconsax.arrow_left),
        ),

        title: const Text(
          'Post',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : post == null
          ? const Center(
              child: Text(
                'Post not found',
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
              child: PostTile(
                post: post!,
                onDeletePressed: null,
                onopencomment: widget.onpencomment,
                onopenlikes: widget.onopenlikes,
              ),
            ),
    );
  }
}
