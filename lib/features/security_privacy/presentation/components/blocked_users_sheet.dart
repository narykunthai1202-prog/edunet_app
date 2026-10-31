import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import '../../data/firebase_security_privacy_repo.dart';

class BlockedUsersSheet extends StatefulWidget {
  final String currentUserId;

  const BlockedUsersSheet({
    super.key,
    required this.currentUserId,
  });

  @override
  State<BlockedUsersSheet> createState() => _BlockedUsersSheetState();
}

class _BlockedUsersSheetState extends State<BlockedUsersSheet> {
  final FirebaseSecurityPrivacyRepo _repo = FirebaseSecurityPrivacyRepo();
  List<ProfileUser> _blockedUsers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBlocked();
  }

  Future<void> _loadBlocked() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repo.fetchBlockedUsers(widget.currentUserId);
      if (!mounted) return;
      setState(() {
        _blockedUsers = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _unblock(ProfileUser user) async {
    try {
      await _repo.unblockUser(widget.currentUserId, user.uid);
      setState(() {
        _blockedUsers.removeWhere((u) => u.uid == user.uid);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} has been unblocked.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unblock: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF242227) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Iconsax.user_cirlce_add, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                'Blocked Users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Blocked members cannot send you messages, join your group calls, or view your posts.',
            style: TextStyle(
              fontSize: 12.5,
              color: colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 18),

          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: colorScheme.primary),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    : _blockedUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.shield_tick,
                                  size: 42,
                                  color: colorScheme.secondary,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'No blocked users',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.inversePrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You have not blocked any members.',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: _blockedUsers.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 16),
                            itemBuilder: (context, index) {
                              final user = _blockedUsers[index];
                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: colorScheme.surface,
                                    backgroundImage: user.profileImageUrl.isNotEmpty
                                        ? CachedNetworkImageProvider(
                                            user.profileImageUrl,
                                          )
                                        : null,
                                    child: user.profileImageUrl.isEmpty
                                        ? Text(
                                            user.name.isNotEmpty
                                                ? user.name[0].toUpperCase()
                                                : 'U',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.primary,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.inversePrimary,
                                          ),
                                        ),
                                        if (user.major.isNotEmpty)
                                          Text(
                                            user.major,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: colorScheme.secondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colorScheme.primary,
                                      side: BorderSide(
                                        color: colorScheme.primary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                    ),
                                    onPressed: () => _unblock(user),
                                    child: const Text(
                                      'Unblock',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
