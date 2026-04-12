import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Lightweight snapshot of the current notification registration state.
class NotificationRegistration {
  const NotificationRegistration({
    this.token,
    required this.authorizationStatus,
  });

  final String? token;
  final AuthorizationStatus authorizationStatus;

  /// Whether the user has effectively granted notification permission.
  bool get notificationsEnabled =>
      authorizationStatus == AuthorizationStatus.authorized ||
      authorizationStatus == AuthorizationStatus.provisional;

  /// Human-readable permission status for Firestore persistence.
  String get permissionStatusString => authorizationStatus.name;
}

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'asia-southeast1',
  );

  /// Cached authorization status from the last [initialize] call.
  static AuthorizationStatus _lastAuthStatus =
      AuthorizationStatus.notDetermined;

  static Future<void> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    _lastAuthStatus = settings.authorizationStatus;

    debugPrint(
      'Notification permission status: ${settings.authorizationStatus}',
    );

    final token = await _messaging.getToken();
    debugPrint('FCM TOKEN: $token');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message id: ${message.messageId}');
      debugPrint('Foreground title: ${message.notification?.title}');
      debugPrint('Foreground body: ${message.notification?.body}');
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification tapped: ${message.messageId}');
    });
  }

  static Future<String?> getToken() async {
    return _messaging.getToken();
  }

  /// Returns the current notification registration state (token + permission).
  ///
  /// Safe to call at any time — returns a `null` token / `notDetermined`
  /// status if [initialize] has not been called yet.
  static Future<NotificationRegistration> getRegistrationState() async {
    try {
      final token = await _messaging.getToken();
      return NotificationRegistration(
        token: token,
        authorizationStatus: _lastAuthStatus,
      );
    } catch (e) {
      debugPrint('[PushNotificationService] getRegistrationState failed: $e');
      return NotificationRegistration(
        token: null,
        authorizationStatus: _lastAuthStatus,
      );
    }
  }

  static Future<void> sendTestNotification() async {
    final token = await _messaging.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('FCM token is null or empty.');
    }

    final callable = _functions.httpsCallable('sendTestNotification');

    final result = await callable.call({
      'token': token,
      'title': 'FoodTech Prep Test',
      'body': 'Hello partner 😄 push notification is working.',
    });

    debugPrint('sendTestNotification result: ${result.data}');
  }

  /// Sends a notification via the backend send-by-uid pattern.
  ///
  /// The backend reads the stored FCM token from Firestore — no raw token
  /// is sent from the client.  Intended for debug/test verification.
  static Future<void> sendNotificationToUser({
    required String uid,
    required String title,
    required String body,
  }) async {
    final callable = _functions.httpsCallable('sendNotificationToUser');

    final result = await callable.call({
      'uid': uid,
      'title': title,
      'body': body,
    });

    debugPrint('sendNotificationToUser result: ${result.data}');
  }

  /// Triggers a countdown reminder for the given user via the backend.
  ///
  /// The backend builds the message content and sends it.
  /// [examDate] is optional — defaults to the Oct 2026 board exam on the
  /// server side.
  static Future<void> sendCountdownReminder({
    required String uid,
    String? examDate,
  }) async {
    final callable = _functions.httpsCallable('sendCountdownReminder');

    final payload = <String, dynamic>{'uid': uid};
    if (examDate != null) payload['examDate'] = examDate;

    final result = await callable.call(payload);

    debugPrint('sendCountdownReminder result: ${result.data}');
  }
}
