import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/profile/presentation/components/cirecle_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class LikesBottomSheet extends StatefulWidget {
  final List<String> userIds;

  const LikesBottomSheet({super.key, required this.userIds});

  @override
  State<LikesBottomSheet> createState() => _LikesBottomSheetState();
}

class _LikesBottomSheetState extends State<LikesBottomSheet> {
  late final ProfileCubit profileCubit;

  List<ProfileUser> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    profileCubit = context.read<ProfileCubit>();

    loadLikedUsers();
  }

  Future<void> loadLikedUsers() async {
    final List<ProfileUser> loadedUsers = [];

    for (final uid in widget.userIds) {
      try {
        final user = await profileCubit.getUserProfile(uid);

        if (user != null) {
          loadedUsers.add(user);
        }
      } catch (e) {
        debugPrint('Error loading liked user $uid: $e');
      }
    }

    if (!mounted) return;

    setState(() {
      users = loadedUsers;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.65,
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 15),

            // Title
            const Text(
              'Likes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.heart, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'No likes yet',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color.fromARGB(255, 237, 229, 212),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 5,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 3,
                            ),

                            // Profile picture
                            leading: CircleProfile(
                              imageurl: user.profileImageUrl,
                              size: 25,
                            ),

                            // Name
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Email or bio
                            subtitle: user.major.isNotEmpty
                                ? Text(
                                    user.major,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,

                            // Heart
                            trailing: const Icon(
                              Iconsax.heart5,
                              size: 20,
                              color: Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
