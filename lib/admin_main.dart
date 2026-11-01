import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/lumi_style.dart';
import 'features/admin/presentation/screens/admin_access_gate.dart';
import 'features/admin/presentation/screens/admin_portal_hub_screen.dart';
import 'firebase_options.dart';

// Entry point độc lập dành riêng cho giao diện Admin LUMI SPA (Lịch hẹn & Đơn hàng).
// Chạy độc lập bằng câu lệnh:
//   flutter run -t lib/admin_main.dart -d chrome
//   hoặc:
//   flutter run -t lib/admin_main.dart -d windows
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const LumiAdminApp());
}

class LumiAdminApp extends StatelessWidget {
  const LumiAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LUMI SPA — Portal Quản Trị',
      debugShowCheckedModeBanner: false,
      theme: LumiStyle.theme.copyWith(scaffoldBackgroundColor: LumiStyle.ivory),
      home: const AdminPortalHubScreen(),
      builder: (context, child) => Overlay.wrap(
        child: AdminAccessGate(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
