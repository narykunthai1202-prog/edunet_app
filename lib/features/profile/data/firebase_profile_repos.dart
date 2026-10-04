import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/core/services/cloudinary_services.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import 'package:edunest_app/features/profile/domain/repos/profile_repo.dart';

class FirebaseProfileRepos implements ProfileRepo {
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final cloudinaryService = CloudinaryService.instance;
  @override
  Future<ProfileUser?> fetchUserProfile(String uid) async {
    try {
      final userDoc = await firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        print("Document does not exist");
        return null;
      }

      final data = userDoc.data();

      if (data == null) return null;

      print(data);
      final followers = List<String>.from(data['followers'] ?? []);
      final following = List<String>.from(data['following'] ?? []);

      return ProfileUser(
        uid: uid,
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        bio: data['bio'] ?? '',
        profileImageUrl: data['profileImageUrl'] ?? '',
        followers: followers,
        following: following,
        dateofbirth: data['dateofbirth'] ?? '',
        gender: data['gender'] ?? '',
        phoneNumber: data['phoneNumber'] ?? '',
        address: data['address'] ?? '',
        university: data['university'] ?? '',
        major: data['major'] ?? '',
        years: data['years'] ?? '',
        semester: data['semester'] ?? '',
        hobbies: data['hobbies'] ?? '',
        nickname: data['nickname'] ?? '',
        relationshipStatus: data['relationshipStatus'] ?? '',
      );
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  @override
  Future<void> updateProfile(ProfileUser updateProfile) async {
    try {
      //convert update profile to json
      await firebaseFirestore.collection('users').doc(updateProfile.uid).update(
        {
          'name': updateProfile.name,
          'email': updateProfile.email,
          'bio': updateProfile.bio,
          'profileImageUrl': updateProfile.profileImageUrl,
          'dateofbirth': updateProfile.dateofbirth,
          'gender': updateProfile.gender,
          'phoneNumber': updateProfile.phoneNumber,
          'address': updateProfile.address,
          'university': updateProfile.university,
          'major': updateProfile.major,
          'years': updateProfile.years,
          'semester': updateProfile.semester,
          'hobbies': updateProfile.hobbies,
          'nickname': updateProfile.nickname,
          'relationshipStatus': updateProfile.relationshipStatus,
        },
      );
    } catch (e) {
      throw Exception(e);
    }
  }

  @override
  Future<String> uploadProfileImage(File image) async {
    final result = await cloudinaryService.uploadImage(image);

    if (result.success && result.imageUrl != null) {
      return result.imageUrl!;
    }

    throw Exception(result.error ?? "Image upload failed");
  }

  @override
  Future<void> toggleFollow(String currentuid, String targetuid) async {
    try {
      final currentUserDoc = await firebaseFirestore
          .collection('users')
          .doc(currentuid)
          .get();
      final targetUserDoc = await firebaseFirestore
          .collection('users')
          .doc(targetuid)
          .get();
      if (currentUserDoc.exists && targetUserDoc.exists) {
        final currentUserData = currentUserDoc.data();
        final targetUserData = targetUserDoc.data();
        if (currentUserData != null && targetUserData != null) {
          final List<String> currentFollowing = List<String>.from(
            currentUserData['following'] ?? [],
          );
          //unfollow
          if (currentFollowing.contains(targetuid)) {
            await firebaseFirestore.collection('users').doc(currentuid).update({
              'following': FieldValue.arrayRemove([targetuid]),
            });
            await firebaseFirestore.collection('users').doc(targetuid).update({
              'followers': FieldValue.arrayRemove([currentuid]),
            });
          } else {
            //follow
            await firebaseFirestore.collection('users').doc(currentuid).update({
              'following': FieldValue.arrayUnion([targetuid]),
            });
            await firebaseFirestore.collection('users').doc(targetuid).update({
              'followers': FieldValue.arrayUnion([currentuid]),
            });
          }
        }
      }
    } catch (e) {
      print("toggleFollow error: $e");
      rethrow;
    }
  }

  @override
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .get();

      if (!doc.exists) {
        return false;
      }

      final data = doc.data();

      final following = List<String>.from(data?['following'] ?? []);

      return following.contains(targetUserId);
    } catch (e) {
      throw Exception('Failed to check following status: $e');
    }
  }

  @override
  Future<List<ProfileUser>> fetchAllUsers() async {
    try {
      final snapshot = await firebaseFirestore.collection('users').get();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        return ProfileUser(
          uid: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          bio: data['bio'] ?? '',
          profileImageUrl: data['profileImageUrl'] ?? '',
          followers: List<String>.from(data['followers'] ?? []),
          following: List<String>.from(data['following'] ?? []),
          dateofbirth: data['dateofbirth'] ?? '',
          gender: data['gender'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          address: data['address'] ?? '',
          university: data['university'] ?? '',
          major: data['major'] ?? '',
          years: data['years'] ?? '',
          semester: data['semester'] ?? '',
          hobbies: data['hobbies'] ?? '',
          nickname: data['nickname'] ?? '',
          relationshipStatus: data['relationshipStatus'] ?? '',
        );
      }).toList();
    } catch (e) {
      print('fetchAllUsers error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProfileUser>> fetchPeopleYouDontFollowBack(
    String currentUserId,
  ) async {
    try {
      final currentUser = await fetchUserProfile(currentUserId);

      if (currentUser == null) {
        return [];
      }

      final snapshot = await firebaseFirestore.collection('users').get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();

        return ProfileUser(
          uid: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          bio: data['bio'] ?? '',
          profileImageUrl: data['profileImageUrl'] ?? '',
          followers: List<String>.from(data['followers'] ?? []),
          following: List<String>.from(data['following'] ?? []),
          dateofbirth: data['dateofbirth'] ?? '',
          gender: data['gender'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          address: data['address'] ?? '',
          university: data['university'] ?? '',
          major: data['major'] ?? '',
          years: data['years'] ?? '',
          semester: data['semester'] ?? '',
          hobbies: data['hobbies'] ?? '',
          nickname: data['nickname'] ?? '',
          relationshipStatus: data['relationshipStatus'] ?? '',
        );
      }).toList();

      return users.where((user) {
        // Don't show yourself
        if (user.uid == currentUserId) {
          return false;
        }

        // They follow you
        final theyFollowMe = user.following.contains(currentUserId);

        // You don't follow them
        final youFollowThem = currentUser.following.contains(user.uid);

        return theyFollowMe && !youFollowThem;
      }).toList();
    } catch (e) {
      print('fetchPeopleYouDontFollowBack error: $e');
      rethrow;
    }
  }

  @override
  Future<List<ProfileUser>> fetchSuggestedUsers(String currentUserId) async {
    try {
      final currentUser = await fetchUserProfile(currentUserId);

      if (currentUser == null) return [];

      final snapshot = await firebaseFirestore.collection('users').get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();

        return ProfileUser(
          uid: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          bio: data['bio'] ?? '',
          profileImageUrl: data['profileImageUrl'] ?? '',
          followers: List<String>.from(data['followers'] ?? []),
          following: List<String>.from(data['following'] ?? []),
          dateofbirth: data['dateofbirth'] ?? '',
          gender: data['gender'] ?? '',
          phoneNumber: data['phoneNumber'] ?? '',
          address: data['address'] ?? '',
          university: data['university'] ?? '',
          major: data['major'] ?? '',
          years: data['years'] ?? '',
          semester: data['semester'] ?? '',
          hobbies: data['hobbies'] ?? '',
          nickname: data['nickname'] ?? '',
          relationshipStatus: data['relationshipStatus'] ?? '',
        );
      }).toList();

      return users.where((user) {
        // Don't show yourself
        if (user.uid == currentUserId) return false;

        // Don't show people you already follow
        if (currentUser.following.contains(user.uid)) {
          return false;
        }

        // Don't show people who already follow you
        if (user.following.contains(currentUserId)) {
          return false;
        }

        return true;
      }).toList();
    } catch (e) {
      print('fetchSuggestedUsers error: $e');
      rethrow;
    }
  }
}
