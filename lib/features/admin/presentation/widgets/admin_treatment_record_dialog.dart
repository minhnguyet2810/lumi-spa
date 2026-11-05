import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../booking/data/models/booking_item.dart';
import '../theme/admin_colors.dart';

class AdminTreatmentRecordDialog extends StatefulWidget {
  final BookingItem booking;

  const AdminTreatmentRecordDialog({super.key, required this.booking});

  @override
  State<AdminTreatmentRecordDialog> createState() => _AdminTreatmentRecordDialogState();
}

class _AdminTreatmentRecordDialogState extends State<AdminTreatmentRecordDialog> {
  final _conditionBeforeController = TextEditingController(text: 'Da khô thiếu nước, vùng chữ T bóng dầu nhẹ, không có vết thương hở.');
  final _reactionAfterController = TextEditingController(text: 'Làn da căng bóng ngậm nước, bề mặt da mềm mịn, không ửng đỏ hay kích ứng.');
  final _homecareController = TextEditingController(text: 'Thoa Serum B5 cấp ẩm sáng & tối, uống đủ 2L nước, thoa kem chống nắng SPF 50+ trước khi ra ngoài.');

  final List<String> _availableSteps = [
    'Tẩy trang & Rửa mặt sạch sâu',
    'Tẩy tế bào chết sinh học Enzyme',
    'Xông hơi thải độc & Hút dầu mụn cám',
    'Cân bằng độ ẩm với Toner hoa hồng',
    'Massage bấm huyệt lưu thông khí huyết',
    'Điện di tinh chất tế bào gốc / HA đa tầng',
    'Đắp mặt nạ Collagen sinh học thủy phân',
    'Chiếu ánh sáng sinh học Bio-Light phục hồi',
    'Khóa ẩm với kem dưỡng tế bào gốc & Chống nắng',
  ];

  final Set<String> _selectedSteps = {
    'Tẩy trang & Rửa mặt sạch sâu',
    'Xông hơi thải độc & Hút dầu mụn cám',
    'Massage bấm huyệt lưu thông khí huyết',
    'Điện di tinh chất tế bào gốc / HA đa tầng',
    'Đắp mặt nạ Collagen sinh học thủy phân',
    'Khóa ẩm với kem dưỡng tế bào gốc & Chống nắng',
  };

  @override
  void dispose() {
    _conditionBeforeController.dispose();
    _reactionAfterController.dispose();
    _homecareController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_outlined,
                    color: AdminColors.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hồ Sơ Trị Liệu & Bệnh Án Da',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Khách hàng: ${widget.booking.contactName} • ${widget.booking.serviceName}',
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
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tình trạng da trước trị liệu (Intake Assessment)',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.softGold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _conditionBeforeController,
                      style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AdminColors.deepTeal,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Các bước phác đồ đã thực hiện',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.softGold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _availableSteps.map((step) {
                        final isSelected = _selectedSteps.contains(step);
                        return FilterChip(
                          label: Text(
                            step,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: isSelected ? Colors.white : AdminColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AdminColors.emerald.withValues(alpha: 0.8),
                          backgroundColor: AdminColors.deepTeal,
                          checkmarkColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? AdminColors.emerald : AdminColors.border,
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSteps.add(step);
                              } else {
                                _selectedSteps.remove(step);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Phản ứng da sau liệu trình',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.softGold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _reactionAfterController,
                      style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AdminColors.deepTeal,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminColors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lời khuyên chăm sóc tại nhà & Mỹ phẩm gợi ý',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AdminColors.softGold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _homecareController,
                      style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
                      maxLines: 2,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AdminColors.deepTeal,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdminColors.border),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'ĐÓNG',
                    style: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop({
                      'skinConditionBefore': _conditionBeforeController.text.trim(),
                      'treatmentStepsApplied': _selectedSteps.toList(),
                      'skinReactionAfter': _reactionAfterController.text.trim(),
                      'homecareRecommendations': _homecareController.text.trim(),
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.cyan,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: Text(
                    'LƯU HỒ SƠ BỆNH ÁN',
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
