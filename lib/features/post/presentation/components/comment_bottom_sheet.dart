import 'dart:io';

import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/post/domain/entities/comment.dart';
import 'package:edunest_app/features/post/presentation/components/report_dialog.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/report_cubit.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:flutter/material.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final String? userprofileimg;
  final List<Comment> comments;
  final Future<Comment?> Function(String text, File? image)? onSubmit;
  final void Function(String userId) on_comment_profile_tap;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    this.userprofileimg,
    required this.comments,
    this.onSubmit,
    required this.on_comment_profile_tap,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  late List<Comment> comments;
  final TextEditingController controller = TextEditingController();
  File? selectedImage;
  bool isSending = false;
  AppUser? currentuser;
  bool isOwnPost = false;

  @override
  void initState() {
    super.initState();
    comments = List.from(widget.comments);
    final authCubit = context.read<AuthCubit>();
    currentuser = authCubit.currentUser;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> chooseImage() async {
    final picker = ImagePicker();

    final pickedImage = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedImage == null) return;

    if (!mounted) return;

    setState(() {
      selectedImage = File(pickedImage.path);
    });
  }
  void showReportCommentDialog(Comment comment) {
  if (currentuser == null) return;

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
          targetId: comment.id,
          targetType: 'comment',
          reporterId: currentuser!.uid,
        ),
      );
    },
  );
}

  Future<void> submitComment() async {
    if (isSending) return;

    final text = controller.text.trim();

    // Nothing to send
    if (text.isEmpty && selectedImage == null) {
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final newComment = await widget.onSubmit?.call(text, selectedImage);

      if (!mounted) return;

      if (newComment != null) {
        setState(() {
          comments.add(newComment);
          controller.clear();
          selectedImage = null;
        });
      }
    } catch (e) {
      debugPrint('Error submitting comment: $e');
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }
Widget buildComment(Comment comment) {
  final canDelete = comment.userId == currentuser?.uid;

  return Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 7,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile picture
        GestureDetector(
          onTap: () {
            widget.on_comment_profile_tap(comment.userId);
          },
          child: CircleProfile(
            imageurl: comment.userimgurl ?? '',
            size: 20,
          ),
        ),

        const SizedBox(width: 10),

        // Comment content
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              15,
              1,
              8,
              10,
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          widget.on_comment_profile_tap(
                            comment.userId,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              comment.userName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                               // More button
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: const Icon(
                        Iconsax.more,
                        size: 18,
                      ),
                      onSelected: (value) async {
                        if (value == 'delete') {
                          await context
                              .read<PostCubit>()
                              .deleteComment(
                                widget.postId,
                                comment.id,
                              );

                          if (!mounted) return;

                          setState(() {
                            comments.removeWhere(
                              (c) => c.id == comment.id,
                            );
                          });
                        }

                        if (value == 'report') {
                          showReportCommentDialog(comment);
                        }
                      },
                      itemBuilder: (context) {
                        if (canDelete) {
                          return [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Iconsax.trash,
                                    color: Colors.red,
                                    size: 19,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Delete',
                                    style: TextStyle(
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        }

                        return [
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.flag,
                                  size: 19,
                                ),
                                SizedBox(width: 10),
                                Text('Report'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                            
                          ],
                        ),
                      ),
                    ),

                 
                  ],
                ),

                // Comment text
                if (comment.text.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 8,
                      top: 0,
                    ),
                    child: Text(
                      comment.text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),

                // Comment image
                if (comment.imgurl != null &&
                    comment.imgurl!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 10,
                      right: 6,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        comment.imgurl!,
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (
                          context,
                          error,
                          stackTrace,
                        ) {
                          return Container(
                            width: 180,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Time
                const SizedBox(height: 5),

                Text(
                  formatCommentTime(comment.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

String formatCommentTime(DateTime time) {
  final difference = DateTime.now().difference(time);

  if (difference.inSeconds < 60) {
    return 'Just now';
  }

  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m';
  }

  if (difference.inHours < 24) {
    return '${difference.inHours}h';
  }

  if (difference.inDays < 7) {
    return '${difference.inDays}d';
  }

  return '${time.day}/${time.month}/${time.year}';
}

@override
Widget build(BuildContext context) {
  return SafeArea(
    child: AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 151, 120, 120),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                14,
                20,
                12,
              ),
              child: Row(
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${comments.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              height: 1,
              color: Colors.grey.shade200,
            ),

            // Comments
            Expanded(
              child: comments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Iconsax.message,
                            size: 45,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No comments yet',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to comment',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.only(
                        top: 10,
                        bottom: 10,
                      ),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        return buildComment(
                          comments[index],
                        );
                      },
                    ),
            ),

            // Selected image preview
            if (selectedImage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  16,
                  4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          selectedImage!,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),

                      Positioned(
                        top: 5,
                        right: 5,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImage = null;
                            });
                          },
                          child: Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Comment input
            Container(
              padding: const EdgeInsets.fromLTRB(
                14,
                8,
                10,
                10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Current user profile
                  CircleProfile(
                    imageurl: widget.userprofileimg ?? '',
                    size: 20,
                  ),

                  const SizedBox(width: 9),

                  // Input
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.newline,
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 3),

                  // Image button
                  IconButton(
                    onPressed: chooseImage,
                    tooltip: 'Add image',
                    icon: Icon(
                      Iconsax.image,
                      color: Colors.grey.shade700,
                      size: 22,
                    ),
                  ),

                  // Send button
                  GestureDetector(
                    onTap: isSending
                        ? null
                        : submitComment,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSending
                            ? Colors.grey.shade300
                            : Theme.of(context)
                                .colorScheme
                                .primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isSending
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Iconsax.send_1,
                                color: Colors.white,
                                size: 19,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}