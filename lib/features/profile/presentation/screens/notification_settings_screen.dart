import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/lumi_style.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const _appointmentKey = 'lumi_notice_appointments';
  static const _membershipKey = 'lumi_notice_membership';
  static const _promotionKey = 'lumi_notice_promotions';

  bool _loading = true;
  bool _saving = false;
  String? _error;
  bool _appointments = true;
  bool _membership = true;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _appointments = preferences.getBool(_appointmentKey) ?? true;
        _membership = preferences.getBool(_membershipKey) ?? true;
        _promotions = preferences.getBool(_promotionKey) ?? false;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = 'Không thể tải tùy chọn thông báo: $error';
        _loading = false;
      });
    }
  }

  Future<void> _updatePreference(String key, bool value) async {
    if (_saving) return;
    final oldValue = switch (key) {
      _appointmentKey => _appointments,
      _membershipKey => _membership,
      _ => _promotions,
    };

    setState(() {
      _saving = true;
      _error = null;
      _setValue(key, value);
    });

    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setBool(key, value);
      if (!saved) throw StateError('Không thể lưu tùy chọn.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _setValue(key, oldValue);
        _error = 'Không lưu được thay đổi. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _setValue(String key, bool value) {
    switch (key) {
      case _appointmentKey:
        _appointments = value;
      case _membershipKey:
        _membership = value;
      case _promotionKey:
        _promotions = value;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('Cài đặt thông báo', style: LumiStyle.heading(size: 28)),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: LumiStyle.rose))
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Text(
                'Thông tin bạn quan tâm',
                style: LumiStyle.heading(size: 32),
              ),
              const SizedBox(height: 6),
              Text(
                'Tùy chỉnh loại cập nhật bạn muốn xem trong ứng dụng LUMI.',
                style: LumiStyle.body(size: 14),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: LumiStyle.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: LumiStyle.line),
                ),
                child: Column(
                  children: [
                    _preferenceTile(
                      icon: Icons.event_available_outlined,
                      title: 'Lịch hẹn',
                      subtitle: 'Nhắc lịch và cập nhật thay đổi liên quan đến lịch hẹn.',
                      value: _appointments,
                      onChanged: (value) =>
                          _updatePreference(_appointmentKey, value),
                    ),
                    _divider(),
                    _preferenceTile(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Tài khoản thành viên',
                      subtitle: 'Cập nhật thông tin thẻ và điểm khi hệ thống ghi nhận.',
                      value: _membership,
                      onChanged: (value) =>
                          _updatePreference(_membershipKey, value),
                    ),
                    _divider(),
                    _preferenceTile(
                      icon: Icons.local_offer_outlined,
                      title: 'Ưu đãi và tin mới',
                      subtitle: 'Thông tin chương trình chăm sóc và hoạt động từ LUMI.',
                      value: _promotions,
                      onChanged: (value) =>
                          _updatePreference(_promotionKey, value),
                    ),
                  ],
                ),
              ),
              if (_saving) ...[
                const SizedBox(height: 14),
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: LumiStyle.rose,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: LumiStyle.blushSurface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: LumiStyle.body(size: 13, color: LumiStyle.plum),
                  ),
                ),
                TextButton(
                  onPressed: _loadPreferences,
                  child: const Text('Tải lại tùy chọn'),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Các lựa chọn này được lưu trên thiết bị. Việc gửi thông báo '
                'thực tế còn phụ thuộc vào tính năng thông báo đang được hỗ trợ.',
                style: LumiStyle.body(size: 12),
              ),
            ],
          ),
  );

  Widget _preferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile.adaptive(
    value: value,
    onChanged: _saving ? null : onChanged,
    activeTrackColor: LumiStyle.rose,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    secondary: Icon(icon, color: LumiStyle.rose),
    title: Text(title, style: LumiStyle.body(size: 15, color: LumiStyle.plum)),
    subtitle: Text(subtitle, style: LumiStyle.body(size: 12)),
  );

  Widget _divider() => const Padding(
    padding: EdgeInsets.symmetric(horizontal: 18),
    child: Divider(height: 1, color: LumiStyle.line),
  );
}
