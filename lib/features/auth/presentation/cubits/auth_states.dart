import 'package:edunest_app/features/auth/domain/entities/app_user.dart';

abstract class AuthState {}

//initiall
class AuthIntial extends AuthState {}

//authenticating
class AuthLoading extends AuthState {}

//authenticated
class Authenticated extends AuthState {
  final AppUser user;
  Authenticated({required this.user});
}

//unauthenticated
class Unauthenticated extends AuthState {}

//errors
class AuthError extends AuthState {
  final String message;
  AuthError({required this.message});
}
