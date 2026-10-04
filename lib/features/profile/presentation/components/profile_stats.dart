import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int postCount;
  final int followerCount;
  final int followingCount;
  final void Function()? ontap;

  const new({
    super.key,
    required this.postCount,
    required this.followerCount,
    required this.followingCount,
    required this.ontap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                followerCount.toString(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text('follower'),
            ],
          ),
          SizedBox(width: 50),
          Column(
            children: [
              Text(
                followingCount.toString(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text('following'),
            ],
          ),
          SizedBox(width: 50),
          Column(
            children: [
              Text(
                postCount.toString(),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text('Posts'),
            ],
          ),
        ],
      ),
    );
  }
}
