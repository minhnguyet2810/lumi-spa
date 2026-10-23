import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class SessionStore {
  static const _seenKey = 'lumi_onboarding_seen_v4';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  static Future<bool> hasSession() async =>
      FirebaseAuth.instance.currentUser != null;

  static Future<String> getName() async {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return user?.email?.split('@').first ?? 'bạn';
  }

  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }
}
