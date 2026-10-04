import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/post/presentation/components/report_dialog.dart';
import 'package:edunest_app/features/post/presentation/cubits/report_cubit.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:edunest_app/features/profile/presentation/components/follow_button.dart';
import 'package:edunest_app/features/profile/presentation/components/profile_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class OtherUserInfo extends StatefulWidget {
  final String imageUrl;
  final String username;
  final String userbios;
  final String usernickname;
  final String major;
  final void Function()? onpressed;
  final void Function()? ontap;

  final bool isfollow;
  final bool isFollowedByUser;

  final int postcount;
  final int followercount;
  final int followingcount;
  final String userId;

  const OtherUserInfo({
    super.key,
    required this.imageUrl,
    required this.username,
    required this.userbios,
    required this.usernickname,
    required this.onpressed,
    required this.isfollow,
    required this.major,
    required this.isFollowedByUser,
    required this.postcount,
    required this.followercount,
    required this.followingcount,
    required this.ontap,
    required this.userId,
  });

  @override
  State<OtherUserInfo> createState() => _OtherUserInfoState();
}

class _OtherUserInfoState extends State<OtherUserInfo> {
  void showReportAccountDialog() {
  final authCubit = context.read<AuthCubit>();
  final currentUser = authCubit.currentUser;

  if (currentUser == null) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(25),
      ),
    ),
    builder: (context) {
      return BlocProvider.value(
        value: this.context.read<ReportCubit>(),
        child: ReportDialog(
          targetId: widget.userId,
          targetType: 'account',
          reporterId: currentUser.uid,
        ),
      );
    },
  );
}
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 221, 171, 180).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 16, 14, 14).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(10, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              CircleProfile(imageurl: widget.imageUrl, size: 50),

              const SizedBox(width: 20),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        if (widget.usernickname.isNotEmpty) Text('(${widget.usernickname})'),
                          ],
                        ),
                       
                        PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: const Icon(
                        Iconsax.more,
                        size: 18,
                      ),
                      onSelected: (value) async {
                        
                        if (value == 'report') {
showReportAccountDialog();                        }
                      },
                      itemBuilder: (context) {

                        return [
                          const PopupMenuItem(
                            value: 'report',
                            child: Row(
                              children: [
                                Icon(
                                  Iconsax.flag,
                                  size: 19,
                                ),
                                SizedBox(width: 10),
                                Text('Report'),
                              ],
                            ),
                          ),
                        ];
                      },
                    ),
                      ],
                    ),

                    if (widget.major.isNotEmpty)
                      Text('🎓 ${widget.major}', style: TextStyle(fontSize: 15)),
                    const SizedBox(height: 10),
                    // Follow button
                    FollowButton(
                      ontap: widget.onpressed,
                      height: 10,
                      width: 25,
                      radius: BorderRadius.circular(15),
                      isFollowing: widget.isfollow,
                      isFollowedByUser: widget.isFollowedByUser,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Bio
          if (widget.userbios.trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Iconsax.note, size: 20),
                const SizedBox(width: 8),

                Expanded(
                  child: Text(widget.userbios, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ],

          const SizedBox(height: 15),

          const SizedBox(height: 20),

          // Profile statistics
          ProfileStats(
            postCount: widget.postcount,
            followerCount: widget.followercount,
            followingCount: widget.followingcount,
            ontap: widget.ontap,
          ),
        ],
      ),
    );
  }
}
