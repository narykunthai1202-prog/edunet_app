import 'dart:io';

import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/post/domain/entities/comment.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';
import 'package:edunest_app/features/post/presentation/components/comment_bottom_sheet.dart';
import 'package:edunest_app/features/post/presentation/components/image_post_card.dart';
import 'package:edunest_app/features/post/presentation/components/likes_bottom_sheet.dart';
import 'package:edunest_app/features/post/presentation/components/options_menu.dart';
import 'package:edunest_app/features/post/presentation/components/report_dialog.dart';
import 'package:edunest_app/features/post/presentation/components/text_post_card.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/report_cubit.dart';
import 'package:edunest_app/features/post/presentation/pages/edit_post_page.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/profile/presentation/pages/other_view_profile.dart';
import 'package:edunest_app/features/profile/presentation/pages/view_profile.dart';
import 'package:edunest_app/helper/helper_method.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class PostTile extends StatefulWidget {
  final Post post;
  final VoidCallback? onDeletePressed;
  final bool onopencomment;
  final bool onopenlikes;

  const PostTile({
    super.key,
    required this.post,
    required this.onDeletePressed,
    this.onopencomment = false,
    this.onopenlikes = false,
  });

  @override
  State<PostTile> createState() => _PostTileState();
}

class _PostTileState extends State<PostTile> {
  //cubit
  late final postCubit = context.read<PostCubit>();
  late final profileCubit = context.read<ProfileCubit>();
  bool isOwnPost = false;
  bool isSaved = false;
  // ignore: unused_field
  bool _showBottomNav = true;
  //currentuser
  AppUser? currentUser;
  //post user
  ProfileUser? postuser;
  ProfileUser? currentUserProfile;

  @override
  void initState() {
    super.initState();
    getcurrentUser();
    fetchPostUser();
    checkSavedPosts();

    if (widget.onopencomment) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showComments();
        }
      });
    }

    if (widget.onopenlikes) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showlikes();
        }
      });
    }
  }

  Future<void> checkSavedPosts() async {
    if (currentUser == null) return;
    final saved = await postCubit.isPostSaved(widget.post.id, currentUser!.uid);
    if (!mounted) return;
    setState(() {
      isSaved = saved;
    });
  }

  //saved state
  Future<void> toggleSavePost() async {
    if (currentUser == null) return;

    final uid = currentUser!.uid;
    final oldValue = isSaved;
    final wasSaved = widget.post.savedBy.contains(uid);

    setState(() {
      isSaved = !isSaved;
      if (wasSaved) {
        widget.post.savedBy.remove(uid);
      } else {
        widget.post.savedBy.add(uid);
      }
    });

    try {
      await postCubit.toggleSavedPosts(widget.post, widget.post.id, uid);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isSaved = oldValue;
        if (wasSaved) {
          widget.post.savedBy.add(uid);
        } else {
          widget.post.savedBy.remove(uid);
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Failed to save post')));
    }
  }

  void getcurrentUser() {
    final authCubit = context.read<AuthCubit>();

    currentUser = authCubit.currentUser;

    isOwnPost = widget.post.userId == currentUser?.uid;

    if (currentUser != null) {
      fetchCurrentUserProfile();
    }
  }

  Future<void> fetchCurrentUserProfile() async {
    if (currentUser == null) return;

    final profile = await profileCubit.getUserProfile(currentUser!.uid);

    if (!mounted) return;

    setState(() {
      currentUserProfile = profile;
    });
  }

  Future<void> fetchPostUser() async {
    final fetchUser = await profileCubit.getUserProfile(widget.post.userId);
    if (!mounted) return;
    if (fetchUser != null) {
      setState(() {
        postuser = fetchUser;
      });
    }
  }

  void togglelikePost() {
    if (currentUser == null) return;
    final uid = currentUser!.uid;
    final isLiked =
        currentUser != null && widget.post.likes.contains(currentUser!.uid);

    // Perform an optimistic UI update so the heart toggles color immediately
    setState(() {
      if (widget.post.likes.contains(uid)) {
        widget.post.likes.remove(uid);
      } else {
        widget.post.likes.add(uid);
      }
    });

    // Fire state update to backend/cubit
    postCubit.toggleLikePost(widget.post, uid).catchError((error) {
      setState(() {
        if (isLiked) {
          widget.post.likes.add(currentUser!.uid);
        } else {
          widget.post.likes.remove(currentUser!.uid);
        }
      });
    });
  }

  //show options for delete
  void showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        actions: [
          //cancel
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          //delete
          TextButton(
            onPressed: () {
              widget.onDeletePressed?.call();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  final commentTextControllet = TextEditingController();

  //open comment box -> user wants to type new comment
  void showComments() {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return CommentBottomSheet(
        postId: widget.post.id,
        comments: widget.post.comments,
        userprofileimg: currentUserProfile?.profileImageUrl,
        onSubmit: addComment,
        on_comment_profile_tap: onCommentProfileTap,
      );
    },
  );
}

  void showlikes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return LikesBottomSheet(userIds: widget.post.likes);
      },
    );
  }
