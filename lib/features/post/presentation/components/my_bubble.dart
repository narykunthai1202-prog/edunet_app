import 'package:flutter/material.dart';

class MyBubble extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData? iconData;
  final String text;
  final bool isSelected;

  const MyBubble({
    super.key,
    this.onTap,
    this.iconData,
    required this.text,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.secondary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 193, 180, 146)
                : const Color.fromARGB(255, 192, 188, 152),
          ),
        ),
        child: Row(
          mainAxisAlignment: iconData == null
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: [
            if (iconData != null) ...[
              Icon(iconData, size: 19),
              const SizedBox(width: 10),
            ],
            Text(text, style: const TextStyle(fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
