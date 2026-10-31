import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:edunest_app/features/post/domain/entities/post.dart';

class DeletedPostTile extends StatelessWidget {
  final Post post;
  final VoidCallback onRestore;
  final VoidCallback onPermanentlyDelete;

  const DeletedPostTile({
    super.key,
    required this.post,
    required this.onRestore,
    required this.onPermanentlyDelete,
  });

  int get _remainingDays {
    if (post.deletedAt == null) return 30;
    final elapsed = DateTime.now().difference(post.deletedAt!);
    final remaining = 30 - elapsed.inDays;
    return remaining < 0 ? 0 : remaining;
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  void _confirmPermanentDelete(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Iconsax.trash, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Delete Forever?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'This action cannot be undone. Your post, including all comments, reactions, and attachments, will be permanently removed from EduNest.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onPermanentlyDelete();
            },
            child: const Text('Delete Forever'),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Iconsax.refresh_2, color: colorScheme.primary, size: 24),
            const SizedBox(width: 10),
            const Text(
              'Restore Post?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'This post will be restored to your profile and returned to the main feed with all previous likes and comments intact.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: colorScheme.secondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onRestore();
            },
            child: const Text('Restore Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final daysLeft = _remainingDays;
    final isUrgent = daysLeft <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Retention Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isUrgent
                  ? Colors.red.withValues(alpha: 0.12)
                  : Colors.amber.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.timer_1,
                  size: 16,
                  color: isUrgent ? Colors.red : Colors.amber.shade800,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    daysLeft == 0
                        ? 'Expiring today (auto-purge in progress)'
                        : '$daysLeft ${daysLeft == 1 ? "day" : "days"} remaining until permanent deletion',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: isUrgent ? Colors.red : Colors.amber.shade900,
                    ),
                  ),
                ),
                if (post.deletedAt != null)
                  Text(
                    'Deleted ${_formatDate(post.deletedAt!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post text preview
                if (post.text.isNotEmpty)
                  Text(
                    post.text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: colorScheme.inversePrimary,
                    ),
                  ),

                // Attached images preview
                if (post.imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 140,
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

                const SizedBox(height: 14),

                // Stats row
                Row(
                  children: [
                    Icon(Iconsax.heart, size: 15, color: colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likes.length}',
                      style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                    ),
                    const SizedBox(width: 14),
                    Icon(Iconsax.message, size: 15, color: colorScheme.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '${post.comments.length}',
                      style: TextStyle(fontSize: 12, color: colorScheme.secondary),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        post.privacy,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Actions: Restore & Permanent Delete
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _confirmPermanentDelete(context),
                        icon: const Icon(Iconsax.trash, size: 16),
                        label: const Text(
                          'Delete Forever',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        onPressed: () => _confirmRestore(context),
                        icon: const Icon(Iconsax.refresh_2, size: 16),
                        label: const Text(
                          'Restore',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
