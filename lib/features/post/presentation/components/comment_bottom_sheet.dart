import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/post/domain/entities/comment.dart';
import 'package:edunest_app/features/post/presentation/components/report_dialog.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/report_cubit.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';

import 'comment_tile.dart';

class CommentBottomSheet extends StatefulWidget {
  final String postId;
  final String? userprofileimg;
  final List<Comment> comments;
  final Future<Comment?> Function(String text, File? image)? onSubmit;
  final String? currentUserName;
  final void Function(String userId) onCommentProfileTap;

  const CommentBottomSheet({
    super.key,
    required this.postId,
    this.userprofileimg,
    required this.comments,
    this.onSubmit,
    this.currentUserName,
    required this.onCommentProfileTap,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  late final List<Comment> _comments;
  final TextEditingController _controller = TextEditingController();
  File? _selectedImage;
  bool _isSending = false;
  AppUser? _currentUser;
  Comment? _replyingTo;

  @override
  void initState() {
    super.initState();
    _comments = List<Comment>.from(widget.comments);
    _currentUser = context.read<AuthCubit>().currentUser;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyingTo = comment;
      _selectedImage = null;
      _controller.clear();
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
      _selectedImage = null;
      _controller.clear();
    });
  }

  Future<String> _resolveCurrentUserName() async {
    final uid = _currentUser?.uid;
    final supplied = widget.currentUserName?.trim();
    if (supplied != null && supplied.isNotEmpty && supplied != uid) {
      return supplied;
    }
    if (uid == null) return 'User';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data();
      if (data != null) {
        for (final key in [
          'name',
          'fullName',
          'fullname',
          'displayName',
          'username',
          'userName',
        ]) {
          final value = data[key]?.toString().trim();
          if (value != null && value.isNotEmpty && value != uid) return value;
        }
      }
    } catch (e) {
      debugPrint('Could not resolve comment author name: $e');
    }
    return 'User';
  }

  Future<void> _submit() async {
    if (_isSending || _currentUser == null) return;
    final postCubit = context.read<PostCubit>();
    final text = _controller.text.trim();
    if (text.isEmpty && _selectedImage == null) return;
    setState(() => _isSending = true);
    try {
      final parent = _replyingTo;
      if (parent != null) {
        final userName = await _resolveCurrentUserName();
        final reply = Comment(
          id: FirebaseFirestore.instance.collection('posts').doc().id,
          postId: widget.postId,
          userId: _currentUser!.uid,
          userName: userName,
          userimgurl: widget.userprofileimg ?? '',
          imgurl: null,
          text: text,
          timestamp: DateTime.now(),
          reactions: [],
          replies: [],
        );
        final replyWithImage = _selectedImage;
        await postCubit.addReply(
          widget.postId,
          parent.id,
          reply,
          parent: parent,
          image: replyWithImage,
        );

        if (!mounted) return;

        setState(() {
          _replyingTo = null;
          _controller.clear();
          _selectedImage = null;
        });

        await _refreshCommentsFromFirestore();
      } else {
        final newComment = await widget.onSubmit?.call(text, _selectedImage);
        if (!mounted) return;
        if (newComment != null) {
          setState(() {
            _comments.add(newComment);
            _controller.clear();
            _selectedImage = null;
          });
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to submit comment/reply: $error\n$stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _replyingTo == null
                  ? 'Failed to send comment.'
                  : 'Failed to send reply.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> _refreshCommentsFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();
      final data = doc.data();
      if (data == null || !mounted) return;
      final raw = data['comments'] as List<dynamic>? ?? [];
      final fresh = raw
          .map(
            (item) => Comment.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList();
      setState(() {
        _comments
          ..clear()
          ..addAll(fresh);
      });
    } catch (e) {
      debugPrint('Failed to refresh comments: $e');
    }
  }

  Future<void> _toggleReaction(Comment comment) async {
    final uid = _currentUser?.uid;
    if (uid == null) return;
    final hadReacted = comment.reactions.contains(uid);
    setState(() {
      if (hadReacted) {
        comment.reactions.remove(uid);
      } else {
        comment.reactions.add(uid);
      }
    });
    try {
      await context.read<PostCubit>().toggleCommentReaction(
        widget.postId,
        comment,
        uid,
        isAdding: !hadReacted,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (hadReacted) {
          comment.reactions.add(uid);
        } else {
          comment.reactions.remove(uid);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to react to comment.')),
      );
    }
  }

  Future<void> _deleteTopLevelComment(Comment comment) async {
    try {
      await context.read<PostCubit>().deleteComment(widget.postId, comment.id);
      if (mounted) {
        setState(() => _comments.removeWhere((item) => item.id == comment.id));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete comment.')),
        );
      }
    }
  }

  Future<void> _deleteNestedComment(Comment comment) async {
    if (_currentUser?.uid != comment.userId) return;
    try {
      await context.read<PostCubit>().deleteReply(
        widget.postId,
        '',
        comment.id,
      );
      if (mounted) await _refreshCommentsFromFirestore();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete reply.')),
        );
      }
    }
  }

  void _reportComment(Comment comment) {
    if (_currentUser == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: context.read<ReportCubit>(),
        child: ReportDialog(
          targetId: comment.id,
          targetType: 'comment',
          reporterId: _currentUser!.uid,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final difference = DateTime.now().difference(time);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m';
    if (difference.inHours < 24) return '${difference.inHours}h';
    if (difference.inDays < 7) return '${difference.inDays}d';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          height: MediaQuery.of(context).size.height * .78,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
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
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_comments.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              Expanded(
                child: _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Iconsax.message,
                              size: 45,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.45,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet',
                              style: TextStyle(
                                fontSize: 15,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to comment',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        key: const PageStorageKey('edunest-comments'),
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(top: 10, bottom: 10),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) => CommentTile(
                          key: ValueKey(_comments[index].id),
                          comment: _comments[index],
                          currentUserId: _currentUser?.uid,
                          formatTime: _formatTime,
                          onProfileTap: widget.onCommentProfileTap,
                          onReact: _toggleReaction,
                          onReply: _startReply,
                          onDeleteComment: _deleteTopLevelComment,
                          onDeleteReply: _deleteNestedComment,
                          onReportComment: _reportComment,
                        ),
                      ),
              ),
              if (_selectedImage != null) _buildImagePreview(),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              _selectedImage!,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImage = null),
              child: Container(
                width: 25,
                height: 25,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildInput() {
    final isReplying = _replyingTo != null;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isReplying)
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 4, bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to ${_replyingTo!.userName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Cancel reply',
                    onPressed: _cancelReply,
                    icon: const Icon(Icons.close, size: 18),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CircleProfile(imageurl: widget.userprofileimg ?? '', size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textInputAction: TextInputAction.newline,
                  maxLines: 4,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: isReplying
                        ? 'Write a reply...'
                        : 'Add a comment...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: _chooseImage,
                tooltip: 'Add image',
                icon: Icon(
                  Iconsax.image,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ),
              const SizedBox(width: 3),
              GestureDetector(
                onTap: _isSending ? null : _submit,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _isSending
                        ? colorScheme.surfaceContainerHighest
                        : colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _isSending
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Iconsax.send_1,
                            color: colorScheme.onPrimary,
                            size: 19,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
