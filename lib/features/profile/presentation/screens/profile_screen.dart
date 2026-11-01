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
    this.onOrders,
  });

  final bool isLoggedIn;
  final bool isLoggingOut;
  final VoidCallback onLogin;
  final VoidCallback onLogout;
  final VoidCallback onAppointments;
  final VoidCallback onSupport;
  final VoidCallback? onOrders;

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
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
    children: [
      SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 24),
          child: Text(
            'Tài khoản',
            style: LumiStyle.body(
              size: 28,
              color: LumiStyle.ink,
            ).copyWith(fontWeight: FontWeight.w700, height: 1.2),
          ),
        ),
      ),
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
            label: Text(widget.isLoggingOut ? 'Đang đăng xuất…' : 'Đăng xuất'),
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
    background: const Color(0xFFFBE7DC),
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
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircleAvatar(
                    backgroundColor: const Color(0xFFFFFDFA),
                    foregroundImage: user?.photoURL == null
                        ? null
                        : NetworkImage(user!.photoURL!),
                    child: user?.photoURL == null
                        ? const Icon(
                            Icons.person_outline_rounded,
                            color: LumiStyle.rose,
                            size: 32,
                          )
                        : null,
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
                                size: 22,
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
          child: FilledButton.icon(
            onPressed: widget.isLoggedIn ? _editProfile : widget.onLogin,
            icon: Icon(
              widget.isLoggedIn ? Icons.edit_outlined : Icons.login_rounded,
              size: 22,
            ),
            label: Text(
              widget.isLoggedIn ? 'Chỉnh sửa hồ sơ' : 'Đăng nhập',
              style: LumiStyle.body(
                size: 16,
                color: LumiStyle.ink,
              ).copyWith(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFFDFA),
              foregroundColor: LumiStyle.plum,
              minimumSize: const Size(48, 54),
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
        background: const Color(0xFFE6F1F5),
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
                      size: 17,
                      color: LumiStyle.plum,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Hạng ${membership?.tier ?? '—'}',
                    style: LumiStyle.body(size: 15),
                  ),
                  Text(
                    'Điểm tích lũy: ${membership?.points?.toString() ?? '—'}',
                    style: LumiStyle.body(size: 15),
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
      children: [
        _setting(
          Icons.settings_outlined,
          'Cài đặt',
          'Tùy chọn tài khoản',
          () => context.push('/settings'),
        ),
        const Divider(height: 20, color: LumiStyle.line),
        _setting(
          Icons.event_note_outlined,
          'Lịch sử liệu trình',
          'Xem các lịch hẹn của bạn',
          widget.onAppointments,
        ),
        const Divider(height: 20, color: LumiStyle.line),
        if (widget.onOrders != null) ...[
          _setting(
            Icons.shopping_bag_outlined,
            'Đơn hàng của tôi',
            'Quản lý và theo dõi đơn mua sản phẩm',
            widget.onOrders!,
          ),
          const Divider(height: 20, color: LumiStyle.line),
        ],
        _setting(
          Icons.support_agent_outlined,
          'Hỗ trợ và liên hệ',
          'Liên hệ với LUMI',
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
  ) {
    final background = icon == Icons.settings_outlined
        ? const Color(0xFFE6F1F5)
        : icon == Icons.event_note_outlined
        ? const Color(0xFFFBE7DC)
        : const Color(0xFFEDF1E5);
    final foreground = icon == Icons.settings_outlined
        ? const Color(0xFF406779)
        : icon == Icons.event_note_outlined
        ? LumiStyle.rose
        : const Color(0xFF526442);

    return Semantics(
      hint: subtitle,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: foreground, size: 25),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: LumiStyle.body(
                      size: 17,
                      color: LumiStyle.ink,
                    ).copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 23,
                  color: LumiStyle.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 17, color: LumiStyle.muted),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value.isEmpty ? '—' : value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LumiStyle.body(size: 15),
        ),
      ),
    ],
  );

  Widget _tierPill(String? tier) => tier == null || tier.trim().isEmpty
      ? const SizedBox.shrink()
      : Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: LumiStyle.blushSurface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tier,
            style: LumiStyle.body(
              size: 14,
              color: LumiStyle.rose,
            ).copyWith(fontWeight: FontWeight.w700),
          ),
        );

  Widget _card({
    required Widget child,
    VoidCallback? onTap,
    Color background = LumiStyle.surface,
  }) => Container(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: const Color(0x66FFFFFF)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x07403735),
          blurRadius: 18,
          offset: Offset(0, 6),
        ),
      ],
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
