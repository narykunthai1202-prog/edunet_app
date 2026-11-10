import 'package:bloc/bloc.dart';
import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/domain/repos/auth_repo.dart';
import 'package:edunest_app/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';

import 'auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  final NotificationCubit notificationCubit;
  final PostCubit postCubit;
  final ProfileCubit profileCubit;

  AppUser? _currentUser;
  bool _authOperationInProgress = false;

  AuthCubit({
    required this.authRepo,
    required this.notificationCubit,
    required this.postCubit,
    required this.profileCubit,
  }) : super(AuthIntial());

  AppUser? get currentUser => _currentUser;

  bool _handleSuspendedUser(AppUser user) {
    if (user.isSuspended &&
        (user.suspendedUntil == null ||
            user.suspendedUntil!.isAfter(DateTime.now()))) {
      emit(
        AccountSuspended(
          user: user,
          reason: user.suspensionReason,
          suspendedUntil: user.suspendedUntil,
        ),
      );
      return true;
    }
    return false;
  }

  String _messageFromError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _completeAuthentication(AppUser user) async {
    _currentUser = user;

    if (_handleSuspendedUser(user)) return;

    if (await authRepo.needsGoogleProfileCompletion(user.uid)) {
      emit(NeedsProfileCompletion(user: user));
      return;
    }

    notificationCubit.fetchNotifications(user.uid);
    emit(Authenticated(user: user));
  }

  Future<void> login(String email, String password) async {
    if (_authOperationInProgress) return;
    _authOperationInProgress = true;
    emit(AuthLoading());

    try {
      final user = await authRepo.loginWitheEmailPassword(
        email: email,
        password: password,
      );

      if (user == null) {
        _currentUser = null;
        notificationCubit.clearNotifications();
        emit(Unauthenticated());
        return;
      }

      _currentUser = user;
      if (await authRepo.needsEmailVerification()) {
        emit(EmailVerificationPending(email: user.email));
        return;
      }

      await _completeAuthentication(user);
    } catch (error) {
      emit(AuthError(message: _messageFromError(error)));
    } finally {
      _authOperationInProgress = false;
    }
  }

  Future<void> signInWithGoogle() async {
    if (_authOperationInProgress) return;
    _authOperationInProgress = true;
    emit(AuthLoading());

    try {
      final user = await authRepo.signInWithGoogle();
      if (user == null) {
        _currentUser = null;
        emit(Unauthenticated());
        return;
      }

      await _completeAuthentication(user);
    } catch (error) {
      emit(AuthError(message: _messageFromError(error)));
    } finally {
      _authOperationInProgress = false;
    }
  }

  Future<void> register(String name, String email, String password) async {
    if (_authOperationInProgress) return;
    _authOperationInProgress = true;
    emit(AuthLoading());

    try {
      final user = await authRepo.registerWithEmailPassword(
        email: email,
        password: password,
        name: name,
      );

      if (user == null) {
        _currentUser = null;
        emit(Unauthenticated());
        return;
      }

      _currentUser = user;
      try {
        await authRepo.sendEmailVerification();
        emit(NeedsProfileCompletion(user: user));
      } catch (error) {
        emit(
          NeedsProfileCompletion(
            user: user,
            message:
                'Could not send the verification email: ${_messageFromError(error)}',
          ),
        );
      }
    } catch (error) {
      emit(AuthError(message: _messageFromError(error)));
    } finally {
      _authOperationInProgress = false;
    }
  }

  Future<void> logout() async {
    await notificationCubit.clearNotifications();
    profileCubit.clearProfile();
    _currentUser = null;
    await authRepo.logout();
    postCubit.fetchAllPostsbypublic();
    emit(Unauthenticated());
  }

  Future<void> checkAuth() async {
    if (_authOperationInProgress) return;
    _authOperationInProgress = true;

    try {
      final needsVerification = await authRepo.needsEmailVerification();
      final user = await authRepo.getCurrentUser();

      if (user == null) {
        _currentUser = null;
        notificationCubit.clearNotifications();
        postCubit.fetchAllPostsbypublic();
        emit(Unauthenticated());
        return;
      }

      _currentUser = user;
      if (needsVerification) {
        emit(EmailVerificationPending(email: user.email));
        return;
      }

      await _completeAuthentication(user);
    } catch (error) {
      emit(AuthError(message: _messageFromError(error)));
    } finally {
      _authOperationInProgress = false;
    }
  }

  Future<void> completeProfile({
    required String name,
    required String major,
    required String university,
  }) async {
    final user = _currentUser;
    if (user == null) {
      emit(AuthError(message: 'Please sign in again.'));
      return;
    }

    if (name.trim().isEmpty ||
        major.trim().isEmpty ||
        university.trim().isEmpty) {
      emit(AuthError(message: 'Please complete all required fields.'));
      return;
    }

    if (_authOperationInProgress) return;
    _authOperationInProgress = true;
    emit(AuthLoading());

    try {
      await authRepo.completeProfile(
        uid: user.uid,
        email: user.email,
        name: name.trim(),
        major: major.trim(),
        university: university.trim(),
      );

      final updatedUser = await authRepo.getCurrentUser();
      if (updatedUser == null) {
        throw StateError('Unable to load the completed profile.');
      }

      if (await authRepo.needsEmailVerification()) {
        emit(
          EmailVerificationPending(
            email: updatedUser.email,
            message: 'Your profile is complete. Verify your email to continue.',
          ),
        );
        return;
      }

      await _completeAuthentication(updatedUser);
    } catch (error) {
      emit(AuthError(message: _messageFromError(error)));
    } finally {
      _authOperationInProgress = false;
    }
  }

  Future<void> resendVerificationEmail() async {
    if (_authOperationInProgress) return;
    _authOperationInProgress = true;

    final user = _currentUser;
    if (user == null) {
      _authOperationInProgress = false;
      emit(AuthError(message: 'Please sign in again to resend the email.'));
      return;
    }

    try {
      await authRepo.sendEmailVerification();
      emit(
        EmailVerificationPending(
          email: user.email,
          message: 'A verification email was sent. Check your inbox and spam folder.',
        ),
      );
    } catch (error) {
      emit(
        EmailVerificationPending(
          email: user.email,
          message: _messageFromError(error),
        ),
      );
    } finally {
      _authOperationInProgress = false;
    }
  }

  Future<void> checkEmailVerification() async {
    if (_authOperationInProgress) return;
    _authOperationInProgress = true;
    emit(AuthLoading());

    try {
      if (await authRepo.needsEmailVerification()) {
        emit(
          EmailVerificationPending(
            email: _currentUser?.email ?? '',
            message: 'Your email is not verified yet. Check your inbox, then try again.',
          ),
        );
        return;
      }

      final user = await authRepo.getCurrentUser();
      if (user == null) {
        _currentUser = null;
        emit(Unauthenticated());
        return;
      }

      await _completeAuthentication(user);
    } catch (error) {
      emit(
        EmailVerificationPending(
          email: _currentUser?.email ?? '',
          message: _messageFromError(error),
        ),
      );
    } finally {
      _authOperationInProgress = false;
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return authRepo.sendPasswordResetEmail(email: email);
  }
}
