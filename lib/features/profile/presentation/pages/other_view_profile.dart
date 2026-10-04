import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/post/presentation/components/my_bubble.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/presentation/components/about_section.dart';
import 'package:edunest_app/features/profile/presentation/components/icons_places.dart';
import 'package:edunest_app/features/profile/presentation/components/list_view_post_byprivacy.dart';
import 'package:edunest_app/features/profile/presentation/components/other_user_info.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/profile/presentation/pages/follow_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class OtherViewProfile extends StatefulWidget {
  final String uid;
  const OtherViewProfile({super.key, required this.uid});

  @override
  State<OtherViewProfile> createState() => _OtherViewProfileState();
}

class _OtherViewProfileState extends State<OtherViewProfile> {
  late final profilecubit = context.read<ProfileCubit>();

  ProfileUser? _user;
  bool _loading = true;
  String? _error;
  bool _showPosts = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  //follow unfollow
  void followButtonPresssed() {
    final currentUid = context
        .read<AuthCubit>()
        .currentUser
        ?.uid; // adjust to your actual auth source

    if (currentUid == null || _user == null) return;

    // optimistic UI update
    final isFollowing = _user!.followers.contains(currentUid);
    setState(() {
      if (isFollowing) {
        _user = _user!.copyWith(
          newFollowers: List<String>.from(_user!.followers)..remove(currentUid),
        );
      } else {
        _user = _user!.copyWith(
          newFollowers: List<String>.from(_user!.followers)..add(currentUid),
        );
      }
    });
    profilecubit.toggleFollow(currentUid, widget.uid);
  }

  int _postCount = 0;
  Future<void> _loadProfile() async {
    try {
      final user = await profilecubit.getUserProfile(widget.uid);

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _error = 'User not found';
        });

        return;
      }

      final postCount = await profilecubit.getPostCount(widget.uid);

      if (!mounted) return;

      setState(() {
        _user = user;
        _postCount = postCount;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthCubit>().currentUser?.uid;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null || _user == null) {
      return Scaffold(body: Center(child: Text('Error: $_error')));
    }
    final user = _user!;
    return Scaffold(
      body: ListView(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.arrow_left),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      IconsPlaces(icons3: Iconsax.notification),
                    ],
                  ),
                ),
                OtherUserInfo(
                  imageUrl: user.profileImageUrl,
                  username: user.name,
                  userbios: user.bio,
                  usernickname: user.nickname,
                  major: user.major,
                  onpressed: followButtonPresssed,

                  // Current user follows the other user
                  isfollow: user.followers.contains(currentUid),

                  // Other user follows the current user
                  isFollowedByUser: user.following.contains(currentUid),

                  postcount: _postCount,
                  followercount: user.followers.length,
                  followingcount: user.following.length,
                  userId: user.uid,

                  ontap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowPage(
                        followers: user.followers,
                        following: user.following,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MyBubble(
                        text: 'About',
                        iconData: Iconsax.information,
                        isSelected: !_showPosts,
                        onTap: () {
                          setState(() {
                            _showPosts = false;
                          });
                        },
                      ),
                      const SizedBox(width: 5),
                      MyBubble(
                        text: 'Posts',
                        iconData: Iconsax.book,
                        isSelected: _showPosts,
                        onTap: () {
                          setState(() {
                            _showPosts = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                _showPosts
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ListViewPostByprivacy(uid: widget.uid, viewerUid: currentUid,),
                      )
                    : AboutSection(user: user),
                // rest of your body
              ],
            ),
          ),
        ],
      ),
    );
  }
}
