# LUMI SPA Welcome V4 Hybrid

## Installation
From your existing Flutter project root (e.g. `~/AndroidStudioProjects/lumi_spa`):

```bash
flutter pub add go_router google_fonts shared_preferences flutter_secure_storage
# Unzip the archive, then copy its lib/ into the project:
cp -R /path/to/unzipped/lumi_v4/lib/. lib/
flutter pub get
flutter run
```

Ensure these assets already exist in `assets/images/`: `splash_background.png` and `welcome_spa_1.png` through `welcome_spa_5.png`. Ensure pubspec.yaml contains `flutter: assets: - assets/images/` with correct YAML indentation.

## File map
- lib/main.dart — entry point
- lib/app/app.dart — MaterialApp.router
- lib/app/router/app_router.dart — routes
- lib/core/theme/lumi_style.dart — visual style
- lib/core/session/session_store.dart — local onboarding and DEMO login persistence
- lib/features/splash/presentation/screens/splash_screen.dart — startup decision
- lib/features/onboarding/presentation/screens/welcome_screen.dart — 5-image editorial onboarding
- lib/features/onboarding/presentation/screens/welcome_back_screen.dart — returning-user welcome
- lib/features/auth/presentation/screens/login_screen.dart — DEMO name login
- lib/features/home/presentation/screens/home_screen.dart — temporary home and logout

## Important
Demo login is **not real authentication**. Replace `SessionStore.demoLogin` / `hasSession` with Firebase Auth or a backend session verification before production. `main.dart` is a simple entrypoint; if you have Riverpod providers used elsewhere, retain `ProviderScope` wrapping `LumiApp`.
