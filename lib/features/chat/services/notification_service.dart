import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String _channelId = 'chat_messages';
const String _channelName = 'Chat Notifications';
const String _channelDesc = 'Notifications for incoming chat messages';

/// Top-level background message handler for FCM.
/// The Cloud Function sends data-only pushes, so the app must build the
/// notification itself here (this runs in a separate isolate).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  await Firebase.initializeApp();
  await NotificationService._ensureLocalReady();
  await NotificationService._showFromMessage(message);
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Set to the chat that is currently open so no popup is shown for a
  /// conversation you're already looking at.
  /// Chat screen: initState -> activeChatId = id; dispose -> activeChatId = null.
  static String? activeChatId;

  static bool _localReady = false;
  static void Function(String chatId)? _onOpenChat;

  // ------------------------------------------------------------------ setup

  /// Initialize FCM permissions & local notifications
  static Future<void> initNotification(
    String currentUserId, {
    void Function(String chatId)? onOpenChat,
  }) async {
    // Local notifications / background handler are not available on web.
    if (kIsWeb) return;
    _onOpenChat = onOpenChat;

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

      // 3 + 4. Local notifications + Android channel
      await _ensureLocalReady();

      // Android 13+ runtime permission
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

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
        final chatId = message.data['chatId'];
        if (chatId != null && chatId == activeChatId) return;
        _showFromMessage(message);
      });

      // 7. Tapped while app was in background
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        final id = message.data['chatId'];
        if (id != null) _onOpenChat?.call(id);
      });
    }
  }

  static Future<void> _ensureLocalReady() async {
    if (_localReady) return;

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
        final id = _chatIdFromPayload(response.payload);
        if (id != null) _onOpenChat?.call(id);
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _localReady = true;
  }

  static String? _chatIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final m = jsonDecode(payload);
      if (m is Map) {
        return (m['conversationId'] ?? m['chatId'])?.toString();
      }
    } catch (_) {}
    return null;
  }

  // ----------------------------------------------------------------- tokens

  /// Save user's FCM token to Firestore.
  /// `fcmTokens` (list) supports several devices; `fcmToken` is kept so any
  /// old code that reads a single token still works.
  static Future<void> saveTokenToFirestore(String userId, String token) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'fcmToken': token,
        'fcmTokens': FieldValue.arrayUnion([token]),
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Call on logout so this device stops getting that user's messages.
  static Future<void> removeToken(String userId) async {
    if (kIsWeb) return;
    try {
      final token = await _messaging.getToken();
      if (token == null) return;
      await _firestore.collection('users').doc(userId).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }

  // ---------------------------------------------------------- notifications

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
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
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

  /// Builds the popup from a push.
  /// - Data-only push from the Cloud Function (chatId, title, lines):
  ///   one popup per chat with the unread messages stacked underneath.
  /// - Anything else (old-style push with a `notification` block): plain popup.
  static Future<void> _showFromMessage(RemoteMessage message) async {
    final data = message.data;
    final notification = message.notification;

    final chatId = data['chatId']?.toString();
    List<String> lines = [];
    try {
      lines = List<String>.from(jsonDecode(data['lines'] ?? '[]') as List);
    } catch (_) {}

    String? title = notification?.title ?? data['title'] ?? data['senderName'];
    String? body = notification?.body ?? (lines.isNotEmpty ? lines.last : null);

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

    title ??= 'New Message';
    if (body == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.message,
      // stacked lines like Instagram
      styleInformation: lines.length > 1
          ? InboxStyleInformation(
              lines,
              contentTitle: title,
              summaryText: '${lines.length} new messages',
            )
          : null,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      // same chat -> same id -> the popup is updated instead of duplicated
      id: chatId != null ? (chatId.hashCode & 0x7fffffff) : notification.hashCode,
      title: title,
      body: body,
      notificationDetails: details,
      payload: jsonEncode(
        chatId != null ? {'conversationId': chatId} : message.data,
      ),
    );
  }
}