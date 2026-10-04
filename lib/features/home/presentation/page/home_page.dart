import 'package:edunest_app/features/ChatPage/presentation/pages/chat_room_page.dart';
import 'package:edunest_app/features/Library/presentation/pages/library_page.dart';
import 'package:edunest_app/features/Reminder/presentation/pages/reminder_page.dart';
import 'package:edunest_app/features/auth/presentation/cubits/auth_cabit.dart';
import 'package:edunest_app/features/home/presentation/components/bottom_nav.dart';
import 'package:edunest_app/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:edunest_app/features/post/presentation/cubits/post_cubit.dart';
import 'package:edunest_app/features/post/presentation/pages/post_page.dart';
import 'package:edunest_app/features/profile/presentation/cubits/profile_cubit.dart';
import 'package:edunest_app/features/profile/presentation/pages/view_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
late final postCubit = context.read<PostCubit>();
  bool _showBottomNav = true;

  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  late final NavigatorObserver _navigatorObserver;
  void fetchforyou() {
    final user = context.read<ProfileCubit>().currentUser;
    if (user == null) return;
    postCubit.fetchAllPostsbypublic();
  }

  @override
  void initState() {
    super.initState();

    _navigatorObserver = _HomeNavigatorObserver(
      onNavigationChanged: _updateBottomNav,
    );

    final authUser = context.read<AuthCubit>().currentUser;

    if (authUser != null) {
      context.read<ProfileCubit>().fetchUserProfile(authUser.uid);
      context.read<NotificationCubit>().fetchNotifications(authUser.uid);
    }
  }

  void _updateBottomNav() {
    final navigator = _navigatorKey.currentState;

    if (navigator == null) return;

    final shouldShow = navigator.canPop() == false;

    if (_showBottomNav != shouldShow) {
      setState(() {
        _showBottomNav = shouldShow;
      });
    }
  }

  void _onTap(int index) {
    setState(() {
      _selectedIndex = index;
      _showBottomNav = true;
    });

    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) {
          switch (index) {
            case 0:
              return const PostPage();
            case 1:
              return LibraryPage();
            case 2:
              return ReminderPage();
            case 3:
              return ChatRoomPage();
            case 4:
              final uid = context.read<AuthCubit>().currentUser?.uid ?? '';
              return ViewProfile(
                uid: uid,
                // Drawer opened → hide bottom navigation
                onDrawerOpened: () {
                  setState(() {
                    _showBottomNav = false;
                  });
                },
                // Drawer closed → show bottom navigation
                onDrawerClosed: () {
                  setState(() {
                    _showBottomNav = true;
                  });
                },
              );

            default:
              return const PostPage();
          }
        },
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<ProfileCubit>().currentUser;

    return Scaffold(
      body: Stack(
        children: [
          Navigator(
            key: _navigatorKey,
            observers: [_navigatorObserver],
            onGenerateRoute: (settings) {
              return MaterialPageRoute(builder: (context) => const PostPage());
            },
          ),

          // Bottom Navigation
          if (_showBottomNav)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MyBottomNavBar(
                currentIndex: _selectedIndex,
                onTap: _onTap,
                profileImageUrl: user?.profileImageUrl ?? '',
              ),
            ),
        ],
      ),
    );
  }
}

/// Detects when a secondary page is pushed or popped.
class _HomeNavigatorObserver extends NavigatorObserver {
  final VoidCallback onNavigationChanged;

  _HomeNavigatorObserver({required this.onNavigationChanged});

  @override
  void didPush(Route route, Route? previousRoute) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onNavigationChanged();
    });
  }
}
