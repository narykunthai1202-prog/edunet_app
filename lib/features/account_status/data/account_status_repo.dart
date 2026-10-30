import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:edunest_app/features/auth/domain/entities/app_user.dart';

class AccountStatusRepo {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  /// Fetches the latest user account status from Firestore
  Future<AppUser?> fetchAccountStatus(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['uid'] = uid;
      return AppUser.fromJson(data);
    } catch (e) {
      throw Exception('Failed to load account status: $e');
    }
  }

  /// Administrator action: Suspend a user account
  Future<void> suspendAccount({
    required String targetUid,
    required String reason,
    DateTime? suspendedUntil,
  }) async {
    try {
      await _firestore.collection('users').doc(targetUid).update({
        'isSuspended': true,
        'suspensionReason': reason,
        'suspendedAt': FieldValue.serverTimestamp(),
        'suspendedUntil': suspendedUntil != null
            ? Timestamp.fromDate(suspendedUntil)
            : null,
      });
    } catch (e) {
      throw Exception('Failed to suspend account: $e');
    }
  }

  /// Administrator action: Reinstate a suspended user account
  Future<void> reinstateAccount(String targetUid) async {
    try {
      await _firestore.collection('users').doc(targetUid).update({
        'isSuspended': false,
        'suspensionReason': FieldValue.delete(),
        'suspendedAt': FieldValue.delete(),
        'suspendedUntil': FieldValue.delete(),
      });
    } catch (e) {
      throw Exception('Failed to reinstate account: $e');
    }
  }

  /// Permanently deletes the user account and cascading data
  Future<void> deleteAccount({
    String? currentPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final uid = user.uid;

    // 1. Re-authenticate before sensitive deletion
    final isGoogleUser = user.providerData
        .any((p) => p.providerId == 'google.com');

    if (isGoogleUser) {
      final googleSignIn = GoogleSignIn.instance;
      final googleAccount = await googleSignIn.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken != null) {
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        await user.reauthenticateWithCredential(credential);
      }
    } else if (currentPassword != null && currentPassword.isNotEmpty) {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
    } else {
      throw Exception(
        'Password re-authentication is required to delete your account.',
      );
    }

    // 2. Cascade delete all posts owned by this user
    final userPosts = await _firestore
        .collection('posts')
        .where('userId', isEqualTo: uid)
        .get();

    for (final doc in userPosts.docs) {
      await doc.reference.delete();
    }

    // 3. Cascade delete notifications for and from this user
    final receivedNotifications = await _firestore
        .collection('notifications')
        .where('receiverId', isEqualTo: uid)
        .get();
    for (final doc in receivedNotifications.docs) {
      await doc.reference.delete();
    }

    final sentNotifications = await _firestore
        .collection('notifications')
        .where('senderId', isEqualTo: uid)
        .get();
    for (final doc in sentNotifications.docs) {
      await doc.reference.delete();
    }

    // 4. Delete blocked subcollection
    final blockedDocs = await _firestore
        .collection('users')
        .doc(uid)
        .collection('blocked')
        .get();
    for (final doc in blockedDocs.docs) {
      await doc.reference.delete();
    }

    // 5. Delete Firestore user document
    await _firestore.collection('users').doc(uid).delete();

    // 6. Delete Firebase Auth user
    await user.delete();
  }
}
