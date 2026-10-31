import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/lumi_style.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Cài đặt', style: LumiStyle.heading(size: 30))),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('Tài khoản', style: LumiStyle.heading(size: 34)),
        const SizedBox(height: 6),
        Text(
          'Quản lý thông tin cá nhân của bạn.',
          style: LumiStyle.body(size: 14),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: LumiStyle.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: LumiStyle.line),
          ),
          child: _setting(
            context,
            icon: Icons.person_outline_rounded,
            title: 'Thông tin cá nhân',
            subtitle: 'Cập nhật họ tên và số điện thoại',
            route: '/profile/edit',
          ),
        ),
      ],
    ),
  );

  Widget _setting(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String route,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    leading: Icon(icon, color: LumiStyle.rose),
    title: Text(title, style: LumiStyle.body(size: 15, color: LumiStyle.plum)),
    subtitle: Text(subtitle, style: LumiStyle.body(size: 12)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => context.push(route),
  );
}
