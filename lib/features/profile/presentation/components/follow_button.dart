import 'package:flutter/material.dart';

class FollowButton extends StatelessWidget {
  final void Function()? ontap;
  final double width;
  final double height;
  final BorderRadius radius;
  final bool isFollowing;
  final bool isFollowedByUser;

  const FollowButton({
    super.key,
    required this.ontap,
    required this.height,
    required this.width,
    required this.radius,
    required this.isFollowing,
    required this.isFollowedByUser,
  });

  @override
  Widget build(BuildContext context) {
    final String buttonText;

    if (isFollowing) {
      buttonText = 'Following';
    } else if (isFollowedByUser) {
      buttonText = 'Follow Back';
    } else {
      buttonText = 'Follow';
    }

    return MaterialButton(
      onPressed: ontap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: width, vertical: height),
        decoration: BoxDecoration(
          color: isFollowing
              ? Theme.of(context).colorScheme.surface
              : const Color.fromARGB(255, 234, 197, 160).withValues(alpha: 0.25),
          borderRadius: radius,
          border: Border.all(color: Colors.grey),
        ),
        child: Text(
          buttonText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
