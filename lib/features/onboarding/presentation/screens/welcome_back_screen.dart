import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/session_store.dart';
import '../../../../core/theme/lumi_style.dart';

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});
  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  String _name = 'bạn';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await SessionStore.getName();
    if (mounted) setState(() => _name = name);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 20, 26, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LUMI', style: LumiStyle.heading(size: 37)),
            const SizedBox(height: 24),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: Image.asset(
                  'assets/images/welcome_spa_5.png',
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'WELCOME BACK',
              style: LumiStyle.body(
                size: 10,
                color: LumiStyle.rose,
              ).copyWith(letterSpacing: 3),
            ),
            const SizedBox(height: 9),
            Text(
              'Thật vui khi gặp lại,\n$_name.',
              style: LumiStyle.heading(size: 43),
            ),
            const SizedBox(height: 9),
            Text(
              'Một chút thời gian dành cho bản thân, hôm nay nhé?',
              style: LumiStyle.body(),
            ),
            const SizedBox(height: 23),
            LumiButton(
              label: 'Tiếp tục trải nghiệm',
              onPressed: () => context.go('/home'),
            ),
          ],
        ),
      ),
    ),
  );
}
