import 'package:edunest_app/features/post/presentation/components/my_bubble.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:edunest_app/features/profile/presentation/components/profile_stats.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class UserInfo extends StatefulWidget {
  final String imageUrl;
  final String username;
  final String userbios;
  final String useremail;
  final String usermajor;
  final int postcount;
  final int followercount;
  final int followingcount;
  final String usernickname;
  final void Function()? ontapfollower;
  final void Function()? ontapeditprofile;
  const UserInfo({
    super.key,
    required this.imageUrl,
    required this.username,
    required this.userbios,
    required this.useremail,
    required this.postcount,
    required this.followercount,
    required this.followingcount,
    required this.ontapfollower,
    required this.usermajor,
    required this.usernickname,
    required this.ontapeditprofile,
  });

  @override
  State<UserInfo> createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 221, 171, 180).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 51, 49, 49).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(10, 24),
          ),
        ],
      ),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 2.0,
                vertical: 2.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleProfile(imageurl: widget.imageUrl, size: 50),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.username,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          if (widget.usernickname.isNotEmpty)
                            Text('(${widget.usernickname})'),
                        ],
                      ),

                      SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '🎓 ${widget.usermajor}',
                            style: TextStyle(fontSize: 15),
                          ),
                          SizedBox(width: 5),
                        ],
                      ),

                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MyBubble(
                            text: 'Edit Profile',
                            iconData: Iconsax.edit,
                            onTap: widget.ontapeditprofile,
                            isSelected: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                if (widget.userbios.trim().isNotEmpty) ...[
                  Icon(Iconsax.note),
                  const SizedBox(width: 5),
                  Text(widget.userbios, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  const SizedBox(width: 20),
                  SizedBox(height: 20),
                ],
              ],
            ),
            const SizedBox(height: 5),
            ProfileStats(
              postCount: widget.postcount,
              followerCount: widget.followercount,
              followingCount: widget.followingcount,
              ontap: widget.ontapfollower,
            ),
          ],
        ),
      ),
    );
  }
}
