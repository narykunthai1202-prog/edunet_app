import 'package:edunest_app/features/account_status/presentation/pages/account_suspended_page.dart';
import 'package:edunest_app/features/auth/data/firebase_auth_repos.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:edunest_app/features/auth/presentation/pages/auth_page.dart';
import 'package:edunest_app/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:edunest_app/features/auth/presentation/pages/email_verification_page.dart';
import 'package:edunest_app/features/chat/services/zego_service.dart'; // NEW
import 'package:edunest_app/features/home/presentation/page/home_page.dart';
import 'package:edunest_app/features/notifications/data/repositories/firebase_notification_repo.dart';
import 'package:edunest_app/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:edunest_app/features/post/data/firebase_post_repo.dart';
import 'package:edunest_app/features/post/data/firebase_report_repos.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/report_cubit.dart';
import 'package:edunest_app/features/profile/data/firebase_profile_repos.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/search/data/firebase_search_repo.dart';
import 'package:edunest_app/features/search/presentation/cubits/search_cubit.dart';
import 'package:edunest_app/core/cubits/theme_cubit.dart';
import 'package:edunest_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:edunest_app/themes/dark_mode.dart';
import 'package:edunest_app/themes/light_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;
  final bool seenOnboarding;

  const MyApp({
    super.key,
    required this.initialThemeMode,
    this.seenOnboarding = false,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _seenOnboarding;

  final authRepo = FirebaseAuthRepos();
  final profileRepo = FirebaseProfileRepos();
  final postRepo = FirebasePostRepo();
  final searchrepo = FirebaseSearchRepo();
  final notificationRepo = FirebaseNotificationRepo();
  final reportrepo = ReportRepo();

  @override
  void initState() {
    super.initState();
    _seenOnboarding = widget.seenOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    // Create these ONCE
    final notificationCubit = NotificationCubit(
      notificationRepo: notificationRepo,
    );

    final postCubit = PostCubit(
      postRepo: postRepo,
      notificationRepo: notificationRepo,
      profileRepo: profileRepo,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            profileRepo: profileRepo,
            notificationRepo: notificationRepo,
            postRepo: postRepo,
          ),
        ),

        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(
            authRepo: authRepo,
            notificationCubit: notificationCubit,
            postCubit: postCubit,
            profileCubit: context.read<ProfileCubit>(),
          )..checkAuth(),
        ),

        // Use the SAME PostCubit
        BlocProvider<PostCubit>.value(value: postCubit),

        BlocProvider<SearchCubit>(
          create: (context) => SearchCubit(searchrepo: searchrepo),
        ),

        // Use the SAME NotificationCubit
        BlocProvider<NotificationCubit>.value(value: notificationCubit),

        BlocProvider<ReportCubit>(
          create: (context) => ReportCubit(reportRepo: reportrepo),
        ),
        BlocProvider<ThemeCubit>(
          create: (context) => ThemeCubit(widget.initialThemeMode),
        ),
      ],

      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp(
          navigatorKey: navigatorKey, // NEW: lets the call screen open
          debugShowCheckedModeBanner: false,
          theme: lightMode,
          darkTheme: darkMode,
          themeMode: themeMode,

          home: BlocConsumer<AuthCubit, AuthState>(
            builder: (context, authState) {
              if (authState is Unauthenticated) {
                if (!_seenOnboarding) {
                  return OnboardingPage(
                    onFinish: () {
                      setState(() {
                        _seenOnboarding = true;
                      });
                    },
                  );
                }
                return const AuthPage();
              }

              if (authState is Authenticated) {
                return const HomePage();
              }

              if (authState is EmailVerificationPending) {
                return const EmailVerificationPage();
              }

              if (authState is NeedsProfileCompletion) {
                return CompleteProfilePage(user: authState.user);
              }

              if (authState is AccountSuspended) {
                return AccountSuspendedPage(
                  user: authState.user,
                  reason: authState.reason,
                  suspendedUntil: authState.suspendedUntil,
                );
              }

              if (authState is AuthError) {
                if (!_seenOnboarding) {
                  return OnboardingPage(
                    onFinish: () {
                      setState(() {
                        _seenOnboarding = true;
                      });
                    },
                  );
                }
                return const AuthPage();
              }

              if (authState is AuthLoading || authState is AuthIntial) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },

            listener: (context, state) {
              if (state is AuthError) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
          ),
        ),
      ),
    );
  }
}
