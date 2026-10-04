import 'package:flutter/material.dart';

class IconsPlaces extends StatelessWidget {
  final IconData? icons2;
  final IconData icons3;
  final void Function()? onTap2;
  final void Function()? onTap3;

  const IconsPlaces({
    super.key,
    this.icons2,
    required this.icons3,
    this.onTap2,
    this.onTap3,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Add button (optional)
          if (icons2 != null)
            Padding(
              padding: const EdgeInsets.only(left: 10),
              child: GestureDetector(
                onTap: onTap2,
                child: Icon(icons2, size: 28),
              ),
            ),

          // Notification (required)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: GestureDetector(
              onTap: onTap3,
              child: Icon(icons3, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}
