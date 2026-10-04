import 'package:edunest_app/features/profile/presentation/components/user_detail.dart';
import 'package:flutter/material.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:iconsax/iconsax.dart';

class AboutSection extends StatelessWidget {
  final ProfileUser user;

  const AboutSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Personal Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 2),

                    Text(
                      'Information about this user',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Divider
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            // Details
            UserDetail(user: user.address, icon: Iconsax.location),
            UserDetail(user: user.dateofbirth, icon: Iconsax.cake),
            UserDetail(user: user.relationshipStatus, icon: Iconsax.heart),
            const SizedBox(height: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Education',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 2),
                Text(
                  'Information about this user',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Divider
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            // Details
            UserDetail(user: user.university, icon: Iconsax.building),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hobbies',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 2),
                Text(
                  'Information about this user',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Divider
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 12),
            // Details
            UserDetail(user: user.hobbies, icon: Iconsax.activity),
          ],
        ),
      ),
    );
  }
}
