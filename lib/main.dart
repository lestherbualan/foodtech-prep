import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Helpful debug info to ensure the app is initialised against the
  // expected Firebase project during testing.
  try {
    debugPrint('Firebase initialized: name=${Firebase.app().name}');
    debugPrint(
      'Firebase options projectId=${Firebase.app().options.projectId}',
    );
    debugPrint('Firebase options appId=${Firebase.app().options.appId}');
  } catch (e) {
    debugPrint('Failed to read Firebase.app() info: $e');
  }

  runApp(const ProviderScope(child: FoodTechPrepApp()));
}
