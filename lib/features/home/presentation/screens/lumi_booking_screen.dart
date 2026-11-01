import '../../../../core/widgets/lumi_catalog_image.dart';
import '../../../../core/theme/lumi_adaptive.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumi_spa/core/theme/lumi_style.dart';
import 'package:lumi_spa/features/booking/data/booking_repository.dart';
import 'package:lumi_spa/features/booking/data/models/booking_item.dart';
import 'package:lumi_spa/features/booking/data/models/slot_availability.dart';

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
  bool _loadingSlots = false;
  List<SlotAvailability> _slots = [];
  BookingItem? _createdBooking;
  String? _error;

  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  String get _name => (widget.service['name'] ?? 'Dịch vụ LUMI').toString();
  String get _serviceId => (widget.service['id'] ?? '').toString();
  String? get _categoryId => widget.service['categoryId']?.toString();
  int get _durationMinutes =>
      int.tryParse(widget.service['durationMinutes']?.toString() ?? '60') ?? 60;
  String get _duration => '$_durationMinutes phút';

  num get _rawPrice {
    final raw = widget.service['price'];
    if (raw == null) return 0;
    return num.tryParse(raw.toString()) ?? 0;
  }

  String get _price {
    final n = _rawPrice;
    if (n <= 0) return 'Liên hệ';
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
    _loadSlots();
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() {
      _loadingSlots = true;
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final slots = await BookingRepository.instance.getAvailableSlots(
        date: _date,
        serviceId: _serviceId,
        categoryId: _categoryId,
        durationMinutes: _durationMinutes,
        currentUserId: user?.uid,
      );

      if (mounted) {
        setState(() {
          _slots = slots;
          _loadingSlots = false;
          // Nếu giờ đang chọn bị rơi vào slot không khả dụng thì hủy chọn
          if (_hour != null) {
            final currentSlot = slots.firstWhere(
              (s) => s.hour == _hour,
              orElse: () =>
                  const SlotAvailability(hour: -1, status: SlotStatus.past),
            );
            if (!currentSlot.isAvailable) {
              _hour = null;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSlots = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final chosen = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
      helpText: LumiAdaptive.optionalText('Chọn ngày dành cho bạn'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context)
              .copyWith(colorScheme: Theme.of(context).colorScheme),
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
      await _loadSlots();
    }
  }

  Future<void> _showLoginRequiredSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: LumiAdaptive.color(ivory, surface: true),
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
                color: LumiAdaptive.color(
                  plum.withValues(alpha: 0.2),
                  surface: true,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(
              Icons.lock_outline_rounded,
              size: 48,
              color: LumiAdaptive.color(rose),
            ),
            const SizedBox(height: 14),
            Text(
              LumiAdaptive.text('Yêu cầu đăng nhập'),
              style: LumiAdaptive.style(
                GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: LumiAdaptive.color(plum),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LumiAdaptive.text(
                'Quý khách vui lòng đăng nhập để lưu và quản lý lịch hẹn tại LUMI SPA.',
              ),
              textAlign: TextAlign.center,
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  fontSize: 14,
                  color: LumiAdaptive.color(plum.withValues(alpha: 0.7)),
                ),
              ),
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
                style: LumiAdaptive.style(
                  FilledButton.styleFrom(
                    backgroundColor: LumiAdaptive.color(rose, surface: true),
                  ),
                ),
                child: Text(
                  LumiAdaptive.text('ĐĂNG NHẬP NGAY'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSlotTapped(SlotAvailability slot) {
    if (slot.isAvailable) {
      setState(() {
        _hour = slot.hour;
        _error = null;
      });
    } else {
      // Hiển thị giải thích lý do khung giờ không chọn được
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LumiAdaptive.text('${slot.timeText}: ${slot.explanation}'),
          ),
          backgroundColor: LumiAdaptive.color(
            slot.status == SlotStatus.userConflict
                ? Colors.amber.shade900
                : plum,
            surface: true,
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
        setState(
          () => _error = 'Quý khách vui lòng đăng nhập để hoàn tất đặt lịch.',
        );
      }
      return;
    }

    if (_serviceId.isEmpty) {
      setState(() => _error = 'Dịch vụ chưa có mã hợp lệ.');
      return;
    }

    final selectedSlot = _slots.firstWhere(
      (s) => s.hour == _hour,
      orElse: () => const SlotAvailability(hour: -1, status: SlotStatus.past),
    );

    if (!selectedSlot.isAvailable) {
      setState(() => _error = selectedSlot.explanation);
      return;
    }

    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();

    if (contactName.isEmpty) {
      setState(() => _error = 'Vui lòng nhập họ và tên của bạn.');
      return;
    }

    if (contactPhone.isEmpty ||
        !RegExp(r'^[0-9+().\s-]{8,20}$').hasMatch(contactPhone)) {
      setState(
        () => _error = 'Vui lòng nhập số điện thoại hợp lệ (8 - 20 số).',
      );
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final booking = await BookingRepository.instance.createBooking(
        serviceId: _serviceId,
        serviceName: _name,
        categoryId: _categoryId,
        price: _rawPrice,
        durationMinutes: _durationMinutes,
        date: _date,
        hour: _hour!,
        contactName: contactName,
        contactPhone: contactPhone,
      );

      if (mounted) {
        setState(() {
          _createdBooking = booking;
        });
      }
    } on BookingConflictException catch (conflictEx) {
      if (mounted) {
        setState(() {
          _error = conflictEx.message;
        });
        _loadSlots(); // Tải lại danh sách slot để cập nhật
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        _loadSlots();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
    return Scaffold(
      backgroundColor: LumiAdaptive.color(ivory, surface: true),
      appBar: AppBar(
        backgroundColor: LumiAdaptive.color(ivory, surface: true),
        foregroundColor: LumiAdaptive.color(plum),
        title: Text(
          LumiAdaptive.text('LUMI · Đặt lịch'),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(fontWeight: FontWeight.w600),
          ),
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
                        _bookingIntro(),
                        const SizedBox(height: 28),
                        _heading('01', 'Chọn ngày đặt lịch'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: Icon(
                            Icons.calendar_month_outlined,
                            color: LumiAdaptive.color(rose),
                          ),
                          label: Text(LumiAdaptive.text(_dateText(_date))),
                          style: LumiAdaptive.style(
                            OutlinedButton.styleFrom(
                              foregroundColor: LumiAdaptive.color(plum),
                              side: BorderSide(
                                color: LumiAdaptive.color(Color(0xFFE5DCDA)),
                              ),
                              minimumSize: const Size(double.infinity, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _heading('02', 'Chọn khung giờ'),
                            if (_loadingSlots)
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: LumiAdaptive.color(rose),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          LumiAdaptive.text(
                            'Spa mở cửa 09:00 – 18:00. Hiển thị trạng thái slot còn trống theo thời gian thực.',
                          ),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              color: LumiAdaptive.color(
                                plum.withValues(alpha: .7),
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildSlotsGrid(),
                        const SizedBox(height: 24),
                        _heading('03', 'Thông tin liên hệ'),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactNameController,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: LumiAdaptive.optionalText('Họ và tên *'),
                            labelStyle: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                color: LumiAdaptive.color(
                                  plum.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            filled: true,
                            fillColor: LumiAdaptive.color(
                              Colors.white,
                              surface: true,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: LumiAdaptive.color(Color(0xFFE5DCDA)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _contactPhoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: LumiAdaptive.optionalText(
                              'Số điện thoại liên hệ *',
                            ),
                            labelStyle: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                color: LumiAdaptive.color(
                                  plum.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                            filled: true,
                            fillColor: LumiAdaptive.color(
                              Colors.white,
                              surface: true,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(
                                color: LumiAdaptive.color(Color(0xFFE5DCDA)),
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: LumiAdaptive.color(
                                Colors.red.shade50,
                                surface: true,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: LumiAdaptive.color(Colors.red.shade200),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: LumiAdaptive.color(
                                    Colors.red.shade700,
                                  ),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    LumiAdaptive.text(_error!),
                                    style: LumiAdaptive.style(
                                      GoogleFonts.dmSans(
                                        color: LumiAdaptive.color(
                                          Colors.red.shade800,
                                        ),
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
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
                    decoration: BoxDecoration(
                      color: LumiAdaptive.color(ivory),
                      border: Border(
                        top: BorderSide(
                          color: LumiAdaptive.color(Color(0xFFEADFE1)),
                        ),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton(
                        onPressed: _hour == null || _busy ? null : _confirm,
                        style: LumiAdaptive.style(
                          FilledButton.styleFrom(
                            backgroundColor: LumiAdaptive.color(
                              rose,
                              surface: true,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        child: _busy
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: LumiAdaptive.color(Colors.white),
                                ),
                              )
                            : Text(
                                LumiAdaptive.text('XÁC NHẬN LỊCH HẸN'),
                                style: LumiAdaptive.style(
                                  GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .7,
                                    fontSize: 14,
                                  ),
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

  Widget _buildSlotsGrid() {
    if (_slots.isEmpty && _loadingSlots) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CircularProgressIndicator(color: LumiAdaptive.color(rose)),
        ),
      );
    }

    // Nếu chưa load xong từ Firestore thì fallback standard
    final slotsList = _slots.isNotEmpty
        ? _slots
        : [9, 10, 11, 12, 13, 14, 15, 16, 17].map((h) {
            final slotTime = DateTime(_date.year, _date.month, _date.day, h);
            final isPast = slotTime.isBefore(DateTime.now());
            final isClosed = h * 60 + _durationMinutes > 18 * 60;
            return SlotAvailability(
              hour: h,
              status: isClosed
                  ? SlotStatus.closedExceeded
                  : (isPast ? SlotStatus.past : SlotStatus.available),
              remainingCapacity: isClosed || isPast ? 0 : 2,
            );
          }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: slotsList.map((slot) {
            final isSelected = _hour == slot.hour;
            final isAvail = slot.isAvailable;

            Color bgColor;
            Color borderColor;
            Color textColor;

            if (isSelected) {
              bgColor = blush;
              borderColor = rose;
              textColor = plum;
            } else if (isAvail) {
              bgColor = Colors.white;
              borderColor = const Color(0xFFE5DCDA);
              textColor = plum;
            } else if (slot.status == SlotStatus.userConflict) {
              bgColor = const Color(0xFFFFF3CD);
              borderColor = const Color(0xFFFFEEBA);
              textColor = const Color(0xFF856404);
            } else {
              bgColor = Colors.black.withValues(alpha: 0.03);
              borderColor = Colors.black.withValues(alpha: 0.05);
              textColor = Colors.grey.shade500;
            }

            return InkWell(
              onTap: () => _onSlotTapped(slot),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 100,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: LumiAdaptive.color(bgColor, surface: true),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: LumiAdaptive.color(isSelected ? rose : borderColor),
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      LumiAdaptive.text(slot.timeText),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: LumiAdaptive.color(textColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      LumiAdaptive.text(slot.statusBadge),
                      textAlign: TextAlign.center,
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: isAvail
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: LumiAdaptive.color(
                            isAvail
                                ? const Color(0xFF2E7D32)
                                : (slot.status == SlotStatus.userConflict
                                      ? const Color(0xFF856404)
                                      : Colors.grey.shade500),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _legendItem(const Color(0xFF2E7D32), 'Còn trống'),
            const SizedBox(width: 14),
            _legendItem(const Color(0xFF856404), 'Trùng lịch'),
            const SizedBox(width: 14),
            _legendItem(Colors.grey.shade500, 'Hết chỗ / Đã qua'),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: LumiAdaptive.color(color, surface: true),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          LumiAdaptive.text(label),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              fontSize: 11,
              color: LumiAdaptive.color(plum.withValues(alpha: 0.65)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bookingIntro() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF604A3D), const Color(0xFF344E5B)]
              : [
                  const Color(0xFFF8D5C2),
                  const Color(0xFFF3E7D9),
                  const Color(0xFFDCECF1),
                ],
        ),
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LumiCatalogImage(item: widget.service, height: 155),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LumiAdaptive.text('YOUR LUMI MOMENT'),
                  style: GoogleFonts.dmSans(
                    color: colors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  LumiAdaptive.text('Một khoảng lặng\nchỉ dành cho bạn.'),
                  style: GoogleFonts.dmSans(
                    fontSize: 28,
                    height: 1.2,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  LumiAdaptive.text('LIỆU TRÌNH ĐÃ CHỌN'),
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _name,
                  style: GoogleFonts.dmSans(
                    fontSize: 21,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(
                      avatar: Icon(
                        Icons.schedule_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      label: Text(LumiAdaptive.text(_duration)),
                      backgroundColor: colors.surface,
                      side: BorderSide.none,
                    ),
                    Chip(
                      avatar: Icon(
                        Icons.spa_outlined,
                        size: 18,
                        color: colors.primary,
                      ),
                      label: Text(_price),
                      backgroundColor: colors.surface,
                      side: BorderSide.none,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heading(String number, String title) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colors.secondaryContainer,
          child: Text(
            number,
            style: GoogleFonts.dmSans(
              color: colors.onSecondaryContainer,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            LumiAdaptive.text(title),
            style: GoogleFonts.dmSans(
              fontSize: 21,
              height: 1.3,
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

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
                color: LumiAdaptive.color(
                  blush.withValues(alpha: 0.5),
                  surface: true,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 50,
                color: LumiAdaptive.color(rose),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              LumiAdaptive.text('Đặt lịch thành công'),
              textAlign: TextAlign.center,
              style: LumiAdaptive.style(
                GoogleFonts.cormorantGaramond(
                  color: LumiAdaptive.color(plum),
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: LumiAdaptive.color(
                  const Color(0xFFFFF3CD),
                  surface: true,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: LumiAdaptive.color(const Color(0xFFFFEEBA)),
                ),
              ),
              child: Text(
                LumiAdaptive.text('ĐANG CHỜ LUMI XÁC NHẬN'),
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    color: LumiAdaptive.color(const Color(0xFF856404)),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: LumiAdaptive.color(Colors.white, surface: true),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: LumiAdaptive.color(const Color(0xFFEADFE1)),
                ),
              ),
              child: Column(
                children: [
                  _summaryRow(
                    'Mã lịch hẹn:',
                    '#${booking.id.isNotEmpty ? booking.id.substring(0, booking.id.length > 8 ? 8 : booking.id.length) : "LUMI"}',
                  ),
                  const Divider(height: 20),
                  _summaryRow('Dịch vụ:', booking.serviceName),
                  const Divider(height: 20),
                  _summaryRow(
                    'Thời gian:',
                    '${_dateText(_date)} lúc ${_hour != null ? _hourText(_hour!) : booking.formattedTime}',
                  ),
                  const Divider(height: 20),
                  _summaryRow('Thời lượng:', '$_durationMinutes phút'),
                  const Divider(height: 20),
                  _summaryRow(
                    'Người đặt:',
                    booking.contactName.isNotEmpty
                        ? booking.contactName
                        : _contactNameController.text,
                  ),
                  const Divider(height: 20),
                  _summaryRow(
                    'Số điện thoại:',
                    booking.contactPhone.isNotEmpty
                        ? booking.contactPhone
                        : _contactPhoneController.text,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              LumiAdaptive.text(
                'LUMI đã nhận lịch hẹn của bạn. Chúng tôi sẽ liên hệ xác nhận trong ít phút. Bạn có thể theo dõi trạng thái tại mục Lịch hẹn.',
              ),
              textAlign: TextAlign.center,
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(plum.withValues(alpha: .7)),
                  fontSize: 13,
                  height: 1.5,
                ),
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
                style: LumiAdaptive.style(
                  FilledButton.styleFrom(
                    backgroundColor: LumiAdaptive.color(rose, surface: true),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: Text(
                  LumiAdaptive.text('HOÀN TẤT & VỀ TRANG CHỦ'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                ),
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
        Text(
          LumiAdaptive.text(label),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              color: LumiAdaptive.color(plum.withValues(alpha: 0.6)),
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            LumiAdaptive.text(value),
            textAlign: TextAlign.right,
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                color: LumiAdaptive.color(plum),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
