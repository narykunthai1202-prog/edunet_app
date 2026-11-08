import 'package:edunest_app/features/auth/domain/entities/app_user.dart';

abstract class AuthState {}

// Initial
class AuthIntial extends AuthState {}

// Authenticating
class AuthLoading extends AuthState {}

// Authenticated
class Authenticated extends AuthState {
  final AppUser user;
  Authenticated({required this.user});
}

// Unauthenticated
class Unauthenticated extends AuthState {}

// Errors
class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}

class EmailVerificationPending extends AuthState {
  final String email;
  final String? message;

  EmailVerificationPending({required this.email, this.message});
}

class NeedsProfileCompletion extends AuthState {
  final AppUser user;
  final String? message;

  NeedsProfileCompletion({required this.user, this.message});
}

// Account Suspended State
class AccountSuspended extends AuthState {
  final AppUser user;
  final String? reason;
  final DateTime? suspendedUntil;

  AccountSuspended({required this.user, this.reason, this.suspendedUntil});
}
