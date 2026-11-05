import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/domain/repos/auth_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepos implements AuthRepo {
  static final Future<void> _googleSignInInitialization = GoogleSignIn.instance
      .initialize(
        serverClientId: '16916775507-1f86dft3upsojobbeiqn8k16psnv4b0g.apps.googleusercontent.com',
      );
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  AppUser _appUserFromFirebaseUser(
    User firebaseUser, [
    Map<String, dynamic>? data,
  ]) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: data?['name']?.toString() ?? firebaseUser.displayName ?? 'User',
      isSuspended: data?['isSuspended'] == true,
      suspensionReason: data?['suspensionReason']?.toString(),
      suspendedAt: parseDate(data?['suspendedAt']),
      suspendedUntil: parseDate(data?['suspendedUntil']),
      role: data?['role']?.toString() ?? 'user',
      createdAt:
          parseDate(data?['createdAt']) ?? firebaseUser.metadata.creationTime,
    );
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return null;
    }

    final isEmailPasswordUser = firebaseUser.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    if (isEmailPasswordUser) {
      if (!firebaseUser.emailVerified) {
        return _appUserFromFirebaseUser(firebaseUser);
      }
      await firebaseUser.getIdToken(true);
    }

    final userRef = firebaseFirestore.collection('users').doc(firebaseUser.uid);
    return firebaseFirestore.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (userDoc.exists) {
        final existingData = userDoc.data() ?? <String, dynamic>{};
        final user = _appUserFromFirebaseUser(firebaseUser, existingData);
        final missingFields = <String, dynamic>{};

        if ((existingData['uid']?.toString().trim() ?? '').isEmpty) {
          missingFields['uid'] = user.uid;
        }
        if ((existingData['email']?.toString().trim() ?? '').isEmpty) {
          missingFields['email'] = user.email;
        }
        if ((existingData['name']?.toString().trim() ?? '').isEmpty) {
          missingFields['name'] = user.name;
        }
        if (existingData['isSuspended'] == null) {
          missingFields['isSuspended'] = user.isSuspended;
        }
        if ((existingData['role']?.toString().trim() ?? '').isEmpty) {
          missingFields['role'] = user.role;
        }
        if (existingData['createdAt'] == null && user.createdAt != null) {
          missingFields['createdAt'] = Timestamp.fromDate(user.createdAt!);
        }

        if (missingFields.isNotEmpty) {
          transaction.set(userRef, missingFields, SetOptions(merge: true));
        }
        return _appUserFromFirebaseUser(firebaseUser, {
          ...existingData,
          ...missingFields,
        });
      }

      final user = _appUserFromFirebaseUser(firebaseUser);
      transaction.set(userRef, user.toJson());
      return user;
    });
  }

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<AppUser?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential userCredential = await firebaseAuth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        return null;
      }

      await firebaseUser.updateDisplayName(name.trim());

      final AppUser user = AppUser(
        uid: firebaseUser.uid,
        email: email.trim(),
        name: name.trim(),
        createdAt: DateTime.now(),
      );

      return user;
    } on FirebaseAuthException catch (e) {
      print("REGISTER FIREBASE ERROR: ${e.code}");
      print("REGISTER FIREBASE MESSAGE: ${e.message}");

      switch (e.code) {
        case 'email-already-in-use':
          throw Exception(
            'This email address is already registered. Please log in or reset your password.',
          );
        case 'invalid-email':
          throw Exception('The email address format is invalid.');
        case 'weak-password':
          throw Exception(
            'The password is too weak. Please ensure it has at least 8 characters with uppercase, lowercase, numbers, and special characters.',
          );
        case 'network-request-failed':
          throw Exception(
            'Network connection error. Please check your internet connection.',
          );
        case 'too-many-requests':
          throw Exception(
            'Too many requests. Please wait a moment before trying again.',
          );
        default:
          throw Exception(e.message ?? 'Failed to register: ${e.code}');
      }
    } catch (e) {
      print("REGISTER ERROR: $e");
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  @override
  Future<AppUser?> loginWitheEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      print("========================================");
      print("LOGIN START");
      print("Email: ${email.trim()}");
      print("========================================");

      // --------------------------------------------------------
      // 1. Firebase Authentication
      // --------------------------------------------------------

      final UserCredential userCredential = await firebaseAuth
          .signInWithEmailAndPassword(email: email.trim(), password: password);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print("LOGIN FAILED: Firebase user is null");
        return null;
      }

      await firebaseUser.reload();
      final refreshedUser = firebaseAuth.currentUser;
      if (refreshedUser == null) {
        throw StateError('Firebase user is no longer available.');
      }

      print("FIREBASE LOGIN SUCCESS");
      return await getCurrentUser();
    } on FirebaseAuthException catch (e) {
      print("========================================");
      print("FIREBASE LOGIN ERROR: ${e.code} - ${e.message}");
      print("========================================");

      switch (e.code) {
        case 'user-not-found':
          throw Exception('No account found for that email address.');
        case 'wrong-password':
          throw Exception('Incorrect password. Please try again.');
        case 'invalid-credential':
          throw Exception(
            'Invalid email or password. Please check your credentials.',
          );
        case 'invalid-email':
          throw Exception('Invalid email address format.');
        case 'user-disabled':
          throw Exception(
            'This account has been disabled. Please contact support.',
          );
        case 'too-many-requests':
          throw Exception(
            'Too many failed attempts. Please wait a moment before trying again.',
          );
        case 'network-request-failed':
          throw Exception(
            'Network connection error. Please check your internet connection.',
          );
        default:
          throw Exception(e.message ?? 'Login failed. Please try again.');
      }
    } catch (e) {
      print("========================================");
      print("LOGIN ERROR: $e");
      print("========================================");

      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    try {
      print('GOOGLE LOGIN: Initializing');

      await _googleSignInInitialization;

      final googleSignIn = GoogleSignIn.instance;

      if (!googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError(
          'Google sign-in is not supported on this platform.',
        );
      }

      print('GOOGLE LOGIN: Opening account picker');

      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      print('GOOGLE LOGIN: Account selected: ${googleUser.email}');

      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        throw StateError(
          'Google returned a null ID token. Check the Web client ID.',
        );
      }

      print('GOOGLE LOGIN: ID token received');

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw StateError('Firebase returned a null user.');
      }

      print('GOOGLE LOGIN: Firebase authentication succeeded');

      final userRef = firebaseFirestore
          .collection('users')
          .doc(firebaseUser.uid);

      final userDoc = await userRef.get();
      final userData = userDoc.data();

      DateTime? parseDate(dynamic value) {
        if (value is Timestamp) {
          return value.toDate();
        } else if (value is String) {
          return DateTime.tryParse(value);
        }
        return null;
      }

      final user = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? googleUser.email,
        name:
            userData?['name']?.toString() ??
            firebaseUser.displayName ??
            googleUser.displayName ??
            'User',
        isSuspended: userData?['isSuspended'] == true,
        suspensionReason: userData?['suspensionReason']?.toString(),
        suspendedAt: parseDate(userData?['suspendedAt']),
        suspendedUntil: parseDate(userData?['suspendedUntil']),
        role: userData?['role']?.toString() ?? 'user',
        createdAt:
            parseDate(userData?['createdAt']) ??
            firebaseUser.metadata.creationTime,
      );

      if (!userDoc.exists) {
        await userRef.set(user.toJson());
      }

      print('GOOGLE LOGIN: Completed successfully');

      return user;
    } catch (e, stackTrace) {
      print('GOOGLE LOGIN ERROR TYPE: ${e.runtimeType}');
      print('GOOGLE LOGIN ERROR DETAILS: $e');
      print('GOOGLE LOGIN STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<void> completeProfile({
    required String uid,
    required String email,
    required String name,
    required String major,
    required String university,
  }) async {
    await firebaseFirestore.collection('users').doc(uid).set({
      'email': email,
      'name': name,
      'major': major,
      'university': university,
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> needsGoogleProfileCompletion(String uid) async {
    final firebaseUser = firebaseAuth.currentUser;
    if (firebaseUser == null || firebaseUser.uid != uid) {
      return false; // User is not logged in or UID does not match
    }
    final isGoogleUser = firebaseUser.providerData.any(
      (provider) => provider.providerId == 'google.com',
    );
    if (!isGoogleUser) {
      return false; // User is not a Google user
    }
    final doc = await firebaseFirestore.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    final name = (data['name'] ?? '').toString().trim();
    final major = (data['major'] ?? '').toString().trim();
    final university = (data['university'] ?? '').toString().trim();
    return name.isEmpty || major.isEmpty || university.isEmpty;
  }
  // ============================================================
  // EMAIL VERIFICATION
  // ============================================================

  @override
  Future<bool> needsEmailVerification() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      return false; // No user is currently signed in
    }

    await user.reload();

    final refreshedUser = firebaseAuth.currentUser;
    if (refreshedUser == null) return false;

    final hasEmailPasswordProvider = refreshedUser.providerData.any(
      (provider) => provider.providerId == 'password',
    );
    return hasEmailPasswordProvider && !refreshedUser.emailVerified;
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = firebaseAuth.currentUser;
    if (user == null) {
      throw Exception("No user is currently signed in.");
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'too-many-requests':
          throw Exception(
            'Verification emails sent too frequently. Please wait a moment before trying again.',
          );
        case 'network-request-failed':
          throw Exception(
            'Network error. Please check your internet connection.',
          );
        default:
          throw Exception(e.message ?? 'Failed to send verification email.');
      }
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return;
        case 'invalid-email':
          throw Exception('Please enter a valid email address.');
        case 'too-many-requests':
          throw Exception(
            'Too many requests. Please wait a moment before trying again.',
          );
        case 'network-request-failed':
          throw Exception(
            'Network error. Please check your internet connection.',
          );
        default:
          throw Exception(
            'We could not send the reset email. Please try again later.',
          );
      }
    }
  }
}
