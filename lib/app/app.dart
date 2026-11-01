import '../core/widgets/lumi_interactions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router/app_router.dart';
import '../core/theme/lumi_style.dart';
import '../core/settings/app_preferences.dart';

class LumiApp extends StatelessWidget {
  const LumiApp({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: AppPreferences.instance,
    builder: (context, _) => MaterialApp.router(
      title: 'LUMI SPA',
      builder: (context, child) =>
          LumiSparkleTrail(child: child ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
      theme: LumiStyle.theme,
      darkTheme: LumiStyle.darkTheme,
      themeMode: AppPreferences.instance.themeMode,
      locale: AppPreferences.instance.locale,
      supportedLocales: const [Locale('vi'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: AppRouter.router,
    ),
  );
}
