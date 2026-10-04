import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/domain/repos/auth_repo.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthRepos implements AuthRepo {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore =
      FirebaseFirestore.instance;

  // ============================================================
  // GET CURRENT USER
  // ============================================================
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

      // If Firestore profile does not exist,
      // still return the Firebase Auth user.
      if (!doc.exists) {
        return AppUser(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? "",
          name: firebaseUser.displayName ?? "User",
        );
      }

      final data = doc.data() as Map<String, dynamic>?;

      return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? "",
        name: data?['name']?.toString() ??
            firebaseUser.displayName ??
            "User",
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
      );
    }
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  @override
  Future<void> logout() async {
    await firebaseAuth.signOut();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  @override
  Future<AppUser?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final UserCredential userCredential =
          await firebaseAuth.createUserWithEmailAndPassword(
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

      throw Exception(
        "Firebase register error: ${e.code} - ${e.message}",
      );
    } catch (e) {
      print("REGISTER ERROR: $e");

      throw Exception(
        "Failed to register: $e",
      );
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

      final UserCredential userCredential =
          await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        print("LOGIN FAILED: Firebase user is null");
        return null;
      }

      print("FIREBASE LOGIN SUCCESS");
      print("UID: ${firebaseUser.uid}");
      print("Email: ${firebaseUser.email}");

      // --------------------------------------------------------
      // 2. Get Firestore profile
      // --------------------------------------------------------

      final DocumentSnapshot userDoc =
          await firebaseFirestore
              .collection("users")
              .doc(firebaseUser.uid)
              .get();

      // --------------------------------------------------------
      // 3. If profile does not exist, create one
      // --------------------------------------------------------

      if (!userDoc.exists) {
        print(
          "Firestore user document does not exist. Creating it...",
        );

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

      final data =
          userDoc.data() as Map<String, dynamic>?;

      final String name =
          data?['name']?.toString() ??
          firebaseUser.displayName ??
          "User";

      final AppUser user = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email.trim(),
        name: name,
      );

      print("LOGIN COMPLETED SUCCESSFULLY");
      print("Name: ${user.name}");
      print("========================================");

      return user;
    }

    // ==========================================================
    // FIREBASE AUTH ERROR
    // ==========================================================

    on FirebaseAuthException catch (e) {
      print("========================================");
      print("FIREBASE LOGIN ERROR");
      print("CODE: ${e.code}");
      print("MESSAGE: ${e.message}");
      print("========================================");

      throw Exception(
        "Firebase login error: ${e.code} - ${e.message}",
      );
    }

    // ==========================================================
    // OTHER ERROR
    // ==========================================================

    catch (e) {
      print("========================================");
      print("LOGIN ERROR");
      print(e);
      print("========================================");

      throw Exception(
        "Failed to login: $e",
      );
    }
  }
}

