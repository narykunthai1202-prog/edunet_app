import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/notifications/domain/entities/notification.dart';
import 'package:edunest_app/features/notifications/domain/repositories/notification_repo.dart';
import 'package:edunest_app/features/post/domain/repos/post_repos.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/domain/repos/profile_repo.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_states.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProfileCubit extends Cubit<ProfileStates> {
  final ProfileRepo profileRepo;
  final NotificationRepo notificationRepo;
  final PostRepo postRepo;
  ProfileCubit({required this.profileRepo, required this.notificationRepo, required this.postRepo})
    : super(ProfileInitial());

  ProfileUser? get currentUser {
    final currentState = state;
    if (currentState is ProfileLoaded) {
      return currentState.profileUser;
    }
    return null;
  }

  //fetch user profile using repo
  Future<void> fetchUserProfile(String uid) async {
    if (uid.isEmpty) {
      emit(ProfileError("No user ID provided"));
      return;
    }
    try {
      emit(ProfileLoading());
      final user = await profileRepo.fetchUserProfile(uid);
      if (user != null) {
        emit(ProfileLoaded(user));
      } else {
        emit(ProfileError("User not Found"));
      }
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  //return user profile givern uid
  Future<ProfileUser?> getUserProfile(String uid) async {
    final user = await profileRepo.fetchUserProfile(uid);
    return user;
  }

  //update bio
  Future<void> updateProfile({
    required String uid,
    String? newBio,
    String? newName,
    String? newEmail,
    File? image,
    String? newDateofbirth,
    String? newGender,
    String? newPhoneNumber,
    String? newAddress,
    String? newUniversity,
    String? newMajor,
    String? newYears,
    String? newSemester,
    String? newHobbies,
    String? newNickname,
    String? newRelationshipStatus,
  }) async {
    emit(ProfileLoading());

    try {
      // Fetch current profile
      final currentUser = await profileRepo.fetchUserProfile(uid);

      if (currentUser == null) {
        emit(ProfileError("Failed to fetch user"));
        return;
      }

      // Keep old image unless a new one is selected
      String imageUrl = currentUser.profileImageUrl;

      if (image != null) {
        print("Uploading image...");
        imageUrl = await profileRepo.uploadProfileImage(image);
        print("Cloudinary URL: $imageUrl");
      } else {
        print("No image selected");
      }
      // Create updated profile
      final updatedProfile = currentUser.copyWith(
        newName: newName ?? currentUser.name,
        newEmail: newEmail ?? currentUser.email,
        newBio: newBio ?? currentUser.bio,
        newProfileImageUrl: imageUrl,
        newDateofbirth: newDateofbirth ?? currentUser.dateofbirth,
        newGender: newGender ?? currentUser.gender,
        newPhoneNumber: newPhoneNumber ?? currentUser.phoneNumber,
        newAddress: newAddress ?? currentUser.address,
        newUniversity: newUniversity ?? currentUser.university,
        newMajor: newMajor ?? currentUser.major,
        newYears: newYears ?? currentUser.years,
        newSemester: newSemester ?? currentUser.semester,
        newHobbies: newHobbies ?? currentUser.hobbies,
        newNickname: newNickname ?? currentUser.nickname,
        newRelationshipStatus:
            newRelationshipStatus ?? currentUser.relationshipStatus,
      );

      await profileRepo.updateProfile(updatedProfile);

      await fetchUserProfile(uid);
    } catch (e) {
      emit(ProfileError(e.toString()));
    }
  }

  Future<void> toggleFollow(String currentUserid, String targetUserId) async {
    try {
      // Follow or unfollow first
      await profileRepo.toggleFollow(currentUserid, targetUserId);

      // Don't notify yourself
      if (currentUserid == targetUserId) {
        return;
      }

      // Check the new follow status
      final isFollowing = await profileRepo.isFollowing(
        currentUserid,
        targetUserId,
      );

      if (isFollowing) {
        // User just FOLLOWED
        final senderProfile = await profileRepo.fetchUserProfile(currentUserid);

        final notification = Notification(
          id: FirebaseFirestore.instance.collection('notifications').doc().id,
          receiverId: targetUserId,
          senderId: currentUserid,
          type: 'follow',
          title: 'New Follower 👤',
          message: '${senderProfile?.name ?? 'Someone'} followed you',
          postId: null,
          isRead: false,
          senderProfileImageurl: senderProfile?.profileImageUrl ?? '',
          createdAt: Timestamp.now(),
        );

        await notificationRepo.createNotification(notification);
      } else {
        // User just UNFOLLOWED
        final existingNotification = await notificationRepo
            .getfollowNotification(currentUserid, targetUserId);

        if (existingNotification != null) {
          await notificationRepo.deleteNotification(existingNotification.id);
        }
      }
    } catch (e) {
      emit(ProfileError('Error toggling follow: $e'));
    }
  }

  Future<int> getPostCount(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .get();

    return snapshot.docs.length;
  }

  Future<List<ProfileUser>> fetchPeopleYouDontFollowBack(
    String currentUserId,
  ) async {
    return await profileRepo.fetchPeopleYouDontFollowBack(currentUserId);
  }

  Future<List<ProfileUser>> fetchSuggestedUsers(String currentUserId) async {
    return await profileRepo.fetchSuggestedUsers(currentUserId);
  }
  
}
