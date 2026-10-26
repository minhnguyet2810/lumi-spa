import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumi_spa/core/theme/lumi_style.dart';
import 'package:lumi_spa/features/booking/data/booking_api_service.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';

class LumiBookingScreen extends StatefulWidget {
  const LumiBookingScreen({super.key, required this.service});
  final Map<String, dynamic> service;

  @override
  State<LumiBookingScreen> createState() => _LumiBookingScreenState();
}

class _LumiBookingScreenState extends State<LumiBookingScreen> {
  static const ivory = LumiStyle.ivory;
  static const rose = LumiStyle.rose;
  static const plum = LumiStyle.plum;
  static const blush = LumiStyle.softPink;

  DateTime _date = DateUtils.dateOnly(DateTime.now());
  int? _hour;
  bool _busy = false;
  BookingItem? _createdBooking;
  String? _error;

  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  String get _name => (widget.service['name'] ?? 'Dịch vụ LUMI').toString();
  String get _serviceId => (widget.service['id'] ?? '').toString();
  int get _durationMinutes => int.tryParse(widget.service['durationMinutes']?.toString() ?? '60') ?? 60;
  String get _duration => '$_durationMinutes phút';

  String get _price {
    final raw = widget.service['price'];
    if (raw == null) return 'Liên hệ';
    final n = num.tryParse(raw.toString());
    if (n == null || n <= 0) return 'Liên hệ';
    return '${n.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ';
  }