void onprofiletap() {
  final currentuser = context.read<AuthCubit>().currentUser;

  if (currentuser?.uid == widget.post.userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfile(
          uid: widget.post.userId,
          onDrawerOpened: () {
            setState(() {
              _showBottomNav = false;
            });
          },
          onDrawerClosed: () {
            setState(() {
              _showBottomNav = true;
            });
          },
        ),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherViewProfile(
          uid: widget.post.userId,
        ),
      ),
    );
  }
}
void onCommentProfileTap(String userId) {
  final currentuser = context.read<AuthCubit>().currentUser;

  if (currentuser?.uid == userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewProfile(
          uid: userId,
          onDrawerOpened: () {
            setState(() {
              _showBottomNav = false;
            });
          },
          onDrawerClosed: () {
            setState(() {
              _showBottomNav = true;
            });
          },
        ),
      ),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherViewProfile(
          uid: userId,
        ),
      ),
    );
  }
}

  Future<Comment?> addComment(String text, File? image) async {
    if (currentUser == null) {
      return null;
    }

    if (text.trim().isEmpty && image == null) {
      return null;
    }

    final newComment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      postId: widget.post.id,
      userId: currentUser!.uid,
      userName: currentUserProfile?.name ?? '',
      userimgurl: currentUserProfile?.profileImageUrl ?? '',
      imgurl: null,
      text: text.trim(),
      timestamp: DateTime.now(),
    );

    try {
      final updatedComment = await postCubit.addComment(
        widget.post,
        newComment,
        image,
        currentUser!.uid,
      );

      if (updatedComment != null) {
        setState(() {
          widget.post.comments.add(updatedComment);
        });
      }

      return updatedComment;
    } catch (e) {
      debugPrint('Error adding comment: $e');
      return null;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
void reportPost() {
  if (currentUser == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(25),
      ),
    ),
    builder: (context) {
      return BlocProvider.value(
        value: this.context.read<ReportCubit>(),
        child: ReportDialog(
          targetId: widget.post.id,
          targetType: 'post',
          reporterId: currentUser!.uid,
        ),
      );
    },
  );
}

  void copyLink() {
    // TODO: hook up real share/copy-link logic
  }

  // Options shown in the "more" menu — different depending on
  // whether the viewer owns this post.
  List<OptionItem> get menuOptions {
    if (isOwnPost) {
      return [
        OptionItem(
          title: 'Edit Post',
         value: () {
            // Navigate to the edit post screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditPostPage(post: widget.post),
              ),
            );
          },
          icon: Iconsax.edit,
        ),
        OptionItem(
          title: 'Delete',
          value: showDeleteDialog,
          icon: Iconsax.trash,
        ),
      ];
    } else {
      return [
        OptionItem(title: 'Report', value: reportPost, icon: Iconsax.flag),
        OptionItem(title: 'Copy Link', value: copyLink, icon: Iconsax.link),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.post.imageUrls.isNotEmpty;
    final isLiked =
        currentUser != null && widget.post.likes.contains(currentUser!.uid);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: hasImage
          ? ImagePostCard(
              username: widget.post.userName,
              profileImageUrl: postuser?.profileImageUrl ?? '',
              imageUrls: widget.post.imageUrls,
              text: widget.post.text,
              isLiked: isLiked,
              likecount: widget.post.likes.length.toString(),
              timestamp: formatDate(widget.post.timestamp),
              trailing: MyOptionmenu(options: menuOptions),
              onlike: togglelikePost,
              onComment: showComments,
              onSave: toggleSavePost,
              savedcount: widget.post.savedBy.length.toString(),
              isSaved: isSaved,
              commentcount: widget.post.comments.length.toString(),
              ondoubletap: togglelikePost,
              onprofiletap: onprofiletap,
              privacy: widget.post.privacy,
            )
          : TextPostCard(
              username: widget.post.userName,
              text: widget.post.text,
              timestamp: formatDate(widget.post.timestamp),
              profileImageUrl: postuser?.profileImageUrl ?? '',
              trailing: MyOptionmenu(options: menuOptions),
              onlike: togglelikePost,
              isLiked: isLiked,
              likecount: widget.post.likes.length.toString(),
              onComment: showComments,
              commentcount: widget.post.comments.length.toString(),
              onSave: toggleSavePost,
              isSaved: isSaved,
              savedcount: widget.post.savedBy.length.toString(),
              privacy: widget.post.privacy,
              onprofiletap: onprofiletap,
            ),
    );
  }
}
