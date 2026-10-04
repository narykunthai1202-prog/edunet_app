import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class TextPostCard extends StatelessWidget {
  final String username;
  final String? profileImageUrl;
  final String text;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onMore;

  const TextPostCard({
    super.key,
    required this.username,
    required this.text,
    this.profileImageUrl,
    this.onComment,
    this.onSave,
    this.onShare,
    this.onMore,
  });

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
          // PROFILE
          Positioned(
            top: 12,
            left: 12,
            child: Row(
              children: [
                Container(
                  height: 68,
                  width: 68,
                  decoration: const BoxDecoration(
                    color: Color(0xffffefd2),
                    shape: BoxShape.circle,
                  ),
                  child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            profileImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.person_outline,
                          color: Colors.redAccent,
                          size: 35,
                        ),
                ),

                const SizedBox(width: 12),

                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 12,
            child: GestureDetector(
              onTap: onMore,
              child: Container(
                height: 40,
                width: 40,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_vert, size: 24),
              ),
            ),
          ),
          Positioned.fill(
            top: 120,
            bottom: 70,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 35),
                child: Text(
                  text,
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
                  // Comment
                  GestureDetector(
                    onTap: onComment,
                    child: const Icon(Iconsax.message, size: 23),
                  ),

                  const SizedBox(width: 22),

                  // Save
                  GestureDetector(
                    onTap: onSave,
                    child: const Icon(Iconsax.bookmark, size: 23),
                  ),

                  const SizedBox(width: 22),

                  // Share
                  GestureDetector(
                    onTap: onShare,
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
