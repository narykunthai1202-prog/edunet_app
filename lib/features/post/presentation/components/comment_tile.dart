import 'package:edunest_app/features/post/domain/entities/comment.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:flutter/material.dart';

import 'comment_action_menu.dart';

class CommentTile extends StatefulWidget {
  final Comment comment;
  final String? currentUserId;
  final String Function(DateTime time) formatTime;
  final void Function(String userId) onProfileTap;
  final void Function(Comment comment)? onReact;
  final void Function(Comment comment)? onReply;
  final void Function(Comment comment)? onDeleteComment;
  final void Function(Comment comment)? onReportComment;
  final void Function(Comment comment)? onDeleteReply;
  final bool isReply;
  final int depth;

  const CommentTile({
    super.key,
    required this.comment,
    required this.currentUserId,
    required this.formatTime,
    required this.onProfileTap,
    this.onReact,
    this.onReply,
    this.onDeleteComment,
    this.onReportComment,
    this.onDeleteReply,
    this.isReply = false,
    this.depth = 0,
  });

  @override
  State<CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<CommentTile> {
  bool _showAllReplies = false;

  static const int _initialReplyCount = 2;

  int _totalReplies(Comment comment) {
    return comment.replies.fold<int>(
      0,
      (total, reply) => total + 1 + _totalReplies(reply),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final isOwner = comment.userId == widget.currentUserId;
    final isNested = widget.depth > 0;
    final replies = comment.replies;

    final visibleCount = _showAllReplies
        ? replies.length
        : replies.length.clamp(0, _initialReplyCount);

    final hasReacted =
        widget.currentUserId != null &&
        comment.reactions.contains(widget.currentUserId);

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: EdgeInsets.only(
        left: isNested ? 0 : 16,
        right: 12,
        top: 5,
        bottom: 5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => widget.onProfileTap(comment.userId),
            child: CircleProfile(
              imageurl: comment.userimgurl ?? '',
              size: 20,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Main comment bubble
                Container(
                  padding: const EdgeInsets.fromLTRB(13, 10, 7, 10),
                  decoration: BoxDecoration(
                    color: isNested
                        ? theme.colorScheme.surfaceContainerLowest
                        : theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onProfileTap(comment.userId),
                              child: Text(
                                comment.userName.trim().isEmpty
                                    ? 'User'
                                    : comment.userName,
                                style: TextStyle(
                                  fontSize: isNested ? 12 : 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 26,
                            width: 28,
                            child: CommentActionMenu(
                              canDelete: isOwner,
                              isReply: isNested,
                              onDelete: () {
                                if (isNested) {
                                  widget.onDeleteReply?.call(comment);
                                } else {
                                  widget.onDeleteComment?.call(comment);
                                }
                              },
                              onReport: !isNested && !isOwner
                                  ? () => widget.onReportComment?.call(comment)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (comment.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          comment.text,
                          style: TextStyle(
                            fontSize: isNested ? 13 : 14,
                            height: 1.4,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                      if (comment.imgurl != null &&
                          comment.imgurl!.trim().isNotEmpty)
                        _buildImage(comment.imgurl!),
                    ],
                  ),
                ),

                // Time, reaction and reply actions
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4, top: 5),
                  child: Wrap(
                    spacing: 15,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        widget.formatTime(comment.timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => widget.onReact?.call(comment),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 2,
                            horizontal: 1,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasReacted
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                size: 16,
                                color: hasReacted
                                    ? Colors.redAccent
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                              if (comment.reactions.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${comment.reactions.length}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: hasReacted
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: hasReacted
                                        ? Colors.redAccent
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: () => widget.onReply?.call(comment),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Recursive replies
                if (replies.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 7, top: 7),
                    child: Container(
                      padding: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                            width: 1.5,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (final reply in replies.take(visibleCount))
                            CommentTile(
                              key: ValueKey(reply.id),
                              comment: reply,
                              currentUserId: widget.currentUserId,
                              formatTime: widget.formatTime,
                              onProfileTap: widget.onProfileTap,
                              onReact: widget.onReact,
                              onReply: widget.onReply,
                              onDeleteComment: widget.onDeleteComment,
                              onReportComment: widget.onReportComment,
                              onDeleteReply: widget.onDeleteReply,
                              depth: widget.depth + 1,
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (replies.length > _initialReplyCount)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 18,
                        top: 7,
                        bottom: 5,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            setState(() => _showAllReplies = !_showAllReplies),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showAllReplies
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: primaryColor,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                _showAllReplies
                                    ? 'Hide replies'
                                    : 'View all ${_totalReplies(comment)} replies',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(String url) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: Image.network(
          url,
          width: 220,
          height: 180,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 220,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 30,
                  color: Colors.grey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
