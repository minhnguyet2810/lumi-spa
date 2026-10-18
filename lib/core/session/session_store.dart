import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// DEMO ONLY: replace the demo token with Firebase Auth or a server-validated session.
abstract final class SessionStore {
  static const _secure = FlutterSecureStorage();
  static const _seenKey = 'lumi_onboarding_seen_v4';
  static const _tokenKey = 'lumi_demo_session';
  static const _nameKey = 'lumi_demo_name';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }

  static Future<bool> hasSession() async =>
      (await _secure.read(key: _tokenKey)) == 'demo-active';

  static Future<String> getName() async =>
      (await _secure.read(key: _nameKey)) ?? 'bạn';

  static Future<void> demoLogin(String name) async {
    await _secure.write(
      key: _nameKey,
      value: name.trim().isEmpty ? 'bạn' : name.trim(),
    );
    await _secure.write(key: _tokenKey, value: 'demo-active');
  }

  static Future<void> logout() async {
    await _secure.delete(key: _tokenKey);
    await _secure.delete(key: _nameKey);
  }
}
