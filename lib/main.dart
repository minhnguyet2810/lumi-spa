import 'core/settings/app_preferences.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'core/services/fcm_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Khởi tạo Firebase Cloud Messaging (Push Notifications)
  await FcmService.instance.initialize();

  await AppPreferences.instance.load();

  runApp(const LumiApp());
}
