import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/presentation/components/user_tile.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class RequestedSugessted extends StatefulWidget {
  const RequestedSugessted({super.key});

  @override
  State<RequestedSugessted> createState() => _RequestedSugesstedState();
}

class _RequestedSugesstedState extends State<RequestedSugessted> {
  List<ProfileUser> _peopleYouDontFollowBack = [];
  List<ProfileUser> _suggestedUsers = [];

  bool _loading = true;

  int _suggestedLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final currentUid = context.read<AuthCubit>().currentUser?.uid;

    if (currentUid == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    try {
      final profileCubit = context.read<ProfileCubit>();

      final peopleYouDontFollowBack = await profileCubit
          .fetchPeopleYouDontFollowBack(currentUid);

      final suggestedUsers = await profileCubit.fetchSuggestedUsers(currentUid);

      if (!mounted) return;

      setState(() {
        _peopleYouDontFollowBack = peopleYouDontFollowBack;

        _suggestedUsers = suggestedUsers;

        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      debugPrint('Find Mate error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final peopleYouDontFollowBackIds = _peopleYouDontFollowBack
        .map((user) => user.uid)
        .toSet();

    final filteredSuggested = _suggestedUsers.where((user) {
      return !peopleYouDontFollowBackIds.contains(user.uid);
    }).toList();

    final visibleSuggested = filteredSuggested.take(_suggestedLimit).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F1F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.arrow_left_2,
                        size: 19,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      'Find your Mate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                children: [
                  // PEOPLE YOU DON'T FOLLOW BACK
                  if (_peopleYouDontFollowBack.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      child: Text(
                        "People you don't follow back",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    ..._peopleYouDontFollowBack.map(
                      (user) => UserTile(user: user),
                    ),

                    const SizedBox(height: 20),
                  ],

                  // SUGGESTED FOR YOU
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Text(
                      'Suggested for you',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (visibleSuggested.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: Text('No suggestions available')),
                    ),

                  ...visibleSuggested.map((user) => UserTile(user: user)),

                  if (_suggestedLimit < filteredSuggested.length)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _suggestedLimit += 10;
                            });
                          },
                          child: const Text(
                            'See more',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
