import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/lumi_account_repository.dart';
import '../../../../core/theme/lumi_style.dart';
import 'edit_profile_screen.dart';
import 'membership_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.isLoggedIn,
    required this.isLoggingOut,
    required this.onLogin,
    required this.onLogout,
    required this.onAppointments,
    required this.onSupport,
  });

  final bool isLoggedIn;
  final bool isLoggingOut;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onAppointments;
  final VoidCallback onSupport;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<LumiAccountProfile> _profileFuture;
  late Future<LumiMembership> _membershipFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoggedIn != widget.isLoggedIn && widget.isLoggedIn) {
      _reload();
    }
  }

  void _reload() {
    if (widget.isLoggedIn) {
      _profileFuture = LumiAccountRepository.fetchProfile();
      _membershipFuture = LumiAccountRepository.fetchMembership();
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    _profileFuture = Future.value(
      LumiAccountProfile(
        uid: '',
        displayName: user?.displayName ?? '',
        email: user?.email ?? '',
        phone: '',
      ),
    );
    _membershipFuture = Future.value(
      const LumiMembership(
        tier: null,
        points: null,
        totalSpent: null,
        isDefault: null,
      ),
    );
  }

  Future<void> _editProfile() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const EditProfileScreen()),
    );
    if (changed == true && mounted) {
      setState(_reload);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    children: [
      Row(
        children: [
          const Spacer(),
          Expanded(
            flex: 3,
            child: Text(
              'Hồ sơ cá nhân',
              textAlign: TextAlign.center,
              style: LumiStyle.heading(size: 28, color: LumiStyle.plum),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: widget.isLoggedIn
                  ? TextButton(
                      onPressed: widget.isLoggingOut ? null : widget.onLogout,
                      child: const Text('Đăng xuất'),
                    )
                  : TextButton(
                      onPressed: widget.onLogin,
                      child: const Text('Đăng nhập'),
                    ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      _profileCard(),
      const SizedBox(height: 14),
      _membershipCard(),
      const SizedBox(height: 14),
      _settingsCard(),
      const SizedBox(height: 18),
      if (widget.isLoggedIn)
        SizedBox(
          height: 52,
          child: OutlinedButton.icon(
            onPressed: widget.isLoggingOut ? null : widget.onLogout,
            icon: const Icon(Icons.logout_rounded),
            label: Text(
              widget.isLoggingOut ? 'ĐANG ĐĂNG XUẤT...' : 'ĐĂNG XUẤT',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: LumiStyle.plum,
              side: const BorderSide(color: LumiStyle.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
    ],
  );

  Widget _profileCard() => _card(
    child: Column(
      children: [
        FutureBuilder<LumiAccountProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final user = FirebaseAuth.instance.currentUser;
            final profile = snapshot.data;
            final error = snapshot.hasError;
            final name = profile?.displayName.isNotEmpty == true
                ? profile!.displayName
                : user?.displayName ?? 'Khách hàng LUMI';
            final email = profile?.email.isNotEmpty == true
                ? profile!.email
                : user?.email ?? '';
            final phone = profile?.phone ?? '';

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CircleAvatar(
                      backgroundColor: LumiStyle.blushSurface,
                      foregroundImage: user?.photoURL == null
                          ? null
                          : NetworkImage(user!.photoURL!),
                      child: user?.photoURL == null
                          ? const Icon(
                              Icons.person_outline_rounded,
                              color: LumiStyle.rose,
                              size: 38,
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: LumiStyle.body(
                                size: 18,
                                color: LumiStyle.plum,
                              ).copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          FutureBuilder<LumiMembership>(
                            future: _membershipFuture,
                            builder: (context, tierSnapshot) =>
                                _tierPill(tierSnapshot.data?.tier),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      _infoLine(Icons.mail_outline, email),
                      const SizedBox(height: 4),
                      _infoLine(
                        Icons.phone_outlined,
                        phone.isEmpty ? 'Chưa cập nhật số điện thoại' : phone,
                      ),
                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: LumiStyle.rose,
                          ),
                        ),
                      if (error)
                        TextButton(
                          onPressed: () => setState(_reload),
                          child: const Text('Không tải được hồ sơ · Thử lại'),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.isLoggedIn ? _editProfile : widget.onLogin,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Chỉnh sửa thông tin cá nhân'),
            style: OutlinedButton.styleFrom(
              foregroundColor: LumiStyle.plum,
              side: const BorderSide(color: LumiStyle.line),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _membershipCard() => FutureBuilder<LumiMembership>(
    future: _membershipFuture,
    builder: (context, snapshot) {
      final membership = snapshot.data;
      return _card(
        onTap: widget.isLoggedIn
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const MembershipScreen(),
                ),
              )
            : widget.onLogin,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: LumiStyle.blushSurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.workspace_premium_outlined,
                color: LumiStyle.rose,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thẻ thành viên LUMI',
                    style: LumiStyle.body(
                      size: 16,
                      color: LumiStyle.rose,
                    ).copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Hạng ${membership?.tier ?? '—'}',
                    style: LumiStyle.body(size: 13),
                  ),
                  Text(
                    'Điểm tích lũy: ${membership?.points?.toString() ?? '—'}',
                    style: LumiStyle.body(size: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: LumiStyle.rose),
          ],
        ),
      );
    },
  );

  Widget _settingsCard() => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _setting(
          Icons.settings_outlined,
          'Cài đặt',
          'Tùy chọn tài khoản',
          () => context.push('/settings'),
        ),
        const SizedBox(height: 4),
        _setting(
          Icons.event_note_outlined,
          'Lịch sử liệu trình',
          'Xem các lịch hẹn của bạn',
          widget.onAppointments,
        ),
        _setting(
          Icons.support_agent_outlined,
          'Hỗ trợ và liên hệ',
          'Chúng tôi luôn sẵn sàng hỗ trợ',
          widget.onSupport,
        ),
      ],
    ),
  );

  Widget _setting(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              height: 42,
              child: Icon(icon, color: LumiStyle.rose, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: LumiStyle.body(size: 15, color: LumiStyle.plum),
                  ),
                  Text(subtitle, style: LumiStyle.body(size: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    ),
  );

  Widget _infoLine(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 15, color: LumiStyle.muted),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value.isEmpty ? '—' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LumiStyle.body(size: 13),
        ),
      ),
    ],
  );

  Widget _tierPill(String? tier) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: LumiStyle.blushSurface,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      tier ?? '—',
      style: LumiStyle.body(
        size: 10,
        color: LumiStyle.rose,
      ).copyWith(fontWeight: FontWeight.w700),
    ),
  );

  Widget _card({required Widget child, VoidCallback? onTap}) => Container(
    decoration: BoxDecoration(
      color: LumiStyle.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: LumiStyle.line),
    ),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(padding: const EdgeInsets.all(18), child: child),
      ),
    ),
  );
}
