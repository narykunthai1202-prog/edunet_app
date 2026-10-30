import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize FCM permissions & local notifications
  static Future<void> initNotification(String currentUserId) async {
    // 1. Request Notification Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      
      // 2. Register Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Setup Android & iOS Notification Settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification tapped: ${response.payload}');
        },
      );

      // 4. Create Android Notification Channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'chat_messages',
        'Chat Notifications',
        description: 'Notifications for incoming chat messages',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 5. Get FCM Token & save to Firestore
      String? token = await _messaging.getToken();
      if (token != null) {
        await saveTokenToFirestore(currentUserId, token);
      }

      // Listen for token refreshes
      _messaging.onTokenRefresh.listen((newToken) {
        saveTokenToFirestore(currentUserId, newToken);
      });

      // 6. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
    }
  }

  /// Save user's FCM token to Firestore
  static Future<void> saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Manually trigger a local notification for incoming chats (audio, image, text)
  static Future<void> showMessageNotification({
    required String senderName,
    required String messageType,
    required String content,
    String? conversationId,
  }) async {
    String bodyText;
    switch (messageType) {
      case 'audio':
        bodyText = '🎤 Voice message';
        break;
      case 'image':
        bodyText = '📷 Photo';
        break;
      default:
        bodyText = content;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Notifications',
      channelDescription: 'Notifications for incoming chat messages',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: senderName,
      body: bodyText,
      notificationDetails: details,
      payload: conversationId != null
          ? jsonEncode({'conversationId': conversationId})
          : null,
    );
  }

  /// Display a heads-up banner when app is open in foreground
  static void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    Map<String, dynamic> data = message.data;

    String? title = notification?.title ?? data['senderName'] ?? 'New Message';
    String? body = notification?.body;

    if (body == null && data.containsKey('type')) {
      switch (data['type']) {
        case 'audio':
          body = '🎤 Voice message';
          break;
        case 'image':
          body = '📷 Photo';
          break;
        default:
          body = data['text'] ?? 'Sent you a message';
      }
    }

    if (title != null && body != null) {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Notifications',
        channelDescription: 'Notifications for incoming chat messages',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );

      _localNotifications.show(
        id: notification.hashCode,
        title: title,
        body: body,
        notificationDetails: details,
        payload: jsonEncode(message.data),
      );
    }
  }
}