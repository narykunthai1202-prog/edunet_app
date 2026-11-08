import 'package:cached_network_image/cached_network_image.dart';
import 'package:edunest_app/core/theme/app_colors.dart';
import 'package:edunest_app/core/theme/app_text_styles.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class ImagePostCard extends StatefulWidget {
  final String username;
  final String? profileImageUrl;

  final List<String> imageUrls;
  final String text;
  final Widget? textContent;
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
    this.textContent,
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
    required this.privacy,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IMAGE POST CONTAINER
        Container(
          height: 410,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppColors.darkDivider : AppColors.divider,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Image carousel
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.imageUrls.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _showImageViewer(index),
                        onDoubleTap: widget.ondoubletap,
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) {
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryLight,
                                ),
                              ),
                            );
                          },
                          errorWidget: (context, url, error) {
                            return const Center(
                              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Top gradient overlay for text readability
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 90,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Multi-image counter pill
              if (widget.imageUrls.length > 1)
                Positioned(
                  top: 14,
                  right: 54,
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

              // Author Header
              Positioned(
                top: 12,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: widget.onprofiletap,
                      child: Row(
                        children: [
                          CircleProfile(
                            imageurl: widget.profileImageUrl ?? '',
                            size: 24,
                          ),
                          const SizedBox(width: 10),
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
                                    Shadow(blurRadius: 4, color: Colors.black45),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    widget.timestamp,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      shadows: [Shadow(blurRadius: 4, color: Colors.black38)],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.circle,
                                    size: 3,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    widget.privacy == 'Public'
                                        ? Iconsax.global
                                        : widget.privacy == 'Friend'
                                            ? Iconsax.people
                                            : Iconsax.lock,
                                    size: 13,
                                    color: Colors.white70,
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

              // Bottom Carousel Dots
              if (widget.imageUrls.length > 1)
                Positioned(
                  bottom: 18,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.imageUrls.length, (index) {
                      final isActive = index == currentImageIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: isActive ? 16 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: isActive ? Colors.white : Colors.white54,
                        ),
                      );
                    }),
                  ),
                ),

              // Floating Action Buttons Pill
              Positioned(
                bottom: -22,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkDivider : AppColors.divider,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Like
                      GestureDetector(
                        onTap: widget.onlike,
                        child: Row(
                          children: [
                            Icon(
                              widget.isLiked ? Iconsax.heart5 : Iconsax.heart,
                              size: 21,
                              color: widget.isLiked ? AppColors.accent : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.likecount,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: widget.isLiked ? AppColors.accent : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 18),

                      // Comment
                      GestureDetector(
                        onTap: widget.onComment,
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.message,
                              size: 21,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.commentcount,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 18),

                      // Save
                      GestureDetector(
                        onTap: widget.onSave,
                        child: Row(
                          children: [
                            Icon(
                              widget.isSaved ? Iconsax.bookmark : Iconsax.bookmark,
                              size: 21,
                              color: widget.isSaved ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.savedcount,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: widget.isSaved ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 18),

                      // Share
                      GestureDetector(
                        onTap: widget.onShare,
                        child: Icon(
                          Iconsax.send_2,
                          size: 21,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Spacing below floating action bar
        const SizedBox(height: 32),

        // Caption
        if (widget.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: widget.textContent ??
                      Text(
                        widget.text,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.textPrimary,
                        ),
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showImageViewer(int initialIndex) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: _PostImageViewer(
          imageUrls: widget.imageUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _PostImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _PostImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_PostImageViewer> createState() => _PostImageViewerState();
}

class _PostImageViewerState extends State<_PostImageViewer> {
  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: widget.imageUrls.length > 1
            ? Text('${_currentIndex + 1}/${widget.imageUrls.length}')
            : null,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) => setState(() {
          _currentIndex = index;
        }),
        itemBuilder: (context, index) => InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: widget.imageUrls[index],
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.broken_image, color: Colors.white, size: 40),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
