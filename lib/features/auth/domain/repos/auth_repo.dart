import 'package:edunest_app/features/auth/domain/entities/app_user.dart';

abstract class AuthRepo {
  Future<AppUser?> loginWitheEmailPassword({
    required String email,
    required String password,
  });
  Future<AppUser?> registerWithEmailPassword({
    required String email,
    required String password,
    required String name,
  });
  Future<void> logout();
  Future<AppUser?> getCurrentUser();
  Future<AppUser?> signInWithGoogle();
  Future<bool> needsGoogleProfileCompletion(String uid);

Future<void> completeGoogleProfile({
  required String uid,
  required String email,
  required String name,
  required String major,
  required String university,
});

}
