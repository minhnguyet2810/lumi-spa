import 'package:flutter/material.dart';

import 'router/app_router.dart';
import '../core/theme/lumi_style.dart';

class LumiApp extends StatelessWidget {
  const LumiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'LUMI SPA',
    debugShowCheckedModeBanner: false,
    theme: LumiStyle.theme,
    routerConfig: AppRouter.router,
  );
}
