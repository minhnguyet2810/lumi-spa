import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum LumiNotificationType { appointment, order, promotion, system }

class LumiNotification {
  const LumiNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final LumiNotificationType type;
  final bool isRead;
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const cream = Color(0xFFFFFAF8);
  static const blush = Color(0xFFF4E4E8);
  static const rose = Color(0xFFB56F86);
  static const blue = Color(0xFFDDECEF);
  static const ink = Color(0xFF503B42);
  static const muted = Color(0xFF765F67);

  // Dữ liệu thật sẽ được đưa vào đây khi tích hợp Firebase/API.
  // Không tạo thông báo giả.
  final List<LumiNotification> _notifications = [];

  final Set<String> _readIds = {};
  bool _unreadOnly = false;

  bool _isRead(LumiNotification item) =>
      item.isRead || _readIds.contains(item.id);

  void _markAllRead() {
    setState(() {
      _readIds.addAll(_notifications.map((item) => item.id));
    });
  }

  IconData _iconFor(LumiNotificationType type) {
    switch (type) {
      case LumiNotificationType.appointment:
        return Icons.calendar_month_outlined;
      case LumiNotificationType.order:
        return Icons.shopping_bag_outlined;
      case LumiNotificationType.promotion:
        return Icons.local_offer_outlined;
      case LumiNotificationType.system:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _notifications
        .where((item) => !_unreadOnly || !_isRead(item))
        .toList();

    final unreadCount = _notifications.where((item) => !_isRead(item)).length;

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Quay lại',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: ink,
            size: 21,
          ),
        ),
        title: Text(
          'Thông báo',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      unreadCount == 0
                          ? 'Cập nhật dành cho bạn'
                          : '$unreadCount thông báo chưa đọc',
                      style: GoogleFonts.dmSans(fontSize: 15, color: muted),
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: _markAllRead,
                      child: Text(
                        'Đánh dấu đã đọc',
                        style: GoogleFonts.dmSans(
                          color: rose,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _filterChip('Tất cả', !_unreadOnly, () {
                    setState(() => _unreadOnly = false);
                  }),
                  const SizedBox(width: 10),
                  _filterChip('Chưa đọc', _unreadOnly, () {
                    setState(() => _unreadOnly = true);
                  }),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: visible.isEmpty
                  ? _emptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _notificationCard(visible[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onPressed) {
    return Material(
      color: selected ? rose : blush,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 50),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                color: blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 48,
                color: Color(0xFF638A94),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              _unreadOnly
                  ? 'Bạn đã xem hết thông báo'
                  : 'Chưa có thông báo nào',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _unreadOnly
                  ? 'Những thông báo chưa đọc sẽ xuất hiện tại đây.'
                  : 'Lịch hẹn, ưu đãi và những cập nhật mới '
                        'từ LUMI sẽ được gửi đến bạn tại đây.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                height: 1.55,
                color: muted,
              ),
            ),
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                color: blush,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: rose,
                    size: 23,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'LUMI luôn đồng hành cùng hành trình '
                      'chăm sóc bản thân của bạn.',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        height: 1.45,
                        color: ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notificationCard(LumiNotification item) {
    final read = _isRead(item);

    return Material(
      color: read ? Colors.white : blush,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() => _readIds.add(item.id));
          // Điều hướng đến lịch hẹn/đơn hàng sẽ nối sau.
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(item.type), color: ink),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        height: 1.45,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!read)
                const Padding(
                  padding: EdgeInsets.only(left: 8, top: 5),
                  child: CircleAvatar(radius: 5, backgroundColor: rose),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
