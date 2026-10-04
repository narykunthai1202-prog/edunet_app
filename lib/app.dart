import 'package:edunest_app/features/auth/data/firebase_auth_repos.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_states.dart';
import 'package:edunest_app/features/auth/presentation/pages/auth_page.dart';
import 'package:edunest_app/features/home/presentation/page/home_page.dart';
import 'package:edunest_app/features/notifications/data/repositories/firebase_notification_repo.dart';
import 'package:edunest_app/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:edunest_app/features/post/data/firebase_post_repos.dart';
import 'package:edunest_app/features/post/data/firebase_report_repos.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/report_cubit.dart';
import 'package:edunest_app/features/profile/data/firebase_profile_repos.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/search/data/firebase_search_repo.dart';
import 'package:edunest_app/features/search/presentation/cubits/search_cubit.dart';
import 'package:edunest_app/themes/light_mode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
class MyApp extends StatelessWidget {
  final authRepo = FirebaseAuthRepos();
  final profileRepo = FirebaseProfileRepos();
  final postRepo = FirebasePostRepo();
  final searchrepo = FirebaseSearchRepo();
  final notificationRepo = FirebaseNotificationRepo();
  final reportrepo = ReportRepo();

  MyApp({super.key});

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
        // Auth Cubit uses the SAME cubits below
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(
            authRepo: authRepo,
            notificationCubit: notificationCubit,
            postCubit: postCubit,
          )..checkAuth(),
        ),

        BlocProvider<ProfileCubit>(
          create: (context) => ProfileCubit(
            profileRepo: profileRepo,
            notificationRepo: notificationRepo,
            postRepo: postRepo
          ),
        ),

        // Use the SAME PostCubit
        BlocProvider<PostCubit>.value(
          value: postCubit,
        ),

        BlocProvider<SearchCubit>(
          create: (context) => SearchCubit(
            searchrepo: searchrepo,
          ),
        ),

        // Use the SAME NotificationCubit
        BlocProvider<NotificationCubit>.value(
          value: notificationCubit,
        ),

        BlocProvider<ReportCubit>(
          create: (context) => ReportCubit(
            reportRepo: reportrepo,
          ),
        ),
      ],

      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightMode,

        home: BlocConsumer<AuthCubit, AuthState>(
          builder: (context, authState) {
            print(authState);

            if (authState is Unauthenticated) {
              return const AuthPage();
            }

            if (authState is Authenticated) {
              return const HomePage();
            }

            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          },

          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}