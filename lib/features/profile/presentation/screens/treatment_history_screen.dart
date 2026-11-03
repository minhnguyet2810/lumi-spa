import '../../../../core/theme/lumi_adaptive.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/lumi_style.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../booking/data/models/booking_item.dart';

class TreatmentHistoryScreen extends StatefulWidget {
  const TreatmentHistoryScreen({super.key});

  @override
  State<TreatmentHistoryScreen> createState() => _TreatmentHistoryScreenState();
}

class _TreatmentHistoryScreenState extends State<TreatmentHistoryScreen> {
  StreamSubscription<User?>? _authSubscription;
  Stream<List<BookingItem>>? _bookings;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _connect(FirebaseAuth.instance.currentUser?.uid);
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted || user?.uid == _uid) return;
      setState(() => _connect(user?.uid));
    });
  }

  void _connect(String? uid) {
    _uid = uid;
    _bookings = uid == null
        ? null
        : BookingRepository.instance.streamUserBookings(uid);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  TextStyle _type(
    double size, {
    bool bold = false,
    Color color = LumiStyle.ink,
  }) =>
      LumiStyle.body(
        size: size,
        color: LumiAdaptive.color(color, surface: true),
      ).copyWith(
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        letterSpacing: 0,
        height: 1.45,
      );

  String _status(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'pending':
        return 'Chờ duyệt';
      case 'approved':
      case 'confirmed':
        return 'Đã xác nhận';
      case 'completed':
        return 'Đã hoàn tất';
      case 'cancelled':
      case 'canceled':
        return 'Đã hủy';
      case 'rejected':
        return 'Không được duyệt';
      case 'no_show':
        return 'Không đến';
      default:
        return 'Trạng thái đang cập nhật';
    }
  }

  String _date(DateTime? value) {
    if (value == null) return 'Chưa có thời gian';
    final d = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}'
        ' · ${two(d.hour)}:${two(d.minute)}';
  }

  Widget _notice(
    IconData icon,
    String title,
    String description, {
    bool retry = false,
  }) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: LumiAdaptive.color(Color(0xFFFBE7DC), surface: true),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 38,
              color: LumiAdaptive.color(LumiStyle.rose),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            LumiAdaptive.text(title),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(_type(23, bold: true)),
          ),
          const SizedBox(height: 12),
          Text(
            LumiAdaptive.text(description),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(
              _type(
                16,
                color: LumiAdaptive.color(LumiStyle.muted, surface: true),
              ),
            ),
          ),
          if (retry) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => setState(() => _connect(_uid)),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(LumiAdaptive.text('Thử lại')),
            ),
          ],
        ],
      ),
    ),
  );

  Widget _entry(BookingItem item) {
    final status = item.status.trim().toLowerCase();
    final completed = status == 'completed';
    final cancelled = ['cancelled', 'canceled', 'rejected'].contains(status);
    final background = completed
        ? const Color(0xFFEDF1E5)
        : cancelled
        ? const Color(0xFFFBE7DC)
        : const Color(0xFFE6F1F5);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(LumiStyle.surface, surface: true),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: LumiAdaptive.color(LumiStyle.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: LumiAdaptive.color(background, surface: true),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.spa_outlined,
                  color: LumiAdaptive.color(LumiStyle.ink),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  LumiAdaptive.text(item.serviceName),
                  style: LumiAdaptive.style(_type(19, bold: true)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            LumiAdaptive.text(_date(item.startAt)),
            style: LumiAdaptive.style(_type(16)),
          ),
          const SizedBox(height: 8),
          Text(
            LumiAdaptive.text('${item.durationMinutes} phút'),
            style: LumiAdaptive.style(
              _type(
                15,
                color: LumiAdaptive.color(LumiStyle.muted, surface: true),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            decoration: BoxDecoration(
              color: LumiAdaptive.color(background, surface: true),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              LumiAdaptive.text(_status(item.status)),
              style: LumiAdaptive.style(_type(15, bold: true)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => Scaffold(
      backgroundColor: LumiAdaptive.color(LumiStyle.canvas, surface: true),
      appBar: AppBar(
        title: Text(
          LumiAdaptive.text('Lịch sử liệu trình'),
          style: LumiAdaptive.style(_type(23, bold: true)),
        ),
      ),
      body: _uid == null
          ? _notice(
              Icons.person_outline_rounded,
              'Bạn chưa đăng nhập',
              'Đăng nhập từ trang tài khoản để xem lịch sử của bạn.',
            )
          : StreamBuilder<List<BookingItem>>(
              key: ValueKey(_uid),
              stream: _bookings,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _notice(
                    Icons.cloud_off_outlined,
                    'Chưa tải được lịch sử',
                    'Vui lòng thử lại sau.',
                    retry: true,
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data!
                    .where((item) => item.userId == _uid)
                    .toList();
                items.sort(
                  (a, b) => (b.createdAt ?? b.startAt ?? DateTime(0)).compareTo(
                    a.createdAt ?? a.startAt ?? DateTime(0),
                  ),
                );

                if (items.isEmpty) {
                  return _notice(
                    Icons.spa_outlined,
                    'Bạn chưa đăng ký dịch vụ nào',
                    'Các liệu trình bạn đăng ký tại LUMI sẽ xuất hiện ở đây.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Text(
                      LumiAdaptive.text('${items.length} lượt đăng ký'),
                      style: LumiAdaptive.style(_type(22, bold: true)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      LumiAdaptive.text(
                        'Tổng hợp các liệu trình và trạng thái đăng ký của bạn.',
                      ),
                      style: LumiAdaptive.style(
                        _type(
                          16,
                          color: LumiAdaptive.color(
                            LumiStyle.muted,
                            surface: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...items.map(_entry),
                  ],
                );
              },
            ),
    ),
  );
}
