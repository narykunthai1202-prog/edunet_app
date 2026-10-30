import 'package:edunest_app/features/profile/domain/entities/profile_user.dart';

abstract class SecurityPrivacyRepo {
  // Password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  // Email
  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  });

  // OTP Verification
  Future<void> sendOtpCode({
    required String email,
    required String purpose,
  });

  Future<bool> verifyOtpCode({
    required String enteredCode,
    required String purpose,
  });

  // Blocked Users
  Future<List<ProfileUser>> fetchBlockedUsers(String currentUserId);
  Future<void> unblockUser(String currentUserId, String targetUserId);

  // Privacy Settings
  Future<Map<String, dynamic>> fetchPrivacySettings(String uid);
  Future<void> updatePrivacySettings(String uid, Map<String, dynamic> settings);
}
