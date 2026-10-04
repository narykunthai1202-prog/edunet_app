import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:edunest_app/features/profile/presentation/pages/other_view_profile.dart';
import 'package:edunest_app/features/profile/presentation/pages/view_profile.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class UserTile extends StatefulWidget {
  final ProfileUser user;

  const UserTile({super.key, required this.user});

  @override
  State<UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<UserTile> {
  late ProfileUser _user;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  @override
  void didUpdateWidget(covariant UserTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.user.uid != widget.user.uid) {
      _user = widget.user;
    }
  }

  Future<void> _toggleFollow() async {
    final currentUid = context.read<AuthCubit>().currentUser?.uid;

    if (currentUid == null || _isLoading) return;

    if (currentUid == _user.uid) return;

    final isFollowing = _user.followers.contains(currentUid);

    // Optimistic UI
    setState(() {
      _isLoading = true;

      if (isFollowing) {
        _user = _user.copyWith(
          newFollowers: List<String>.from(_user.followers)..remove(currentUid),
        );
      } else {
        _user = _user.copyWith(
          newFollowers: List<String>.from(_user.followers)..add(currentUid),
        );
      }
    });

    try {
      await context.read<ProfileCubit>().toggleFollow(currentUid, _user.uid);
    } catch (e) {
      // Roll back if Firebase fails
      if (!mounted) return;

      setState(() {
        if (isFollowing) {
          _user = _user.copyWith(
            newFollowers: List<String>.from(_user.followers)..add(currentUid),
          );
        } else {
          _user = _user.copyWith(
            newFollowers: List<String>.from(_user.followers)
              ..remove(currentUid),
          );
        }
      });

      debugPrint('Follow error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentUser = context.read<AuthCubit>().currentUser;
    final currentUid = currentUser?.uid;

    final isCurrentUser = currentUid == _user.uid;

    // You follow this person
    final isFollowing = _user.followers.contains(currentUid);

    // This person follows you
    final isFollowedBy = _user.following.contains(currentUid);

    String buttonText;

    if (isCurrentUser) {
      buttonText = 'You';
    } else if (isFollowing) {
      buttonText = 'Following';
    } else if (isFollowedBy) {
      buttonText = 'Follow Back';
    } else {
      buttonText = 'Follow';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (isCurrentUser) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewProfile(
                    uid: _user.uid,
                    onDrawerOpened: () {},
                    onDrawerClosed: () {},
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtherViewProfile(uid: _user.uid),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Profile picture
                CircleProfile(imageurl: _user.profileImageUrl, size: 25),

                const SizedBox(width: 14),

                // User information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _user.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          if (isCurrentUser) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'You',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        _user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Follow button
                if (!isCurrentUser)
                  GestureDetector(
                    onTap: _toggleFollow,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isFollowing
                            ? colorScheme.surface
                            : colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.25),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isFollowing
                                    ? colorScheme.primary
                                    : Colors.white,
                              ),
                            )
                          : Text(
                              buttonText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isFollowing
                                    ? colorScheme.onSurface
                                    : Colors.white,
                              ),
                            ),
                    ),
                  ),

                if (isCurrentUser)
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.arrow_right_3,
                      size: 18,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
