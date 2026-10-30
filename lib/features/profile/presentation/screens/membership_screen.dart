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
          tier == null
              ? 'Thông tin hạng chưa khả dụng'
              : 'Dành cho hạng $tier',
          style: LumiStyle.body(size: 13),
        ),
        const SizedBox(height: 12),
        _benefit(Icons.spa_outlined, 'Ưu đãi dịch vụ làm đẹp'),
        _benefit(Icons.event_available_outlined, 'Ưu tiên cập nhật lịch hẹn'),
        _benefit(Icons.card_giftcard_outlined, 'Quà tặng trong các dịp đặc biệt'),
        const SizedBox(height: 8),
        Text(
          'Quyền lợi thực tế tùy thuộc vào hạng và chính sách hiện hành của LUMI.',
          style: LumiStyle.body(size: 12),
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
