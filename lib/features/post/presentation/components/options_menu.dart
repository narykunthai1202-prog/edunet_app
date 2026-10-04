import 'package:flutter/material.dart';

class OptionItem {
  final String title;
  final VoidCallback value;
  final IconData icon;

  const OptionItem({
    required this.title,
    required this.value,
    required this.icon,
  });
}

class MyOptionmenu extends StatelessWidget {
  final List<OptionItem> options;

  const MyOptionmenu({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        shape: BoxShape.circle,
      ),
      child: PopupMenuButton<VoidCallback>(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_vert, size: 24),
        onSelected: (action) => action(),
        itemBuilder: (BuildContext context) {
          return options.map((option) {
            return PopupMenuItem<VoidCallback>(
              value: option.value,
              child: Row(
                children: [
                  Icon(option.icon),
                  const SizedBox(width: 8),
                  Text(option.title),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }
}
