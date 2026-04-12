import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'core/services/push_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background message received: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  try {
    debugPrint('Firebase initialized: name=${Firebase.app().name}');
    debugPrint(
      'Firebase options projectId=${Firebase.app().options.projectId}',
    );
    debugPrint('Firebase options appId=${Firebase.app().options.appId}');
  } catch (e) {
    debugPrint('Failed to read Firebase.app() info: $e');
  }

  await PushNotificationService.initialize();

  runApp(const ProviderScope(child: FoodTechPrepApp()));
}