  String _dateText(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _hourText(int hour) => '${hour.toString().padLeft(2, '0')}:00';

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    _contactNameController.text = user?.displayName ?? '';
    _contactPhoneController.text = user?.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  bool _isSlotValid(int h) {
    // Spa opens 09:00 - 18:00. Service must end before or at 18:00.
    if (h * 60 + _durationMinutes > 18 * 60) return false;

    // Must be in future
    final slotTime = DateTime(_date.year, _date.month, _date.day, h);
    return slotTime.isAfter(DateTime.now());
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final chosen = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      helpText: 'Chọn ngày dành cho bạn',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: rose,
              onPrimary: Colors.white,
              surface: ivory,
              onSurface: plum,
            ),
          ),
          child: child!,
        );
      },
    );
    if (chosen != null && mounted) {
      setState(() {
        _date = chosen;
        _hour = null;
        _error = null;
      });
    }
  }

  Future<void> _showLoginRequiredSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: ivory,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: plum.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.lock_outline_rounded, size: 48, color: rose),
            const SizedBox(height: 14),
            Text(
              'Yêu cầu đăng nhập',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: plum,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quý khách vui lòng đăng nhập để lưu và quản lý lịch hẹn tại LUMI SPA.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14, color: plum.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.push('/login');
                },
                style: FilledButton.styleFrom(backgroundColor: rose),
                child: Text('ĐĂNG NHẬP NGAY', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm() async {
    if (_busy || _hour == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      await _showLoginRequiredSheet();
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser != null) {
        await _confirm();
      } else {
        setState(() => _error = 'Quý khách vui lòng đăng nhập để hoàn tất đặt lịch.');
      }
      return;
    }

    if (_serviceId.isEmpty) {
      setState(() => _error = 'Dịch vụ chưa có mã hợp lệ.');
      return;
    }

    if (!_isSlotValid(_hour!)) {
      setState(() => _error = 'Khung giờ này không khả dụng hoặc vượt quá giờ đóng cửa (18:00).');
      return;
    }

    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();

    if (contactName.isEmpty) {
      setState(() => _error = 'Vui lòng nhập họ và tên của bạn.');
      return;
    }

    if (contactPhone.isEmpty || !RegExp(r'^[0-9+().\s-]{8,20}$').hasMatch(contactPhone)) {
      setState(() => _error = 'Vui lòng nhập số điện thoại hợp lệ (8 - 20 số).');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final dateStr =
          '${_date.year.toString().padLeft(4, '0')}-'
          '${_date.month.toString().padLeft(2, '0')}-'
          '${_date.day.toString().padLeft(2, '0')}';

      final booking = await BookingApiService.instance.createBooking(
        serviceId: _serviceId,
        date: dateStr,
        hour: _hour!,
        contactName: contactName,
        contactPhone: contactPhone,
      );

      if (mounted) {
        setState(() {
          _createdBooking = booking;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: _createdBooking != null
            ? _buildSuccessView(_createdBooking!)
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
                          const Color(0xFFF0EBE6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LIỆU TRÌNH ĐÃ CHỌN',
                                style: GoogleFonts.dmSans(
                                  color: rose,
                                  fontSize: 11,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _name,
                                style: GoogleFonts.cormorantGaramond(
                                  fontSize: 28,
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
                        _heading('01', 'Chọn ngày đặt lịch'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_month_outlined, color: rose),
                          label: Text(_dateText(_date)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: plum,
                            side: const BorderSide(color: Color(0xFFE5DCDA)),
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _heading('02', 'Chọn khung giờ'),
                        const SizedBox(height: 8),
                        Text(
                          'Giờ hoạt động: 09:00 – 18:00 (dịch vụ phải kết thúc trước 18:00).',
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
                                onSelected: _isSlotValid(h)
                                    ? (_) => setState(() {
                                        _hour = h;
                                        _error = null;
                                      })
                                    : null,
                                selectedColor: blush,
                                disabledColor: Colors.black.withValues(alpha: 0.04),
                                labelStyle: GoogleFonts.dmSans(
                                  color: _isSlotValid(h) ? plum : Colors.grey,
                                  fontWeight: _hour == h ? FontWeight.w700 : FontWeight.normal,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _heading('03', 'Thông tin liên hệ'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Họ và tên *',
                            labelStyle: GoogleFonts.dmSans(color: plum.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE5DCDA)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactPhoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Số điện thoại liên hệ *',
                            labelStyle: GoogleFonts.dmSans(color: plum.withValues(alpha: 0.7)),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE5DCDA)),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.red.shade800,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
                    decoration: const BoxDecoration(
                      color: ivory,
                      border: Border(top: BorderSide(color: Color(0xFFEADFE1))),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _hour == null || _busy ? null : _confirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: rose,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'XÁC NHẬN LỊCH HẸN',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: .7,
                                  fontSize: 14,
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
            radius: 15,
            backgroundColor: blush,
            child: Text(
              number,
              style: GoogleFonts.dmSans(
                color: rose,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
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

  Widget _buildSuccessView(BookingItem booking) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: blush.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded, size: 50, color: rose),
            ),
            const SizedBox(height: 20),
            Text(
              'Booking Request Submitted',
              textAlign: TextAlign.center,
              style: GoogleFonts.cormorantGaramond(
                color: plum,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFEEBA)),
              ),
              child: Text(
                'TRẠNG THÁI: CHỜ XÁC NHẬN (PENDING)',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF856404),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFEADFE1)),
              ),
              child: Column(
                children: [
                  _summaryRow('Mã lịch hẹn:', '#${booking.id.isNotEmpty ? booking.id.substring(0, booking.id.length > 8 ? 8 : booking.id.length) : "LUMI"}'),
                  const Divider(height: 20),
                  _summaryRow('Dịch vụ:', booking.serviceName),
                  const Divider(height: 20),
                  _summaryRow('Thời gian:', '${_dateText(_date)} lúc ${_hourText(_hour!)}'),
                  const Divider(height: 20),
                  _summaryRow('Thời lượng:', '$_durationMinutes phút'),
                  const Divider(height: 20),
                  _summaryRow('Người đặt:', booking.contactName.isNotEmpty ? booking.contactName : _contactNameController.text),
                  const Divider(height: 20),
                  _summaryRow('Số điện thoại:', booking.contactPhone.isNotEmpty ? booking.contactPhone : _contactPhoneController.text),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Spa sẽ liên hệ xác nhận lịch trong ít phút. Quý khách có thể theo dõi trong mục Lịch hẹn của bạn.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: plum.withValues(alpha: .7),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: rose,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('HOÀN TẤT & VỀ TRANG CHỦ', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.dmSans(color: plum.withValues(alpha: 0.6), fontSize: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.dmSans(color: plum, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
