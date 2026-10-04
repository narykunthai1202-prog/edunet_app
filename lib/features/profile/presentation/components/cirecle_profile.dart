import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CircleProfile extends StatelessWidget {
  final String imageurl;
  final double size;

  const CircleProfile({
    super.key,
    required this.imageurl,
    this.size = 50.0, // Default size if none is provided
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundColor: Theme.of(context).colorScheme.tertiary,
      backgroundImage: imageurl.isNotEmpty ? NetworkImage(imageurl) : null,

      child: imageurl.isEmpty
          ? Icon(
              Iconsax.user,
              size:
                  size *
                  0.8, // Scales the icon proportionally to the avatar size
              color: const Color.fromARGB(
                255,
                223,
                163,
                141,
              ), // Optional: matches your background tint
            )
          : null,
    );
  }
}
