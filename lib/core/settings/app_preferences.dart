import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device preferences only. Does not modify authentication or Firebase data.
class AppPreferences extends ChangeNotifier {
  AppPreferences._();
  static final instance = AppPreferences._();
  static const _languageKey = 'lumi.ui.language.v1';
  static const _themeKey = 'lumi.ui.theme.v1';
  Locale _locale = const Locale('vi');
  ThemeMode _themeMode = ThemeMode.system;
  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  bool get isEnglish => _locale.languageCode == 'en';

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _locale = Locale(prefs.getString(_languageKey) == 'en' ? 'en' : 'vi');
      _themeMode = switch (prefs.getString(_themeKey)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
    } catch (_) {
      // Keep usable defaults if local storage cannot be read.
    }
  }

  Future<void> setLanguage(String language) async {
    if (language != 'vi' && language != 'en') {
      return;
    }
    if (_locale.languageCode == language) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_languageKey, language)) {
      throw StateError('Could not save language');
    }
    _locale = Locale(language);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_themeKey, mode.name)) {
      throw StateError('Could not save appearance');
    }
    _themeMode = mode;
    notifyListeners();
  }
}

/// Locale-aware UI text. Firebase content is intentionally left untouched.
extension LumiLanguage on BuildContext {
  String lumiText(String vi, String en) =>
      Localizations.localeOf(this).languageCode == 'en' ? en : vi;
}
