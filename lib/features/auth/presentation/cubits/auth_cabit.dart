import 'package:bloc/bloc.dart';
import 'package:edunest_app/features/auth/domain/entities/app_user.dart';
import 'package:edunest_app/features/auth/domain/repos/auth_repo.dart';
import 'package:edunest_app/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';

import 'auth_states.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepo authRepo;
  final NotificationCubit notificationCubit;
  final PostCubit postCubit;

  AppUser? _currentUser;

  AuthCubit({required this.authRepo, required this.notificationCubit,required this.postCubit})
    : super(AuthIntial());

  // Check if user is already authenticated
  void checkAuth() async {
    final AppUser? user = await authRepo.getCurrentUser();

    if (user != null) {
      _currentUser = user;

      // Load notifications for this user
      notificationCubit.fetchNotifications(user.uid);

      emit(Authenticated(user: user));
    } else {
      _currentUser = null;
      notificationCubit.clearNotifications();
      postCubit.fetchAllPostsbypublic();

      emit(Unauthenticated());
    }
  }

  // Get current user
  AppUser? get currentUser => _currentUser;

  // Login
  Future<void> login(String email, String pw) async {
    try {
      emit(AuthLoading());

      final AppUser? user = await authRepo.loginWitheEmailPassword(
        email: email,
        password: pw,
      );

      if (user != null) {
        _currentUser = user;

        // Load notifications for the new account
        notificationCubit.fetchNotifications(user.uid);

        emit(Authenticated(user: user));
      } else {
        _currentUser = null;
        notificationCubit.clearNotifications();

        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // Register
  Future<void> register(String name, String email, String pw) async {
    try {
      emit(AuthLoading());

      final AppUser? user = await authRepo.registerWithEmailPassword(
        name: name,
        email: email,
        password: pw,
      );

      if (user != null) {
        _currentUser = user;

        // Load notifications for this new account
        notificationCubit.fetchNotifications(user.uid);

        emit(Authenticated(user: user));
      } else {
        _currentUser = null;
        notificationCubit.clearNotifications();
        postCubit.fetchAllPostsbypublic();

        emit(Unauthenticated());
      }
    } catch (e) {
      emit(AuthError(message: e.toString()));
    }
  }

  // Logout
  Future<void> logout() async {
    await notificationCubit.clearNotifications();

    _currentUser = null;

    await authRepo.logout();

    emit(Unauthenticated());
  }
}
