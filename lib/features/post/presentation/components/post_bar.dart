import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class MySearchBar extends StatelessWidget {
  final VoidCallback? onTap;
  const MySearchBar({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border.all(color: const Color.fromARGB(255, 96, 97, 84)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              SizedBox(width: 12),
              Icon(Iconsax.pen_add, color: Colors.grey),
              SizedBox(width: 10),
              Text(
                "What's on your mind?",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
