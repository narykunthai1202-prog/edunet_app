import 'package:firebase_auth/firebase_auth.dart';

/// Everything related to "who is the current user" lives here, separate
/// from the todo data logic in TodoService.
///
/// ⚠️ MERGE NOTE FOR TEAMMATE'S AUTH MODULE ⚠️
/// This file currently only does ANONYMOUS sign-in, which is fine for
/// standalone testing of the Todo feature. When merging with your
/// teammate's real Authentication (email/Google/etc.), you have two options:
///
///   1. RECOMMENDED: Replace this whole file with your teammate's
///      AuthService, as long as it exposes the same two members used
///      elsewhere in this module:
///        - `AuthService.currentUserId` (used by TodoService)
///        - `AuthService.authStateChanges` (used by app.dart)
///
///   2. If you want to keep a "try the app without an account" guest mode,
///      upgrade an anonymous user to a real account instead of creating a
///      brand new uid, so their todos aren't lost on login:
///        final credential = EmailAuthProvider.credential(email: e, password: p);
///        await FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
///
/// Do NOT run two separate `signInAnonymously()` / real-login flows at the
/// same time — pick one AuthService for the whole merged app.
class AuthService {
  AuthService._();

  /// Signs the device in anonymously if it isn't already signed in.
  /// Anonymous auth still gives a stable, unique `uid` per device/install,
  /// which is all we need to keep each person's todos private.
  static Future<void> ensureSignedIn() async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }
  }

  static String get currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError(
        'No signed-in user yet. Call AuthService.ensureSignedIn() first '
        '(this is already done once in main.dart before runApp).',
      );
    }
    return user.uid;
  }

  static Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();
}
