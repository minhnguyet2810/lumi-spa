import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/session/session_store.dart';
import '../../../../core/theme/lumi_style.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    setState(() => _busy = true);
    await SessionStore.demoLogin(_name.text);
    if (mounted) context.go('/welcome-back');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LUMI', style: LumiStyle.heading(size: 38)),
            const Spacer(),
            Text(
              'A little time,\njust for you.',
              style: LumiStyle.heading(size: 54),
            ),
            const SizedBox(height: 16),
            Text(
              'Đăng nhập demo để thử trải nghiệm Welcome Back.',
              style: LumiStyle.body(),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Tên của bạn',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 17),
            LumiButton(
              label: _busy ? 'Đang tiếp tục...' : 'Tiếp tục (demo)',
              onPressed: _busy ? null : _login,
            ),
            const SizedBox(height: 12),
            Text(
              'DEMO: chưa có xác thực tài khoản thật. Không nhập mật khẩu.',
              style: LumiStyle.body(size: 10),
            ),
            const Spacer(),
          ],
        ),
      ),
    ),
  );
}
