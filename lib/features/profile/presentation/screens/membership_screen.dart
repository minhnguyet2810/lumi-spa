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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Thẻ thành viên LUMI')),
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
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: CircularProgressIndicator(color: LumiStyle.rose),
                ),
              ),
            if (snapshot.hasError)
              _messageCard(
                icon: Icons.cloud_off_outlined,
                title: 'Không tải được dữ liệu thành viên',
                message: snapshot.error.toString(),
                action: TextButton(
                  onPressed: _retry,
                  child: const Text('Thử lại'),
                ),
              ),
            const SizedBox(height: 16),
            _benefitsCard(membership?.tier),
          ],
        );
      },
    ),
  );

  Widget _membershipHero(LumiMembership? membership) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: LumiStyle.plum,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: const BoxDecoration(
            color: Color(0x33FFFFFF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.workspace_premium_outlined,
            color: LumiStyle.ivory,
            size: 38,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'THÀNH VIÊN LUMI',
                style: LumiStyle.label(size: 10, color: LumiStyle.ivory),
              ),
              const SizedBox(height: 5),
              Text(
                membership?.tier ?? 'Hạng chưa xác định',
                style: LumiStyle.heading(size: 32, color: LumiStyle.ivory),
              ),
              Text(
                membership?.points == null
                    ? 'Điểm chưa khả dụng'
                    : '${membership!.points} điểm tích lũy',
                style: LumiStyle.body(size: 13, color: LumiStyle.ivory),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tiến trình thành viên', style: LumiStyle.heading(size: 25)),
          const SizedBox(height: 8),
          if (points == null)
            Text(
              'Điểm tích lũy hiện chưa khả dụng. Các thông tin thành viên khác vẫn được hiển thị.',
              style: LumiStyle.body(size: 14),
            )
          else if (points == 0)
            Text(
              'Bạn chưa có điểm tích lũy. Điểm sẽ được cập nhật khi hệ thống ghi nhận giao dịch đủ điều kiện.',
              style: LumiStyle.body(size: 14),
            )
          else
            Text(
              '$points điểm đã được ghi nhận. Mốc tiến hạng chưa được cung cấp.',
              style: LumiStyle.body(size: 14),
            ),
          if (membership?.isDefault == true) ...[
            const SizedBox(height: 12),
            Text(
              'Hệ thống hiện đang sử dụng trạng thái thành viên mặc định.',
              style: LumiStyle.body(size: 12),
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
        Text('Quyền lợi', style: LumiStyle.heading(size: 25)),
        const SizedBox(height: 4),
        Text(
          tier == null ? 'Đặc quyền dành cho thành viên' : 'Hạng $tier',
          style: LumiStyle.body(size: 13, color: LumiStyle.muted),
        ),
        const SizedBox(height: 12),
        _benefit(
          Icons.event_available_outlined,
          'Chủ động xem và quản lý lịch hẹn tại LUMI',
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

  Widget _benefit(IconData icon, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Icon(icon, size: 19, color: LumiStyle.rose),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: LumiStyle.body(size: 14))),
      ],
    ),
  );

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) => _card(
    child: Column(
      children: [
        Icon(icon, size: 32, color: LumiStyle.rose),
        const SizedBox(height: 8),
        Text(title, style: LumiStyle.body(size: 15, color: LumiStyle.plum)),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center, style: LumiStyle.body()),
        ?action,
      ],
    ),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: LumiStyle.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: LumiStyle.line),
    ),
    child: child,
  );
}
