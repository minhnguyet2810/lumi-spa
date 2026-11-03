import '../../../../core/theme/lumi_adaptive.dart';

import 'package:flutter/material.dart';

import '../../../../core/data/lumi_account_repository.dart';
import '../../../../core/theme/lumi_style.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late Future<LumiMembership> _membershipFuture;

  @override
  void initState() {
    super.initState();
    _membershipFuture = LumiAccountRepository.fetchMembership();
  }

  void _retry() {
    setState(() {
      _membershipFuture = LumiAccountRepository.fetchMembership();
    });
  }

  @override
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => Scaffold(
      appBar: AppBar(title: Text(LumiAdaptive.text('Thẻ thành viên LUMI'))),
      body: FutureBuilder<LumiMembership>(
        future: _membershipFuture,
        builder: (context, snapshot) {
          final membership = snapshot.data;
          final loading = snapshot.connectionState == ConnectionState.waiting;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _membershipHero(membership),
              const SizedBox(height: 16),
              _progressCard(membership),
              const SizedBox(height: 16),
              if (loading && membership == null)
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: LumiAdaptive.color(LumiStyle.rose),
                    ),
                  ),
                ),
              if (snapshot.hasError)
                _messageCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Không tải được dữ liệu thành viên',
                  message: snapshot.error.toString(),
                  action: TextButton(
                    onPressed: _retry,
                    child: Text(LumiAdaptive.text('Thử lại')),
                  ),
                ),
<<<<<<< HEAD
              ),
            const SizedBox(height: 16),
            _benefitsCard(membership?.tier),
          ],
        );
      },
=======
              _benefitsCard(membership?.tier),
            ],
          );
        },
      ),
