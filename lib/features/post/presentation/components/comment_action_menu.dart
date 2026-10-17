import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CommentActionMenu extends StatelessWidget {
  final bool canDelete;
  final bool isReply;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const CommentActionMenu({
    super.key,
    required this.canDelete,
    required this.isReply,
    this.onDelete,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    if (!canDelete && onReport == null) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: Icon(Iconsax.more, size: isReply ? 16 : 18),
      onSelected: (value) {
        if (value == 'delete') onDelete?.call();
        if (value == 'report') onReport?.call();
      },
      itemBuilder: (context) => [
        if (canDelete)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Iconsax.trash, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        if (!canDelete && onReport != null)
          const PopupMenuItem<String>(
            value: 'report',
            child: Row(
              children: [
                Icon(Iconsax.flag, size: 18),
                SizedBox(width: 8),
                Text('Report'),
              ],
            ),
          ),
      ],
    );
  }
}
