import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LumiAppointmentsScreen extends StatefulWidget {
  const LumiAppointmentsScreen({
    super.key,
    required this.isLoggedIn,
    required this.onExploreServices,
    required this.onLogin,
  });

  final bool isLoggedIn;
  final VoidCallback onExploreServices;
  final VoidCallback onLogin;

  @override
  State<LumiAppointmentsScreen> createState() => _LumiAppointmentsScreenState();
}

class _LumiAppointmentsScreenState extends State<LumiAppointmentsScreen> {
  static const ink = Color(0xFF503B42);
  static const plum = Color(0xFF46313D);
  static const rose = Color(0xFFB56F86);
  static const blush = Color(0xFFF4E4E8);
  static const blue = Color(0xFFDDECEF);
  static const muted = Color(0xFF78676B);

  int selectedTab = 0;

  Widget _tabButton(String title, int index) {
    final selected = selectedTab == index;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => setState(() => selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: plum.withValues(alpha: 0.07),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? plum : muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    final upcoming = selectedTab == 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFF0E4E6)),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              color: upcoming ? blush : blue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              upcoming ? Icons.calendar_month_outlined : Icons.history_rounded,
              color: plum,
              size: 39,
            ),
          ),
          const SizedBox(height: 21),
          Text(
            upcoming ? 'Chưa có lịch hẹn sắp tới' : 'Chưa có lịch sử hiển thị',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 29,
              fontWeight: FontWeight.w700,
              color: ink,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 11),
          Text(
            !widget.isLoggedIn
                ? 'Đăng nhập để xem và quản lý những buổi chăm sóc '
                      'của riêng bạn tại LUMI.'
                : upcoming
                ? 'Lịch hẹn sẽ xuất hiện tại đây khi dữ liệu '
                      'đặt lịch được kết nối.'
                : 'Lịch sử chăm sóc sẽ được hiển thị khi '
                      'hệ thống lịch hẹn được kết nối.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 14, height: 1.55, color: muted),
          ),
          const SizedBox(height: 23),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: FilledButton.icon(
              onPressed: widget.isLoggedIn
                  ? widget.onExploreServices
                  : widget.onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: rose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: Icon(
                widget.isLoggedIn ? Icons.spa_outlined : Icons.login_rounded,
                size: 19,
              ),
              label: Text(
                widget.isLoggedIn ? 'KHÁM PHÁ DỊCH VỤ' : 'ĐĂNG NHẬP',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          if (!widget.isLoggedIn) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: widget.onExploreServices,
              child: Text(
                'Khám phá dịch vụ trước',
                style: GoogleFonts.dmSans(
                  color: rose,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_border_rounded, color: plum, size: 24),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Một chút thời gian cho bản thân',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Khám phá những liệu trình chăm sóc '
                  'và thư giãn tại LUMI SPA.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    height: 1.5,
                    color: muted,
                  ),
                ),
                const SizedBox(height: 9),
                InkWell(
                  onTap: widget.onExploreServices,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Xem dịch vụ',
                        style: GoogleFonts.dmSans(
                          color: rose,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: rose,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 115),
      children: [
        Text(
          'YOUR MOMENTS',
          style: GoogleFonts.dmSans(
            color: rose,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Lịch hẹn của bạn.',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 33,
            height: 1.05,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Mọi khoảnh khắc chăm sóc, trong một không gian riêng.',
          style: GoogleFonts.dmSans(fontSize: 14, height: 1.5, color: muted),
        ),
        const SizedBox(height: 23),
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: blush,
            borderRadius: BorderRadius.circular(19),
          ),
          child: Row(
            children: [_tabButton('Sắp tới', 0), _tabButton('Lịch sử', 1)],
          ),
        ),
        const SizedBox(height: 22),
        _emptyState(),
        const SizedBox(height: 20),
        _infoCard(),
        const SizedBox(height: 18),
        Center(
          child: Text(
            'LUMI SPA  •  MADE FOR YOUR MOMENTS',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: muted.withValues(alpha: 0.75),
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}