>>>>>>> f69fef543243a3b629319035f2b9c062ba0b8aab
    ),
  );

  Widget _membershipHero(LumiMembership? membership) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: LumiAdaptive.color(const Color(0xFFFBE7DC), surface: true),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: LumiAdaptive.color(const Color(0xFFFFFDFA))),
      boxShadow: [
        BoxShadow(
          color: LumiAdaptive.color(Color(0x12403735), surface: true),
          blurRadius: 24,
          offset: Offset(0, 8),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            SizedBox(
              height: 170,
              width: double.infinity,
              child: Image.asset(
                'assets/images/welcome_spa_5.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.25),
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => ColoredBox(
                  color: LumiAdaptive.color(Color(0xFFE6F1F5), surface: true),
                  child: Center(
                    child: Icon(
                      Icons.spa_outlined,
                      size: 48,
                      color: LumiAdaptive.color(Color(0xFF406779)),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      LumiAdaptive.color(Color(0x6630241F), surface: true),
                      LumiAdaptive.color(Color(0x0030241F), surface: true),
                      LumiAdaptive.color(Color(0x4430241F), surface: true),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              left: 20,
              child: Text(
                LumiAdaptive.text('LUMI'),
                style: LumiAdaptive.style(
                  LumiStyle.body(
                    size: 26,
                    color: LumiAdaptive.color(Colors.white, surface: true),
                  ).copyWith(
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 18,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LumiAdaptive.color(Color(0xFFFFF8EF), surface: true),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: LumiAdaptive.color(Color(0xFFA5553E)),
                  size: 27,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LumiAdaptive.text('Thẻ thành viên của bạn'),
                style: LumiAdaptive.style(
                  LumiStyle.body(
                    size: 16,
                    color: LumiAdaptive.color(LumiStyle.ink, surface: true),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      LumiAdaptive.text(membership?.tier ?? 'Chưa xác định'),
                      style: LumiAdaptive.style(
                        LumiStyle.body(
                          size: 27,
                          color: LumiAdaptive.color(
                            LumiStyle.ink,
                            surface: true,
                          ),
                        ).copyWith(fontWeight: FontWeight.w600, height: 1.25),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          LumiAdaptive.text(
                            membership?.points?.toString() ?? '—',
                          ),
                          textAlign: TextAlign.right,
                          style: LumiAdaptive.style(
                            LumiStyle.body(
                              size: 34,
                              color: LumiAdaptive.color(
                                LumiStyle.ink,
                                surface: true,
                              ),
                            ).copyWith(
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          LumiAdaptive.text('điểm tích lũy'),
                          textAlign: TextAlign.right,
                          style: LumiAdaptive.style(
                            LumiStyle.body(
                              size: 15,
                              color: LumiAdaptive.color(
                                LumiStyle.ink,
                                surface: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _progressCard(LumiMembership? membership) {
    final points = membership?.points;
    return _card(
      background: const Color(0xFFEAF3F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LumiAdaptive.text('Tích lũy của bạn'),
            style: LumiAdaptive.style(
              LumiStyle.body(
                size: 22,
                color: LumiAdaptive.color(LumiStyle.ink, surface: true),
              ).copyWith(fontWeight: FontWeight.w600, height: 1.3),
            ),
          ),
          const SizedBox(height: 8),
          if (points == null)
            Text(
              LumiAdaptive.text('Chưa có thông tin điểm tích lũy.'),
              style: LumiAdaptive.style(LumiStyle.body(size: 16)),
            )
          else if (points == 0)
            Text(
              LumiAdaptive.text(
                'Điểm sẽ được cập nhật sau giao dịch đủ điều kiện.',
              ),
              style: LumiAdaptive.style(LumiStyle.body(size: 16)),
            )
          else
            Text(
              LumiAdaptive.text(
                '$points điểm đã được ghi nhận. Mốc tiến hạng chưa được cung cấp.',
              ),
              style: LumiAdaptive.style(LumiStyle.body(size: 16)),
            ),
          if (membership?.isDefault == true) ...[
            const SizedBox(height: 12),
            Text(
              LumiAdaptive.text('Bạn đang ở hạng thành viên mặc định.'),
              style: LumiAdaptive.style(LumiStyle.body(size: 14)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _benefitsCard(String? tier) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LumiAdaptive.text('Quyền lợi'),
          style: LumiAdaptive.style(
            LumiStyle.body(
              size: 22,
              color: LumiAdaptive.color(LumiStyle.ink, surface: true),
            ).copyWith(fontWeight: FontWeight.w600, height: 1.3),
          ),
        ),
        const SizedBox(height: 4),
        Text(
<<<<<<< HEAD
          tier == null ? 'Đặc quyền dành cho thành viên' : 'Hạng $tier',
          style: LumiStyle.body(size: 13, color: LumiStyle.muted),
        ),
        const SizedBox(height: 12),
        _benefit(
          Icons.event_available_outlined,
          'Chủ động xem và quản lý lịch hẹn tại LUMI',
=======
          LumiAdaptive.text(
            tier == null
                ? 'Thông tin hạng chưa khả dụng'
                : 'Dành cho hạng $tier',
          ),
          style: LumiAdaptive.style(LumiStyle.body(size: 16)),
        ),
        const SizedBox(height: 12),
        _benefit(Icons.spa_outlined, 'Ưu đãi dịch vụ làm đẹp'),
        _benefit(Icons.event_available_outlined, 'Ưu tiên cập nhật lịch hẹn'),
        _benefit(
          Icons.card_giftcard_outlined,
          'Quà tặng trong các dịp đặc biệt',
        ),
        const SizedBox(height: 8),
        Text(
          LumiAdaptive.text(
            'Quyền lợi thực tế tùy thuộc vào hạng và chính sách hiện hành của LUMI.',
          ),
          style: LumiAdaptive.style(LumiStyle.body(size: 14)),
>>>>>>> f69fef543243a3b629319035f2b9c062ba0b8aab
        ),
        _benefit(
          Icons.spa_outlined,
          'Khám phá liệu trình và ưu đãi phù hợp',
        ),
        _benefit(
          Icons.stars_outlined,
          'Theo dõi điểm tích lũy khi được hệ thống cập nhật',
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _showOtherTierBenefits(tier),
            style: OutlinedButton.styleFrom(
              foregroundColor: LumiStyle.plum,
              side: const BorderSide(color: LumiStyle.line),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Xem quyền lợi các hạng thành viên khác'),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, size: 17),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  void _showOtherTierBenefits(String? currentTier) {
    const tierBenefits = <({String name, IconData icon, List<String> benefits})>[
      (
        name: 'Member',
        icon: Icons.spa_outlined,
        benefits: [
          'Quản lý lịch hẹn và thông tin chăm sóc cá nhân',
          'Cập nhật điểm tích lũy khi hệ thống ghi nhận',
          'Nhận thông tin dịch vụ và hoạt động mới của LUMI',
        ],
      ),
      (
        name: 'Silver',
        icon: Icons.workspace_premium_outlined,
        benefits: [
          'Các tiện ích của hạng Member',
          'Ưu tiên tiếp cận một số chương trình dành cho hội viên',
          'Quà tặng hoặc ưu đãi trong dịp sinh nhật',
        ],
      ),
      (
        name: 'Gold',
        icon: Icons.military_tech_outlined,
        benefits: [
          'Các tiện ích của hạng Silver',
          'Ưu tiên lựa chọn khung giờ cho liệu trình',
          'Ưu đãi chọn lọc cho dịch vụ chăm sóc',
        ],
      ),
      (
        name: 'Platinum',
        icon: Icons.diamond_outlined,
        benefits: [
          'Các tiện ích của hạng Gold',
          'Hỗ trợ tư vấn và sắp xếp lịch hẹn ưu tiên',
          'Trải nghiệm quà tặng dành riêng cho hội viên',
        ],
      ),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: LumiStyle.ivory,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.88,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                'Các hạng thành viên',
                style: LumiStyle.heading(size: 30),
              ),
              const SizedBox(height: 6),
              Text(
                'Khám phá những đặc quyền được gợi ý cho từng cấp độ hội viên.',
                style: LumiStyle.body(size: 14),
              ),
              const SizedBox(height: 16),
              for (final (index, tier) in tierBenefits.indexed) ...[
                _tierBenefitsCard(
                  tier,
                  isCurrentTier:
                      currentTier?.toLowerCase() == tier.name.toLowerCase(),
                ),
                if (index < tierBenefits.length - 1)
                  const SizedBox(height: 12),
              ],
              const SizedBox(height: 14),
              Text(
                'Các hạng và quyền lợi trong danh sách này mang tính minh họa. '
                'Hạng hiện tại và điểm của bạn chỉ hiển thị theo dữ liệu backend; '
                'chính sách chính thức sẽ theo thông báo của LUMI.',
                style: LumiStyle.body(size: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tierBenefitsCard(
    ({String name, IconData icon, List<String> benefits}) tier, {
    required bool isCurrentTier,
  }) => _card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(tier.icon, color: LumiStyle.rose),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tier.name,
                style: LumiStyle.body(
                  size: 17,
                  color: LumiStyle.plum,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (isCurrentTier)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: LumiStyle.blushSurface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Hạng hiện tại',
                  style: LumiStyle.body(size: 11, color: LumiStyle.rose),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final benefit in tier.benefits)
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: LumiStyle.rose,
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(benefit, style: LumiStyle.body(size: 13))),
              ],
            ),
          ),
      ],
    ),
  );

  Widget _benefit(IconData icon, String text) {
    final background = icon == Icons.spa_outlined
        ? const Color(0xFFFBE7DC)
        : icon == Icons.event_available_outlined
        ? const Color(0xFFE6F1F5)
        : const Color(0xFFEDF1E5);

    final foreground = icon == Icons.spa_outlined
        ? const Color(0xFFA5553E)
        : icon == Icons.event_available_outlined
        ? const Color(0xFF406779)
        : const Color(0xFF526442);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: LumiAdaptive.color(background, surface: true),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, size: 25, color: LumiAdaptive.color(foreground)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              LumiAdaptive.text(text),
              style: LumiAdaptive.style(
                LumiStyle.body(
                  size: 17,
                  color: LumiAdaptive.color(LumiStyle.ink, surface: true),
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) => _card(
    child: Column(
      children: [
        Icon(icon, size: 32, color: LumiAdaptive.color(LumiStyle.rose)),
        const SizedBox(height: 8),
        Text(
          LumiAdaptive.text(title),
          style: LumiAdaptive.style(
            LumiStyle.body(
              size: 15,
              color: LumiAdaptive.color(LumiStyle.plum, surface: true),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          LumiAdaptive.text(message),
          textAlign: TextAlign.center,
          style: LumiAdaptive.style(LumiStyle.body()),
        ),
        ?action,
      ],
    ),
  );

  Widget _card({required Widget child, Color background = LumiStyle.surface}) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: LumiAdaptive.color(background, surface: true),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: LumiAdaptive.color(const Color(0xFFEDE4DB)),
          ),
        ),
        child: child,
      );
}
