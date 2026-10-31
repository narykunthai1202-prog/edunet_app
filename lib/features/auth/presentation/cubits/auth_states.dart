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

class NeedsProfileCompletion extends AuthState {
  final AppUser user;

  NeedsProfileCompletion({required this.user});
}

// Account Suspended State
class AccountSuspended extends AuthState {
  final AppUser user;
  final String? reason;
  final DateTime? suspendedUntil;

  AccountSuspended({
    required this.user,
    this.reason,
    this.suspendedUntil,
  });
}
