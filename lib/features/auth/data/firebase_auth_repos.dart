import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/domain/repos/auth_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthRepos implements AuthRepo {
  static final Future<void> _googleSignInInitialization =
    GoogleSignIn.instance.initialize(
  serverClientId: '16916775507-1f86dft3upsojobbeiqn8k16psnv4b0g.apps.googleusercontent.com',
);
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    try {
      final DocumentSnapshot doc = await firebaseFirestore
          .collection("users")
          .doc(firebaseUser.uid)
          .get();

      DateTime? parseDate(dynamic value) {
        if (value is Timestamp) {
          return value.toDate();
        } else if (value is String) {
          return DateTime.tryParse(value);
        }
        return null;
      }

      // If Firestore profile does not exist,
      // still return the Firebase Auth user.
      if (!doc.exists) {
        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? "",
          name: firebaseUser.displayName ?? "User",
          createdAt: firebaseUser.metadata.creationTime,
        );
      }

      final data = doc.data() as Map<String, dynamic>?;

      return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? "",
        name: data?['name']?.toString() ?? firebaseUser.displayName ?? "User",
        isSuspended: data?['isSuspended'] == true,
        suspensionReason: data?['suspensionReason']?.toString(),
        suspendedAt: parseDate(data?['suspendedAt']),
        suspendedUntil: parseDate(data?['suspendedUntil']),
        role: data?['role']?.toString() ?? 'user',
        createdAt:
            parseDate(data?['createdAt']) ?? firebaseUser.metadata.creationTime,
      );
    } catch (e) {
      print("GET CURRENT USER ERROR: $e");

      // Firebase Authentication succeeded,
      // so don't make the user appear logged out
      // just because Firestore profile loading failed.
      return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? "",
        name: firebaseUser.displayName ?? "User",
        createdAt: firebaseUser.metadata.creationTime,
      );
    }
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

      final AppUser user = AppUser(
        uid: firebaseUser.uid,
        email: email.trim(),
        name: name.trim(),
      );

      await firebaseFirestore
          .collection("users")
          .doc(user.uid)
          .set(user.toJson());

      return user;
    } on FirebaseAuthException catch (e) {
      print("REGISTER FIREBASE ERROR: ${e.code}");
      print("REGISTER FIREBASE MESSAGE: ${e.message}");

      throw Exception("Firebase register error: ${e.code} - ${e.message}");
    } catch (e) {
      print("REGISTER ERROR: $e");

      throw Exception("Failed to register: $e");
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

      print("FIREBASE LOGIN SUCCESS");
      print("UID: ${firebaseUser.uid}");
      print("Email: ${firebaseUser.email}");

      final DocumentSnapshot userDoc = await firebaseFirestore
          .collection("users")
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        print("Firestore user document does not exist. Creating it...");

        final AppUser user = AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? email.trim(),
          name: firebaseUser.displayName ?? "User",
        );

        await firebaseFirestore
            .collection("users")
            .doc(firebaseUser.uid)
            .set(user.toJson());

        print("Firestore user document created.");

        return user;
      }

      // --------------------------------------------------------
      // 4. Read existing Firestore profile safely
      // --------------------------------------------------------

      final data = userDoc.data() as Map<String, dynamic>?;

      DateTime? parseDate(dynamic value) {
        if (value is Timestamp) {
          return value.toDate();
        } else if (value is String) {
          return DateTime.tryParse(value);
        }
        return null;
      }

      final String name =
          data?['name']?.toString() ?? firebaseUser.displayName ?? "User";

      final AppUser user = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email.trim(),
        name: name,
        isSuspended: data?['isSuspended'] == true,
        suspensionReason: data?['suspensionReason']?.toString(),
        suspendedAt: parseDate(data?['suspendedAt']),
        suspendedUntil: parseDate(data?['suspendedUntil']),
        role: data?['role']?.toString() ?? 'user',
        createdAt:
            parseDate(data?['createdAt']) ?? firebaseUser.metadata.creationTime,
      );

      print("LOGIN COMPLETED SUCCESSFULLY");
      print("Name: ${user.name}");
      print("========================================");

      return user;
    }
    on FirebaseAuthException catch (e) {
      print("========================================");
      print("FIREBASE LOGIN ERROR");
      print("CODE: ${e.code}");
      print("MESSAGE: ${e.message}");
      print("========================================");

      throw Exception("Firebase login error: ${e.code} - ${e.message}");
    }
    catch (e) {
      print("========================================");
      print("LOGIN ERROR");
      print(e);
      print("========================================");

      throw Exception("Failed to login: $e");
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

    final GoogleSignInAccount googleUser =
        await googleSignIn.authenticate();

    print('GOOGLE LOGIN: Account selected: ${googleUser.email}');

    final idToken = googleUser.authentication.idToken;

    if (idToken == null) {
      throw StateError(
        'Google returned a null ID token. Check the Web client ID.',
      );
    }

    print('GOOGLE LOGIN: ID token received');

    final credential = GoogleAuthProvider.credential(
      idToken: idToken,
    );

    final userCredential =
        await firebaseAuth.signInWithCredential(credential);

    final firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw StateError('Firebase returned a null user.');
    }

    print('GOOGLE LOGIN: Firebase authentication succeeded');

    final userRef =
        firebaseFirestore.collection('users').doc(firebaseUser.uid);

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
      name: userData?['name']?.toString() ??
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
  Future<void> completeGoogleProfile({required String uid, required String email, required String name, required String major, required String university}) async {
    await firebaseFirestore.collection('users').doc(uid).set({
      'email': email,
      'name': name,
      'major': major,
      'university': university,
    }, SetOptions(merge: true));
  }

  @override
  Future<bool> needsGoogleProfileCompletion(String uid) async{
    final firebaseUser = firebaseAuth.currentUser;
    if(firebaseUser == null || firebaseUser.uid != uid) {
       return false; // User is not logged in or UID does not match
    }
    final isGoogleUser = firebaseUser.providerData.any((provider) => provider.providerId == 'google.com');
    if(!isGoogleUser) {
      return false; // User is not a Google user
    }
    final doc = await firebaseFirestore.collection('users').doc(uid).get();
    final data  = doc.data() ?? {};
    final name = (data['name'] ?? '').toString().trim();
    final major = (data['major'] ?? '').toString().trim();  
    final university = (data['university'] ?? '').toString().trim();
    return name.isEmpty || major.isEmpty || university.isEmpty;

  }
}
