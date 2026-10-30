import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';
import 'package:edunest_app/features/post/presentation/pages/post_detail_page.dart';

class LikedPostTile extends StatelessWidget {
  final Post post;
  final VoidCallback onUnlike;

  const LikedPostTile({
    super.key,
    required this.post,
    required this.onUnlike,
  });

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242227) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : colorScheme.outline.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailPage(postId: post.id),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row & Unlike button
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.2),
                      child: Text(
                        post.userName.isNotEmpty
                            ? post.userName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.userName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.inversePrimary,
                            ),
                          ),
                          Text(
                            _formatDate(post.timestamp),
                            style: TextStyle(
                              fontSize: 11.5,
                              color: colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Unlike Heart Button
                    IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 22,
                      ),
                      tooltip: 'Unlike post',
                      onPressed: onUnlike,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Post text
                if (post.text.isNotEmpty)
                  Text(
                    post.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: colorScheme.inversePrimary.withValues(alpha: 0.9),
                    ),
                  ),

                // Post Image if available
                if (post.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          color: colorScheme.surface,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (_, _, _) => Container(
                          color: colorScheme.surface,
                          child: Icon(Iconsax.image, color: colorScheme.secondary),
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Action hint & comment count
                Row(
                  children: [
                    Icon(Iconsax.message, size: 14, color: colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.comments.length} comments',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          'View Post',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
