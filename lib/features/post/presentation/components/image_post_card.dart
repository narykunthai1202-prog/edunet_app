import 'package:cached_network_image/cached_network_image.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ImagePostCard extends StatefulWidget {
  final String username;
  final String? profileImageUrl;

  // Multiple image URLs
  final List<String> imageUrls;
  final String text;
  final String timestamp;
  final VoidCallback? onlike;
  final VoidCallback? onComment;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final Widget? trailing;
  final bool isLiked;
  final String likecount;
  final String commentcount;
  final VoidCallback? onprofiletap;
  final bool isSaved;
  final String savedcount;
  final VoidCallback? ondoubletap;
  final String privacy;

  const ImagePostCard({
    super.key,
    required this.username,
    this.profileImageUrl,
    required this.imageUrls,
    required this.text,
    required this.timestamp,
    this.onlike,
    this.onComment,
    this.onSave,
    this.onShare,
    this.trailing,
    required this.isLiked,
    required this.likecount,
    required this.commentcount,
    this.onprofiletap,
    required this.isSaved,
    required this.savedcount,
    required this.ondoubletap,
    required this.privacy
  });

  @override
  State<ImagePostCard> createState() => _ImagePostCardState();
}

class _ImagePostCardState extends State<ImagePostCard> {
  final PageController _pageController = PageController();

  int currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IMAGE POST
        Container(
          height: 400,
          width: double.infinity,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls.length,

                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },

                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: widget.imageUrls[index],
                        fit: BoxFit.cover,

                        // Loading
                        placeholder: (context, url) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },

                        // Error
                        errorWidget: (context, url, error) {
                          return const Center(
                            child: Icon(Icons.broken_image, size: 40),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),

              if (widget.imageUrls.length > 1)
                Positioned(
                  top: 12,
                  right: 55,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${currentImageIndex + 1}/${widget.imageUrls.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

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
                          CircleProfile(
                            imageurl: widget.profileImageUrl ?? '',
                            size: 25,
                          ),

                          const SizedBox(width: 10),

                          // Username + timestamp
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
      color: const Color.fromARGB(255, 21, 21, 21),
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

              if (widget.imageUrls.length > 1)
                GestureDetector(
                  onDoubleTap: widget.ondoubletap,
                  child: Positioned(
                    bottom: 15,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(widget.imageUrls.length, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: index == currentImageIndex ? 8 : 6,
                          height: index == currentImageIndex ? 8 : 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                              alpha: index == currentImageIndex ? 1 : 0.5,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),

              Positioned(
                bottom: -22,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // LIKE
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

                      // COMMENT
                      GestureDetector(
                        onTap: widget.onComment,
                        child: const Icon(Iconsax.message, size: 23),
                      ),

                      const SizedBox(width: 3),

                      Text(widget.commentcount),

                      const SizedBox(width: 22),

                      // SAVE
                      GestureDetector(
                        onTap: widget.onSave,
                        child: Icon(
                          widget.isSaved ? Iconsax.bookmark : Iconsax.bookmark,
                          color: widget.isSaved
                              ? const Color.fromARGB(255, 253, 186, 181)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 3),

                      Text(widget.savedcount),

                      const SizedBox(width: 22),

                      // SHARE
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
        ),

        // Space for floating buttons
        const SizedBox(height: 30),

        if (widget.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(width: 5),

                const Text(':', style: TextStyle(fontSize: 15)),

                const SizedBox(width: 5),

                Expanded(
                  child: Text(
                    widget.text,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
