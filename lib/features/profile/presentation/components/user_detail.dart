import 'package:flutter/material.dart';

class UserDetail extends StatelessWidget {
  final String user;
  final IconData icon;

  const UserDetail({super.key, required this.user, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (user.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 115, 116, 117).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color.fromARGB(255, 219, 180, 177),
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              user,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
