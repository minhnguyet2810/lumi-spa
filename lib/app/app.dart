import 'package:flutter/material.dart';

import 'router/app_router.dart';
import '../core/theme/lumi_style.dart';

class LumiApp extends StatelessWidget {
  const LumiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'LUMI SPA',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: LumiStyle.ivory,
      colorScheme: ColorScheme.fromSeed(seedColor: LumiStyle.rose),
    ),
    routerConfig: AppRouter.router,
  );
}
