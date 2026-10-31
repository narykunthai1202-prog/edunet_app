import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/faq_item.dart';

class FaqTile extends StatefulWidget {
  final FaqItem item;
  final ValueChanged<bool> onVote;

  const FaqTile({
    super.key,
    required this.item,
    required this.onVote,
  });

  @override
  State<FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<FaqTile> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark
        ? const Color(0xFF242227)
        : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : colorScheme.outline.withValues(alpha: 0.15);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
          childrenPadding: const EdgeInsets.fromLTRB(18.0, 0.0, 18.0, 16.0),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.message_question,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            widget.item.question,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: colorScheme.inversePrimary,
              height: 1.35,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              widget.item.category,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: colorScheme.inversePrimary,
              size: 24,
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.item.answer,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.inversePrimary.withValues(alpha: 0.85),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Was this helpful?',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.secondary,
                  ),
                ),
                const Spacer(),
                // Helpful button
                InkWell(
                  onTap: widget.item.userVote != null
                      ? null
                      : () => widget.onVote(true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.item.userVote == true
                          ? Colors.green.withValues(alpha: 0.15)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.item.userVote == true
                            ? Colors.green
                            : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.like_1,
                          size: 15,
                          color: widget.item.userVote == true
                              ? Colors.green
                              : colorScheme.inversePrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.item.helpfulCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.item.userVote == true
                                ? Colors.green
                                : colorScheme.inversePrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Not helpful button
                InkWell(
                  onTap: widget.item.userVote != null
                      ? null
                      : () => widget.onVote(false),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.item.userVote == false
                          ? Colors.red.withValues(alpha: 0.15)
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.item.userVote == false
                            ? Colors.red
                            : borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.dislike,
                          size: 15,
                          color: widget.item.userVote == false
                              ? Colors.red
                              : colorScheme.inversePrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.item.unhelpfulCount}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.item.userVote == false
                                ? Colors.red
                                : colorScheme.inversePrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
