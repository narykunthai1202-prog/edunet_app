import 'package:edunest_app/features/notifications/presentation/components/notification_item.dart';
import 'package:edunest_app/features/notifications/presentation/cubits/notification_cubit.dart';
import 'package:edunest_app/features/notifications/domain/entities/notification.dart'
    as app_notification;
import 'package:edunest_app/features/notifications/presentation/pages/requested_sugessted.dart';
import 'package:edunest_app/features/search/presentation/pages/search_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationCubit>().state;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 10, 0),
              child: Row(
                children: [
                  // Back button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F1F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Iconsax.arrow_left_2,
                        size: 19,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Title
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),

                  // Search
                  IconButton(
                    splashRadius: 22,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SearchPage(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Iconsax.search_normal_1,
                      size: 21,
                      color: Colors.black,
                    ),
                  ),

                  // Add friend
                  IconButton(
                    splashRadius: 22,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestedSugessted(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Iconsax.user_add,
                      size: 21,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  notifications.isEmpty
                      ? 'You have no notifications.'
                      : '${notifications.length} notification${notifications.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child:
                  BlocBuilder<
                    NotificationCubit,
                    List<app_notification.Notification>
                  >(
                    builder: (context, notifications) {
                      if (notifications.isEmpty) {
                        return _emptyNotification();
                      }

                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          ...notifications.map(
                            (notification) =>
                                NotificationItem(notification: notification),
                          ),

                          const SizedBox(height: 25),
                        ],
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyNotification() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFF8EDEF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.notification,
                size: 34,
                color: Color(0xFFB98A94),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'We will let you know when something happens.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF999999)),
            ),
          ],
        ),
      ),
    );
  }
}
