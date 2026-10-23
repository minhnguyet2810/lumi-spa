import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/session_store.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      final results = await Future.wait<bool>([
        SessionStore.hasSeenOnboarding(),
        SessionStore.hasSession(),
      ]);

      // Giữ splash tối thiểu 2.2 giây
      await Future.delayed(const Duration(milliseconds: 2200));

      if (!mounted) return;

      final hasSeenOnboarding = results[0];
      final isLoggedIn = results[1];

      if (isLoggedIn) {
        context.go('/welcome-back');
      } else if (!hasSeenOnboarding) {
        context.go('/welcome');
      } else {
        // Returning guests may browse without signing in.
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      // If onboarding state is unavailable, allow browsing.
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ảnh splash đã có chữ LUMI
          Image.asset('assets/images/splash_background.png', fit: BoxFit.cover),

          // Loading bar tối giản
          Positioned(
            left: 0,
            right: 0,
            bottom: 55,
            child: Center(
              child: SizedBox(
                width: 82,
                child: const LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Color(0x66FFFFFF),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
