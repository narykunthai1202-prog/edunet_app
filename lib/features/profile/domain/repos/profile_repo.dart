import 'dart:io';

import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';

abstract class ProfileRepo {
  Future<ProfileUser?> fetchUserProfile(String uid);
  Future<void> updateProfile(ProfileUser updateProfile);
  Future<String> uploadProfileImage(File image);
  Future<void> toggleFollow(String currentuid, String targetuid);
  Future<bool> isFollowing(String currentUserId, String targetUserId);
  Future<List<ProfileUser>> fetchAllUsers();

  Future<List<ProfileUser>> fetchPeopleYouDontFollowBack(String currentUserId);

  Future<List<ProfileUser>> fetchSuggestedUsers(String currentUserId);
}
