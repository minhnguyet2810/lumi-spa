import '../../../../core/theme/lumi_adaptive.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/lumi_style.dart';

class LumiSupportScreen extends StatefulWidget {
  const LumiSupportScreen({super.key});

  @override
  State<LumiSupportScreen> createState() => _LumiSupportScreenState();
}

class _LumiSupportScreenState extends State<LumiSupportScreen> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _contacts;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _contacts = FirebaseFirestore.instance
        .collection('app_config')
        .doc('support')
        .snapshots();
  }

  TextStyle _type(double size, {bool bold = false}) =>
      LumiStyle.body(
        size: size,
        color: LumiAdaptive.color(LumiStyle.ink, surface: true),
      ).copyWith(
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
      );

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: LumiAdaptive.color(LumiStyle.surface, surface: true),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: LumiAdaptive.color(LumiStyle.line)),
    ),
    child: child,
  );

  Widget _contact(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: LumiAdaptive.color(const Color(0xFFE6F1F5), surface: true),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: LumiAdaptive.color(const Color(0xFF406779)),
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LumiAdaptive.text(label),
                style: LumiAdaptive.style(_type(17, bold: true)),
              ),
              const SizedBox(height: 4),
              SelectableText(value, style: LumiAdaptive.style(_type(16))),
            ],
          ),
        ),
        IconButton(
          tooltip: LumiAdaptive.optionalText('Sao chép $label'),
          icon: const Icon(Icons.copy_outlined, size: 21),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: value));
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(LumiAdaptive.text('Đã sao chép'))),
            );
          },
        ),
      ],
    ),
  );

  Widget _faq(String question, String answer) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 16),
    title: Text(
      LumiAdaptive.text(question),
      style: LumiAdaptive.style(_type(17, bold: true)),
    ),
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Text(
          LumiAdaptive.text(answer),
          style: LumiAdaptive.style(_type(16)),
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => Scaffold(
      backgroundColor: LumiAdaptive.color(LumiStyle.canvas, surface: true),
      appBar: AppBar(
        title: Text(
          LumiAdaptive.text('Hỗ trợ và liên hệ'),
          style: LumiAdaptive.style(_type(23, bold: true)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: LumiAdaptive.color(const Color(0xFFFBE7DC), surface: true),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  size: 38,
                  color: LumiAdaptive.color(LumiStyle.rose),
                ),
                const SizedBox(height: 16),
                Text(
                  LumiAdaptive.text('Bạn cần hỗ trợ?'),
                  style: LumiAdaptive.style(_type(27, bold: true)),
                ),
                const SizedBox(height: 10),
                Text(
                  LumiAdaptive.text(
                    'Tìm thông tin liên hệ và hướng dẫn sử dụng LUMI.',
                  ),
                  style: LumiAdaptive.style(_type(16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            LumiAdaptive.text('Liên hệ LUMI'),
            style: LumiAdaptive.style(_type(22, bold: true)),
          ),
          const SizedBox(height: 14),
          _card(
            StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _contacts,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LumiAdaptive.text('Chưa tải được thông tin liên hệ.'),
                        style: LumiAdaptive.style(_type(16)),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(_connect),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(LumiAdaptive.text('Thử lại')),
                      ),
                    ],
                  );
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final data = snapshot.data!.data() ?? {};
                final rows = <Widget>[];

                void add(String key, String label, IconData icon) {
                  final raw = data[key];
                  if (raw is String && raw.trim().isNotEmpty) {
                    rows.add(_contact(icon, label, raw.trim()));
                  }
                }

                add('phone', 'Điện thoại', Icons.phone_outlined);
                add('email', 'Email', Icons.mail_outline_rounded);
                add('zalo', 'Zalo', Icons.chat_bubble_outline_rounded);
                add('address', 'Địa chỉ', Icons.location_on_outlined);
                add('hours', 'Giờ hoạt động', Icons.schedule_rounded);

                if (rows.isEmpty) {
                  return Text(
                    LumiAdaptive.text('Thông tin liên hệ chưa được cập nhật.'),
                    style: LumiAdaptive.style(_type(16)),
                  );
                }

                return Column(children: rows);
              },
            ),
          ),
          const SizedBox(height: 26),
          Text(
            LumiAdaptive.text('Câu hỏi thường gặp'),
            style: LumiAdaptive.style(_type(22, bold: true)),
          ),
          const SizedBox(height: 14),
          _card(
            Column(
              children: [
                _faq(
                  'Đăng ký liệu trình ở đâu?',
                  'Mở tab Spa, chọn dịch vụ và thực hiện các bước đặt lịch.',
                ),
                _faq(
                  'Xem lịch đã đăng ký ở đâu?',
                  'Mở tab Lịch hẹn để xem trạng thái đăng ký của bạn.',
                ),
                _faq(
                  'Xem đơn hàng ở đâu?',
                  'Vào Tôi → Đơn hàng của tôi để theo dõi đơn mua sản phẩm.',
                ),
                _faq(
                  'Chỉnh sửa thông tin cá nhân thế nào?',
                  'Vào Tôi → Chỉnh sửa hồ sơ để cập nhật tên và số điện thoại.',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
