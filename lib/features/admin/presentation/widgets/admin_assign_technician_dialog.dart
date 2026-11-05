import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../booking/data/models/booking_item.dart';
import '../theme/admin_colors.dart';

class AdminAssignTechnicianDialog extends StatefulWidget {
  final BookingItem booking;

  const AdminAssignTechnicianDialog({super.key, required this.booking});

  @override
  State<AdminAssignTechnicianDialog> createState() => _AdminAssignTechnicianDialogState();
}

class _AdminAssignTechnicianDialogState extends State<AdminAssignTechnicianDialog> {
  String? _selectedStaffId;
  String? _selectedRoomId;
  final _noteController = TextEditingController();

  // Danh sách KTV chuẩn bị mẫu (nếu database chưa seed đủ)
  final List<Map<String, String>> _mockStaff = [
    {'id': 'staff_01', 'name': 'KTV. Nguyễn Thảo (Chuyên viên Facial & Cấp ẩm)'},
    {'id': 'staff_02', 'name': 'KTV. Lê Ngọc Mai (Chuyên viên Massage Đá Nóng)'},
    {'id': 'staff_03', 'name': 'KTV. Trần Minh Anh (Kỹ thuật viên Trị liệu da)'},
    {'id': 'staff_04', 'name': 'KTV. Hoàng Bích (Chuyên viên Gội đầu dưỡng sinh)'},
  ];

  final List<Map<String, String>> _mockRooms = [
    {'id': 'room_01', 'name': 'Phòng Trị Liệu Sen Trắng (Giường 01 - 02)'},
    {'id': 'room_02', 'name': 'Phòng VIP Hoàng Lan (Giường Đơn Riêng Tư)'},
    {'id': 'room_03', 'name': 'Phòng Massage Đá Bazan Himalaya'},
    {'id': 'room_04', 'name': 'Phòng Dưỡng Sinh & Gội Đầu Thảo Mộc'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedStaffId = _mockStaff.first['id'];
    _selectedRoomId = _mockRooms.first['id'];
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AdminColors.border),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminColors.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_available_rounded,
                    color: AdminColors.goldAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duyệt Lịch & Phân Công Nhân Sự',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Khách: ${widget.booking.contactName} • ${widget.booking.serviceName}',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AdminColors.deepTeal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 18, color: AdminColors.softGold),
                  const SizedBox(width: 8),
                  Text(
                    'Thời gian: ${widget.booking.formattedStartAt} (${widget.booking.durationMinutes} phút)',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chỉ định Kỹ thuật viên (Technician)',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AdminColors.deepTeal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStaffId,
                  isExpanded: true,
                  dropdownColor: AdminColors.cardSurface,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AdminColors.textSecondary),
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textPrimary),
                  items: _mockStaff.map((s) => DropdownMenuItem(value: s['id'], child: Text(s['name']!))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStaffId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Chỉ định Phòng trị liệu (Treatment Room)',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AdminColors.deepTeal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AdminColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedRoomId,
                  isExpanded: true,
                  dropdownColor: AdminColors.cardSurface,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AdminColors.textSecondary),
                  style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textPrimary),
                  items: _mockRooms.map((r) => DropdownMenuItem(value: r['id'], child: Text(r['name']!))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRoomId = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ghi chú chuẩn bị phòng / lưu ý đặc biệt',
              style: GoogleFonts.beVietnamPro(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AdminColors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _noteController,
              style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Chuẩn bị tinh dầu sả chanh, khăn ấm, nhạc thư giãn...',
                hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AdminColors.deepTeal,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdminColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdminColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AdminColors.goldAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'HỦY',
                    style: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'technicianId': _selectedStaffId,
                      'roomId': _selectedRoomId,
                      'note': _noteController.text.trim(),
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.emerald,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: Text(
                    'XÁC NHẬN DUYỆT & KHÓA LỊCH',
                    style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
