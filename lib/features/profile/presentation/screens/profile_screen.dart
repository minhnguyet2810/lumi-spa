// LUMI_PROFILE_MENU_V2
import 'package:lumi_spa/core/widgets/lumi_interactions.dart';

import 'package:lumi_spa/core/settings/app_preferences.dart';
import 'package:lumi_spa/core/widgets/lumi_signature.dart';
import 'package:lumi_spa/features/ai/lumi_ai_screen.dart';

import '../../../../core/theme/lumi_adaptive.dart';
import 'support_screen.dart';

import 'package:lumi_spa/features/experience/experience_screen.dart';

import 'treatment_history_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/data/lumi_account_repository.dart';
import '../../../../core/theme/lumi_style.dart';
import 'addresses_screen.dart';
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
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
      children: [
        LumiSignatureHeader(
          eyebrow: 'MY LUMI SPACE',
          title: context.lumiText(
            'Chăm mình,\ntheo cách của bạn.',
            'Your space.\nYour kind of care.',
          ),
          description: context.lumiText(
            'Hồ sơ, đặc quyền và những trải nghiệm bạn yêu thích — ở cùng một nơi.',
            'Your profile, membership and favourite experiences, all together.',
          ),
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 20),
        LumiSoftEntrance(child: _profileCard()),
        const SizedBox(height: 14),
        LumiSoftEntrance(child: _membershipCard()),
        const SizedBox(height: 14),
        const LumiMomentCard(),
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
                LumiAdaptive.text(
                  widget.isLoggingOut ? 'Đang đăng xuất…' : 'Đăng xuất',
                ),
              ),
              style: LumiAdaptive.style(
                OutlinedButton.styleFrom(
                  foregroundColor: LumiAdaptive.color(LumiStyle.plum),
                  side: BorderSide(color: LumiAdaptive.color(LumiStyle.line)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
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
            final photoUrl = user?.photoURL?.trim();
            final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircleAvatar(
                    backgroundColor: LumiAdaptive.color(
                      const Color(0xFFFFFDFA),
                      surface: true,
                    ),
                    foregroundImage: hasPhoto ? NetworkImage(photoUrl) : null,
                    onForegroundImageError: hasPhoto
                        ? (error, stackTrace) {}
                        : null,
                    child: !hasPhoto
                        ? Icon(
                            Icons.person_outline_rounded,
                            color: LumiAdaptive.color(LumiStyle.rose),
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
                              LumiAdaptive.text(name),
                              overflow: TextOverflow.ellipsis,
                              style: LumiAdaptive.style(
                                LumiStyle.body(
                                  size: 22,
                                  color: LumiAdaptive.color(
                                    LumiStyle.plum,
                                    surface: true,
                                  ),
                                ).copyWith(fontWeight: FontWeight.w700),
                              ),
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
                        Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: LumiAdaptive.color(LumiStyle.rose),
                          ),
                        ),
                      if (error)
                        TextButton(
                          onPressed: () => setState(_reload),
                          child: Text(
                            LumiAdaptive.text('Không tải được hồ sơ · Thử lại'),
                          ),
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
              LumiAdaptive.text(
                widget.isLoggedIn ? 'Chỉnh sửa hồ sơ' : 'Đăng nhập',
              ),
              style: LumiAdaptive.style(
                LumiStyle.body(
                  size: 16,
                  color: LumiAdaptive.color(LumiStyle.ink, surface: true),
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            style: LumiAdaptive.style(
              FilledButton.styleFrom(
                backgroundColor: LumiAdaptive.color(
                  const Color(0xFFFFFDFA),
                  surface: true,
                ),
                foregroundColor: LumiAdaptive.color(LumiStyle.plum),
                minimumSize: const Size(48, 54),
                side: BorderSide(color: LumiAdaptive.color(LumiStyle.line)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
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
              decoration: BoxDecoration(
                color: LumiAdaptive.color(
                  LumiStyle.blushSurface,
                  surface: true,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium_outlined,
                color: LumiAdaptive.color(LumiStyle.rose),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    LumiAdaptive.text('Thẻ thành viên LUMI'),
                    style: LumiAdaptive.style(
                      LumiStyle.body(
                        size: 17,
                        color: LumiAdaptive.color(
                          LumiStyle.plum,
                          surface: true,
                        ),
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    LumiAdaptive.text('Hạng ${membership?.tier ?? '—'}'),
                    style: LumiAdaptive.style(LumiStyle.body(size: 15)),
                  ),
                  Text(
                    LumiAdaptive.text(
                      'Điểm tích lũy: ${membership?.points?.toString() ?? '—'}',
                    ),
                    style: LumiAdaptive.style(LumiStyle.body(size: 15)),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: LumiAdaptive.color(LumiStyle.rose),
            ),
          ],
        ),
      );
    },
  );

  Widget _settingsCard() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 10, 4, 16),
        child: Text(
          Localizations.localeOf(context).languageCode == 'en'
              ? 'YOUR LUMI ESSENTIALS'
              : 'KHÔNG GIAN CỦA BẠN',
          style: LumiStyle.body(
            size: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ).copyWith(letterSpacing: 1.7, fontWeight: FontWeight.w700),
        ),
      ),
      _setting(
        Icons.auto_awesome_outlined,
        'LUMI AI',
        'Trò chuyện và khám phá mỹ phẩm cùng bạn',
        widget.isLoggedIn
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const LumiAiScreen()),
              )
            : widget.onLogin,
      ),
      _setting(
        Icons.favorite_border_rounded,
        'Góc riêng của bạn',
        'Yêu thích, nhắc lịch, đặt lại và đánh giá',
        widget.isLoggedIn
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const LumiExperienceScreen(),
                ),
              )
            : widget.onLogin,
      ),
      const SizedBox.shrink(),
      _setting(
        Icons.settings_outlined,
        'Cài đặt',
        'Tùy chọn tài khoản',
        () => context.push('/settings'),
      ),
      const SizedBox.shrink(),
      _setting(
        Icons.location_on_outlined,
        'Địa chỉ nhận hàng',
        'Sổ địa chỉ giao nhận (chuẩn Shopee)',
        widget.isLoggedIn
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddressesScreen(),
                ),
              )
            : widget.onLogin,
      ),
      const SizedBox.shrink(),

      _setting(
        Icons.event_note_outlined,
        'Lịch sử liệu trình',
        'Xem các lịch hẹn của bạn',
        widget.isLoggedIn
            ? () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const TreatmentHistoryScreen(),
                ),
              )
            : widget.onLogin,
      ),
      const SizedBox.shrink(),
      if (widget.onOrders != null) ...[
        _setting(
          Icons.shopping_bag_outlined,
          'Đơn hàng của tôi',
          'Quản lý và theo dõi đơn mua sản phẩm',
          widget.onOrders!,
        ),
        const SizedBox.shrink(),
      ],
      _setting(
        Icons.support_agent_outlined,
        'Hỗ trợ và liên hệ',
        'Liên hệ với LUMI',
        () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LumiSupportScreen()),
        ),
      ),
    ],
  );

  Widget _setting(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final english = Localizations.localeOf(context).languageCode == 'en';
    final ink = dark ? const Color(0xFFFFF1E6) : const Color(0xFF463B35);
    final accent = dark ? const Color(0xFFF0BC9E) : const Color(0xFFA65A3E);
    final hints = <String, String>{
      'LUMI AI': english
          ? 'Chat and explore your care options'
          : 'Trò chuyện và khám phá cách chăm mình',
      'Góc riêng của bạn': english
          ? 'Favourites, reminders and reviews'
          : 'Yêu thích, nhắc lịch và đánh giá',
      'Cài đặt': english
          ? 'Language, appearance and preferences'
          : 'Ngôn ngữ, giao diện và tùy chọn',
      'Địa chỉ nhận hàng': english
          ? 'Manage your delivery addresses'
          : 'Quản lý địa chỉ giao nhận',
      'Lịch sử liệu trình': english
          ? 'Revisit your appointments'
          : 'Xem lại các lịch hẹn của bạn',
      'Đơn hàng của tôi': english
          ? 'Track your shopping journey'
          : 'Theo dõi hành trình mua sắm',
      'Hỗ trợ và liên hệ': english
          ? 'We are here to help'
          : 'LUMI luôn sẵn sàng hỗ trợ',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: LumiPressFeedback(
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF2D3837) : const Color(0xFFFFFDFA),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: dark ? const Color(0xFF46534E) : const Color(0xFFEDE1D6),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF604536)
                    .withValues(alpha: dark ? .02 : .045),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              hoverColor: accent.withValues(alpha: .06),
              splashColor: accent.withValues(alpha: .12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: dark
                            ? const Color(0xFF574237)
                            : const Color(0xFFF9E7D9),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: accent, size: 22),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LumiAdaptive.text(title),
                            style: LumiStyle.body(size: 15, color: ink)
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hints[title] ?? LumiAdaptive.text(subtitle),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: LumiStyle.body(
                              size: 12,
                              color: ink.withValues(alpha: .72),
                            ).copyWith(height: 1.45),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: accent,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String value) => Row(
    children: [
      Icon(icon, size: 17, color: LumiAdaptive.color(LumiStyle.muted)),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          LumiAdaptive.text(value.isEmpty ? '—' : value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LumiAdaptive.style(LumiStyle.body(size: 15)),
        ),
      ),
    ],
  );

  Widget _tierPill(String? tier) {
    if (tier == null || tier.trim().isEmpty) return const SizedBox.shrink();
    final lower = tier.toLowerCase();
    Color bg;
    Color fg;
    if (lower.contains('diamond') || lower.contains('kim cương')) {
      bg = const Color(0xFFE0F2FE);
      fg = const Color(0xFF0369A1);
    } else if (lower.contains('gold') || lower.contains('vàng')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFFB45309);
    } else if (lower.contains('silver') || lower.contains('bạc')) {
      bg = const Color(0xFFF1F5F9);
      fg = const Color(0xFF475569);
    } else {
      bg = LumiStyle.blushSurface;
      fg = LumiStyle.rose;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(bg, surface: true),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        LumiAdaptive.text(tier),
        style: LumiAdaptive.style(
          LumiStyle.body(
            size: 14,
            color: LumiAdaptive.color(fg, surface: true),
          ).copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    VoidCallback? onTap,
    Color background = LumiStyle.surface,
  }) => Container(
    decoration: BoxDecoration(
      color: LumiAdaptive.color(background, surface: true),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: LumiAdaptive.color(const Color(0x66FFFFFF))),
      boxShadow: [
        BoxShadow(
          color: LumiAdaptive.color(Color(0x07403735), surface: true),
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
