import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/marketplace/presentation/conversation_thread_screen.dart';
import '../../features/notifications/data/device_token_api.dart';
import '../navigation/navigator_key.dart';

const _defaultChannel = AndroidNotificationChannel(
  'eventsrus_default_channel',
  'EventsRUs Notifications',
  description: 'New leads, messages, quotations, and booking updates.',
  importance: Importance.high,
);

/// Must be a top-level/static function (FlutterFire requirement - it runs
/// in its own background isolate, with no access to this instance's state).
/// Left minimal on purpose: a "notification" message (the kind every
/// backend push in this app sends) is already shown by the OS itself while
/// the app is backgrounded/terminated, using the AndroidManifest meta-data
/// channel/icon - no Dart code runs for that display at all. This handler
/// only exists as the hook FlutterFire requires to be registered for
/// background messages to be delivered here in the first place, should a
/// later data-only message type need real background handling.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Push notifications (Firebase Cloud Messaging) - lets a vendor see new
/// leads/messages/quotations/booking updates arrive even with the app
/// closed, the same way BPI/Grab do. Requires a real Firebase project with
/// an Android app registered under this exact package name
/// (com.eventsrus.eventsrus_ui) and its google-services.json dropped in at
/// android/app/google-services.json - until that's done,
/// Firebase.initializeApp() below throws and [initialize] just logs and
/// returns, leaving the rest of the app completely unaffected.
///
/// This phase only covers the mobile-side plumbing (permission, token
/// registration, foreground/background display). Actually SENDING a push
/// when a lead/message/quotation/booking event happens is separate
/// backend work, not yet wired up - see DeviceTokenApi's own doc comment.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _localNotifications = FlutterLocalNotificationsPlugin();
  DeviceTokenApi? _deviceTokenApi;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      // No google-services.json yet (Firebase console setup not done) -
      // or any other native config problem. Push notifications just stay
      // off; nothing else in the app depends on this.
      debugPrint('PushNotificationService: Firebase not configured yet, skipping. ($e)');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_defaultChannel);

    // A "notification" message (what every push this app sends carries)
    // only auto-displays via the OS while backgrounded/terminated -
    // Android/iOS both deliberately suppress that same system banner while
    // the app is in the foreground, so it has to be shown manually here or
    // a vendor actively using the app would never see it arrive at all.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Tapped while the app was backgrounded (not terminated) - the OS
    // handled displaying it, this fires once the user taps it and the app
    // resumes to the foreground.
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleNotificationTap(message.data));

    // Tapped while the app was fully terminated - the app is only just
    // starting up now, so the Navigator this needs may not exist yet;
    // _handleNotificationTap retries until it does.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _handleNotificationTap(initialMessage.data);

    await FirebaseMessaging.instance.requestPermission();
    _initialized = true;
  }

  void _onLocalNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    try {
      _handleNotificationTap(jsonDecode(payload) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('PushNotificationService: could not parse notification payload. ($e)');
    }
  }

  /// Routes a tapped notification to the screen its related entity belongs
  /// to - only "CONVERSATION" (new message) is wired up today, matching the
  /// only entity type that currently has a single obvious destination
  /// screen regardless of role. Other types (lead, quotation, booking, ...)
  /// just open the app normally for now.
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = int.tryParse(data['id'] as String? ?? '');
    if (type != 'CONVERSATION' || id == null) return;
    _pushWhenNavigatorReady(
      MaterialPageRoute(builder: (_) => ConversationThreadScreen(conversationId: id)),
    );
  }

  Future<void> _pushWhenNavigatorReady(Route<void> route) async {
    for (var attempt = 0; attempt < 15; attempt++) {
      final navigator = rootNavigatorKey.currentState;
      if (navigator != null) {
        navigator.push(route);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  /// Called once authenticated (see AuthGate) - registers this device's
  /// FCM token with the backend so a push can actually be addressed to
  /// this specific signed-in user, and keeps it updated if Firebase
  /// rotates the token later.
  Future<void> registerDevice(DeviceTokenApi api) async {
    if (!_initialized) return;
    _deviceTokenApi = api;

    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _safeRegister(token);

    FirebaseMessaging.instance.onTokenRefresh.listen(_safeRegister);
  }

  Future<void> _safeRegister(String token) async {
    try {
      await _deviceTokenApi?.register(token);
    } catch (e) {
      debugPrint('PushNotificationService: could not register device token. ($e)');
    }
  }

  /// Called on logout (see AuthController.logout) so a push never keeps
  /// reaching a device that's no longer signed in to that account.
  Future<void> unregisterDevice() async {
    if (!_initialized) return;
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    try {
      await _deviceTokenApi?.unregister(token);
    } catch (e) {
      debugPrint('PushNotificationService: could not unregister device token. ($e)');
    } finally {
      _deviceTokenApi = null;
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(_defaultChannel.id, _defaultChannel.name),
      ),
      payload: message.data.isEmpty ? null : jsonEncode(message.data),
    );
  }
}
