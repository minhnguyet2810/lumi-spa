import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class LumiBookingScreen extends StatefulWidget {
  const LumiBookingScreen({super.key, required this.service});
  final Map<String, dynamic> service;

  @override
  State<LumiBookingScreen> createState() => _LumiBookingScreenState();
}

class _LumiBookingScreenState extends State<LumiBookingScreen> {
  static const ivory = Color(0xFFFFFAF8);
  static const rose = Color(0xFFB56F86);
  static const plum = Color(0xFF503B42);
  static const blush = Color(0xFFF4E4E8);
  static const blue = Color(0xFFDDECEF);
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  int? _hour;
  bool _busy = false;
  bool _done = false;
  String? _error;

  String get _name => (widget.service['name'] ?? 'Dịch vụ LUMI').toString();
  String get _serviceId => (widget.service['id'] ?? '').toString();
  String get _price => '${widget.service['price'] ?? 'Liên hệ'}';
  String get _duration => '${widget.service['durationMinutes'] ?? '—'} phút';
  String _dateText(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _hourText(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final chosen = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      helpText: 'Chọn ngày dành cho bạn',
    );
    if (chosen != null && mounted) {
      setState(() {
        _date = chosen;
        _hour = null;
        _error = null;
      });
    }
  }

  Future<void> _confirm() async {
    if (_busy || _hour == null) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Preserve this booking screen and its selected date/time while signing in.
      await context.push('/login');
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser != null) {
        await _confirm();
      } else {
        setState(() => _error = 'Đăng nhập để xác nhận lịch hẹn.');
      }
      return;
    }
    if (_serviceId.isEmpty) {
      setState(() => _error = 'Dịch vụ chưa có mã Firestore hợp lệ.');
      return;
    }
    final when = DateTime(_date.year, _date.month, _date.day, _hour!);
    if (!when.isAfter(DateTime.now())) {
      setState(() => _error = 'Vui lòng chọn một khung giờ trong tương lai.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // One booking per service/start-time. Transaction prevents same-slot races.
      // Firestore security rules must enforce authenticated ownership and immutable slot data.
      final slotId =
          '${_serviceId}_${_date.year}${_date.month.toString().padLeft(2, '0')}${_date.day.toString().padLeft(2, '0')}_${_hour!.toString().padLeft(2, '0')}00';
      final db = FirebaseFirestore.instance;
      final slot = db.collection('booking_slots').doc(slotId);
      await db.runTransaction((tx) async {
        final existing = await tx.get(slot);
        if (existing.exists) {
          throw StateError(
            'Khung giờ này đã được đặt. Vui lòng chọn giờ khác.',
          );
        }
        tx.set(slot, {
          'userId': user.uid,
          'serviceId': _serviceId,
          'serviceName': _name,
          'price': widget.service['price'],
          'durationMinutes': widget.service['durationMinutes'],
          'startAt': Timestamp.fromDate(when),
          'status': 'confirmed',
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) setState(() => _done = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is StateError ? e.message.toString() : 'Không thể xác nhận lịch. Kiểm tra kết nối và Firestore Rules rồi thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: ivory,
      appBar: AppBar(
        backgroundColor: ivory,
        foregroundColor: plum,
        title: Text(
          'LUMI · Đặt lịch',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: _done
            ? _success()
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(22),
                      children: [
                        Text(
                          'YOUR LUMI MOMENT',
                          style: GoogleFonts.dmSans(
                            color: rose,
                            letterSpacing: 2,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Một khoảng lặng\nchỉ dành cho bạn.',
                          style: GoogleFonts.cormorantGaramond(
                            color: plum,
                            fontSize: 37,
                            height: 1.04,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _panel(
                          blue,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LIỆU TRÌNH ĐÃ CHỌN',
                                style: GoogleFonts.dmSans(
                                  color: rose,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _name,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 29,
                                  color: plum,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Thời lượng: $_duration     ·     Giá: $_price',
                                style: GoogleFonts.dmSans(
                                  color: plum,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),
                        _heading('01', 'Chọn ngày'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_month_outlined),
                          label: Text(_dateText(_date)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: plum,
                            minimumSize: const Size(double.infinity, 55),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _heading('02', 'Chọn khung giờ'),
                        const SizedBox(height: 10),
                        Text(
                          'Khung giờ dự kiến · 09:00–18:00. Lịch trống được kiểm tra khi xác nhận.',
                          style: GoogleFonts.dmSans(
                            color: plum.withValues(alpha: .7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final h in [9, 10, 11, 12, 13, 14, 15, 16, 17])
                              ChoiceChip(
                                label: Text(_hourText(h)),
                                selected: _hour == h,
                                onSelected:
                                    DateTime(
                                      _date.year,
                                      _date.month,
                                      _date.day,
                                      h,
                                    ).isAfter(now)
                                    ? (_) => setState(() {
                                        _hour = h;
                                        _error = null;
                                      })
                                    : null,
                                selectedColor: blush,
                                labelStyle: GoogleFonts.dmSans(color: plum),
                              ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        if (_error != null)
                          Text(
                            _error!,
                            style: GoogleFonts.dmSans(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                    decoration: const BoxDecoration(
                      color: ivory,
                      border: Border(top: BorderSide(color: blush)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton(
                        onPressed: _hour == null || _busy ? null : _confirm,
                        style: FilledButton.styleFrom(backgroundColor: rose),
                        child: Text(
                          _busy ? 'ĐANG XÁC NHẬN...' : 'XÁC NHẬN LỊCH HẸN',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            letterSpacing: .7,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _heading(String number, String title) => Row(
    children: [
      CircleAvatar(
        radius: 17,
        backgroundColor: blush,
        child: Text(
          number,
          style: GoogleFonts.dmSans(
            color: rose,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        title,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 28,
          color: plum,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  Widget _panel(Color color, Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );

  Widget _success() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 68, color: rose),
          const SizedBox(height: 16),
          Text(
            'Your moment is reserved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(color: plum, fontSize: 35),
          ),
          const SizedBox(height: 10),
          Text(
            '$_name\n${_dateText(_date)} · ${_hourText(_hour!)}',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: plum, height: 1.7),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(backgroundColor: rose),
            child: const Text('TRỞ VỀ LUMI'),
          ),
        ],
      ),
    ),
  );
}
