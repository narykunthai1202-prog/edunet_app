import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MyBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final String? profileImageUrl;

  const MyBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.profileImageUrl,
  });

  static const _items = [
    Iconsax.home,
    Iconsax.book,
    Iconsax.tick_circle,
    Iconsax.message,
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: const Color.fromARGB(214, 231, 226, 219),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < _items.length; i++)
              _NavIcon(
                icon: _items[i],
                isSelected: currentIndex == i,
                onTap: () => onTap(i),
              ),

            // Profile Button
            GestureDetector(
              onTap: () => onTap(_items.length),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutBack,
                width: currentIndex == _items.length ? 40 : 34,
                height: currentIndex == _items.length ? 40 : 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: currentIndex == _items.length
                        ? const Color.fromARGB(255, 179, 223, 255)
                        : const Color.fromARGB(255, 213, 195, 195),
                    width: 2,
                  ),
                ),
                child: ClipOval(child: _buildProfileAvatar()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (profileImageUrl == null || profileImageUrl!.trim().isEmpty) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.person, color: Colors.grey, size: 22),
      );
    }

    return Image.network(
      profileImageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.person, color: Colors.grey, size: 22),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: isSelected ? 48 : 40,
        height: isSelected ? 48 : 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected
              ? const Color.fromARGB(248, 163, 167, 171)
              : Colors.transparent,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            icon,
            key: ValueKey(isSelected),
            size: isSelected ? 24 : 22,
            color: isSelected ? Colors.white : Colors.black38,
          ),
        ),
      ),
    );
  }
}
