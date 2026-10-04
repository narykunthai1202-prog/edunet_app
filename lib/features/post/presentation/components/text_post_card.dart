import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TextPostCard extends StatefulWidget {
  final String username;
  final String? profileImageUrl;
  final String text;
  final String timestamp;
  final VoidCallback? onlike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onMore;
  final Widget? trailing;
  final bool isLiked;
  final String likecount;
  final String commentcount;
  final VoidCallback? onprofiletap;
  final bool isSaved;
  final String savedcount;
  final String privacy;

  const TextPostCard({
    super.key,
    required this.username,
    required this.text,
    required this.timestamp,
    this.profileImageUrl,
    this.onlike,
    required this.isLiked,
    this.onComment,
    this.onSave,
    this.onShare,
    this.onMore,
    this.trailing,
    required this.likecount,
    required this.commentcount,
    this.onprofiletap,
    required this.isSaved,
    required this.savedcount,
    required this.privacy
  });

  @override
  State<TextPostCard> createState() => _TextPostCardState();
}

class _TextPostCardState extends State<TextPostCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 390,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xfff1f1f1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profile
                GestureDetector(
                  onTap: widget.onprofiletap,
                  child: Row(
                    children: [
                      CircleProfile(imageurl: widget.profileImageUrl ?? '', size: 25),

                      const SizedBox(width: 10),
                      // Username
                      Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(blurRadius: 5, color: Colors.black),
                                  ],
                                ),
                              ),

                              Row(
      children: [
        Text(
          widget.timestamp,
          style: const TextStyle(
            color: Color.fromARGB(255, 43, 42, 42),
            fontSize: 12,
            shadows: [
              Shadow(blurRadius: 5),
            ],
          ),
        ),

        const SizedBox(width: 6),

        const Icon(
          Icons.circle,
          size: 3,
          color: Colors.grey,
        ),

        const SizedBox(width: 6),
        Icon(
      widget.privacy == 'Public'
          ? Iconsax.global
          : widget.privacy == 'Friend'
              ? Iconsax.people
              : Iconsax.lock,
      size: 13,
      color: const Color.fromARGB(255, 28, 26, 26),
    ),
      ],
    ),
                            ],
                          ),
                    ],
                  ),
                ),
                widget.trailing ?? const SizedBox.shrink(),
              ],
            ),
          ),

          // POST TEXT
          Positioned.fill(
            top: 120,
            bottom: 70,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Text(
                  widget.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          // ACTION BUTTONS
          Positioned(
            bottom: -1,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(17),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onlike,
                    child: Icon(
                      widget.isLiked ? Iconsax.heart5 : Iconsax.heart,
                      color: widget.isLiked ? Colors.red : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(widget.likecount),
                  const SizedBox(width: 22),
                  // Comment
                  GestureDetector(
                    onTap: widget.onComment,
                    child: const Icon(Iconsax.message, size: 23),
                  ),
                  const SizedBox(width: 3),
                  Text(widget.commentcount),
                  const SizedBox(width: 22),
                  // Save
                  GestureDetector(
                    onTap: widget.onSave,
                    child: Icon(
                      widget.isSaved ? Iconsax.bookmark : Iconsax.bookmark,
                      color: widget.isSaved
                          ? const Color.fromARGB(255, 239, 172, 168)
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Text(widget.savedcount),
                  const SizedBox(width: 22),
                  // Share
                  GestureDetector(
                    onTap: widget.onShare,
                    child: const Icon(Iconsax.send_2, size: 23),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
