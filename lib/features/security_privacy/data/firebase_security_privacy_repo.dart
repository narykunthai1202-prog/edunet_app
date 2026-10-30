import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';
import '../domain/security_privacy_repo.dart';

class FirebaseSecurityPrivacyRepo implements SecurityPrivacyRepo {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User is not logged in.');
    }

    try {
      // 1. Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('The current password entered is incorrect.');
      } else if (e.code == 'weak-password') {
        throw Exception('The new password is too weak.');
      } else if (e.code == 'requires-recent-login') {
        throw Exception('Please log out and log in again before changing password.');
      }
      throw Exception('Failed to update password: ${e.message}');
    } catch (e) {
      throw Exception('Error changing password: $e');
    }
  }

  @override
  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('User is not logged in.');
    }

    try {
      // 1. Re-authenticate
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);

      // 2. Send verification to new email
      await user.verifyBeforeUpdateEmail(newEmail.trim());

      // 3. Store pending email in firestore
      await _firestore.collection('users').doc(user.uid).update({
        'pendingNewEmail': newEmail.trim(),
        'emailChangeRequestedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Incorrect current password.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('This email address is already in use by another account.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The new email address format is invalid.');
      }
      throw Exception('Failed to request email change: ${e.message}');
    } catch (e) {
      throw Exception('Error requesting email change: $e');
    }
  }

  @override
  Future<void> sendOtpCode({
    required String email,
    required String purpose,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    try {
      // Generate 6-digit random code
      final random = Random.secure();
      final codeInt = 100000 + random.nextInt(900000);
      final code = codeInt.toString();

      // Generate salt
      final saltBytes = List<int>.generate(16, (_) => random.nextInt(256));
      final salt = base64Encode(saltBytes);

      // Compute SHA-256 hash with salt
      final hash = sha256.convert(utf8.encode('$code$salt')).toString();

      // Expires in 10 minutes, max 5 attempts
      final expiresAt = DateTime.now().add(const Duration(minutes: 10));

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('security')
          .doc('otp_verification')
          .set({
        'hash': hash,
        'salt': salt,
        'expiresAt': Timestamp.fromDate(expiresAt),
        'attempts': 0,
        'maxAttempts': 5,
        'purpose': purpose,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Log the OTP securely for verification/testing
      debugPrint('==================================================');
      debugPrint('[EduNest OTP Code] For $email ($purpose): $code');
      debugPrint('Expires at: $expiresAt');
      debugPrint('==================================================');
    } catch (e) {
      throw Exception('Failed to generate verification code: $e');
    }
  }

  @override
  Future<bool> verifyOtpCode({
    required String enteredCode,
    required String purpose,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('User not logged in.');
    }

    try {
      final docRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('security')
          .doc('otp_verification');

      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        throw Exception('No active verification code found. Please request a new one.');
      }

      final data = snapshot.data()!;
      final expectedHash = data['hash'] as String? ?? '';
      final salt = data['salt'] as String? ?? '';
      final Timestamp? expiresTimestamp = data['expiresAt'] as Timestamp?;
      final int attempts = data['attempts'] as int? ?? 0;
      final int maxAttempts = data['maxAttempts'] as int? ?? 5;
      final String codePurpose = data['purpose'] as String? ?? '';

      if (codePurpose != purpose) {
        throw Exception('Invalid verification context.');
      }

      if (expiresTimestamp != null &&
          DateTime.now().isAfter(expiresTimestamp.toDate())) {
        await docRef.delete();
        throw Exception('Verification code has expired. Please request a new code.');
      }

      if (attempts >= maxAttempts) {
        await docRef.delete();
        throw Exception(
          'Too many failed attempts. For your security, this code has been invalidated.',
        );
      }

      // Check hash
      final enteredHash = sha256.convert(utf8.encode('$enteredCode$salt')).toString();

      if (enteredHash == expectedHash) {
        // Success: remove the OTP doc
        await docRef.delete();
        return true;
      } else {
        // Increment attempts
        await docRef.update({'attempts': attempts + 1});
        final remainingAttempts = maxAttempts - (attempts + 1);
        throw Exception(
          'Invalid verification code. $remainingAttempts ${remainingAttempts == 1 ? "attempt" : "attempts"} remaining.',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProfileUser>> fetchBlockedUsers(String currentUserId) async {
    try {
      final blockedDocs = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked')
          .get();

      if (blockedDocs.docs.isEmpty) return [];

      final List<ProfileUser> blockedUsers = [];

      for (final doc in blockedDocs.docs) {
        final peerId = doc.id;
        final userDoc = await _firestore.collection('users').doc(peerId).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          data['uid'] = peerId;
          blockedUsers.add(ProfileUser.fromJson(data));
        } else {
          // Placeholder user if deleted
          blockedUsers.add(ProfileUser(
            uid: peerId,
            email: '',
            name: 'EduNest User ($peerId)',
            bio: '',
            profileImageUrl: '',
            followers: [],
            following: [],
            dateofbirth: '',
            gender: '',
            phoneNumber: '',
            address: '',
            university: '',
            major: '',
            years: '',
            semester: '',
            hobbies: '',
            nickname: '',
            relationshipStatus: '',
          ));
        }
      }

      return blockedUsers;
    } catch (e) {
      throw Exception('Failed to fetch blocked users: $e');
    }
  }

  @override
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blocked')
          .doc(targetUserId)
          .delete();
    } catch (e) {
      throw Exception('Failed to unblock user: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchPrivacySettings(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return _defaultPrivacySettings;
      }
      final data = doc.data();
      final settings = data?['privacySettings'] as Map<String, dynamic>?;
      if (settings == null) {
        return _defaultPrivacySettings;
      }
      return {
        ..._defaultPrivacySettings,
        ...settings,
      };
    } catch (e) {
      return _defaultPrivacySettings;
    }
  }

  @override
  Future<void> updatePrivacySettings(
    String uid,
    Map<String, dynamic> settings,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'privacySettings': settings,
      });
    } catch (e) {
      throw Exception('Failed to update privacy settings: $e');
    }
  }

  static const Map<String, dynamic> _defaultPrivacySettings = {
    'profileVisibility': 'Public', // 'Public', 'Friends Only', 'Private'
    'defaultPostPrivacy': 'Public', // 'Public', 'Friend', 'private'
    'allowTagging': true,
    'showEmail': false,
  };
}
