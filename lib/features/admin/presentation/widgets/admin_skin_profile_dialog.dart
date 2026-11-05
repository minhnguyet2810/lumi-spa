import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_crm_repository.dart';
import '../../data/models/customer_360_model.dart';
import '../theme/admin_colors.dart';

class AdminSkinProfileDialog extends StatefulWidget {
  final String customerId;
  final String customerName;
  final SkinProfile initialProfile;
  final VoidCallback? onUpdated;

  const AdminSkinProfileDialog({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.initialProfile,
    this.onUpdated,
  });

  @override
  State<AdminSkinProfileDialog> createState() => _AdminSkinProfileDialogState();
}

class _AdminSkinProfileDialogState extends State<AdminSkinProfileDialog> {
  late String _selectedSkinType;
  late List<String> _selectedConcerns;
  late List<String> _selectedAllergies;
  late List<String> _selectedContraindications;
  final _customAllergyController = TextEditingController();
  final _customContraindicationController = TextEditingController();
  final _routineController = TextEditingController();

  bool _submitting = false;
  String? _errorMessage;

  final List<String> _skinTypeKeys = ['normal', 'oily', 'dry', 'combination', 'sensitive'];
  final Map<String, String> _skinTypeLabels = {
    'normal': 'Da Thường',
    'oily': 'Da Dầu',
    'dry': 'Da Khô',
    'combination': 'Da Hỗn Hợp',
    'sensitive': 'Da Nhạy Cảm',
  };

  final List<String> _commonConcerns = [
    'Mụn ẩn / Mụn viêm',
    'Thâm mụn & Nám tàn nhang',
    'Lỗ chân lông to',
    'Lão hóa & Nếp nhăn',
    'Da thiếu nước & Bong tróc',
    'Da không đều màu',
    'Màng bảo vệ da suy yếu',
  ];

  final List<String> _commonAllergies = [
    'Cồn khô (Alcohol Denat)',
    'Hương liệu (Fragrance/Parfum)',
    'Parabens',
    'Retinol / Retinoids',
    'AHA (Glycolic/Lactic)',
    'BHA (Salicylic Acid)',
    'Dầu khoáng (Mineral Oil)',
    'Tinh dầu tràm trà',
  ];

  final List<String> _commonContraindications = [
    'Đang mang thai',
    'Đang cho con bú',
    'Uống Isotretinoin trong 6 tháng',
    'Tiền sử sẹo lồi phì đại',
    'Vết thương hở / Viêm da cơ địa',
    'Vừa peel da hóa học sâu',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSkinType = widget.initialProfile.skinType.toLowerCase();
    if (!_skinTypeKeys.contains(_selectedSkinType)) {
      _selectedSkinType = 'normal';
    }
    _selectedConcerns = List.from(widget.initialProfile.concerns);
    _selectedAllergies = List.from(widget.initialProfile.knownAllergies);
    _selectedContraindications = List.from(widget.initialProfile.contraindications);
    _routineController.text = widget.initialProfile.currentRoutine;
  }

  @override
  void dispose() {
    _customAllergyController.dispose();
    _customContraindicationController.dispose();
    _routineController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      await AdminCrmRepository.instance.updateSkinProfile(
        customerId: widget.customerId,
        skinType: _selectedSkinType,
        concerns: _selectedConcerns,
        knownAllergies: _selectedAllergies,
        contraindications: _selectedContraindications,
        currentRoutine: _routineController.text.trim(),
      );

      if (!mounted) return;
      widget.onUpdated?.call();
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật hồ sơ da liễu & hoạt chất dị ứng thành công!'),
          backgroundColor: Color(0xFF1ABC9C),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('StateError: ', '');
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AdminColors.border, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 780),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.healing_rounded,
                      color: Color(0xFF38BDF8),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HỒ SƠ DA LIỄU LÂM SÀNG & DỊ ỨNG',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.textPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          widget.customerName,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: AdminColors.gold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AdminColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AdminColors.border, height: 1),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Phân loại loại da
                      Text(
                        '1. Phân loại loại da lâm sàng',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _skinTypeKeys.map((k) {
                          final isSelected = _selectedSkinType == k;
                          return ChoiceChip(
                            label: Text(_skinTypeLabels[k] ?? k),
                            selected: isSelected,
                            onSelected: (val) {
                              if (val) setState(() => _selectedSkinType = k);
                            },
                            selectedColor: AdminColors.gold.withValues(alpha: 0.25),
                            backgroundColor: AdminColors.sidebarBackground,
                            labelStyle: GoogleFonts.beVietnamPro(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AdminColors.gold : AdminColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected ? AdminColors.gold : AdminColors.border,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // 2. Vấn đề da cần cải thiện
                      Text(
                        '2. Vấn đề da & Nhu cầu điều trị',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _commonConcerns.map((concern) {
                          final isSelected = _selectedConcerns.contains(concern);
                          return FilterChip(
                            label: Text(concern),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedConcerns.add(concern);
                                } else {
                                  _selectedConcerns.remove(concern);
                                }
                              });
                            },
                            selectedColor: const Color(0xFF0284C7).withValues(alpha: 0.3),
                            backgroundColor: AdminColors.sidebarBackground,
                            labelStyle: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: isSelected ? const Color(0xFF38BDF8) : AdminColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF38BDF8) : AdminColors.border,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // 3. ⚠️ Hoạt chất dị ứng (RED ALERT)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: Color(0xFFE74C3C), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  '3. Hoạt chất & Thành phần gây Dị ứng / Kích ứng',
                                  style: GoogleFonts.beVietnamPro(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFE74C3C),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'KTV & Lễ tân sẽ nhận được cảnh báo đỏ trên hồ sơ điều trị để tránh sử dụng mỹ phẩm chứa các hoạt chất này.',
                              style: GoogleFonts.beVietnamPro(
                                fontSize: 11,
                                color: AdminColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _commonAllergies.map((allergy) {
                                final isSelected = _selectedAllergies.contains(allergy);
                                return FilterChip(
                                  label: Text(allergy),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    setState(() {
                                      if (val) {
                                        _selectedAllergies.add(allergy);
                                      } else {
                                        _selectedAllergies.remove(allergy);
                                      }
                                    });
                                  },
                                  selectedColor: const Color(0xFFE74C3C).withValues(alpha: 0.35),
                                  backgroundColor: AdminColors.sidebarBackground,
                                  labelStyle: GoogleFonts.beVietnamPro(
                                    fontSize: 11,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFFFFAAA6) : AdminColors.textSecondary,
                                  ),
                                  side: BorderSide(
                                    color: isSelected ? const Color(0xFFE74C3C) : AdminColors.border,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customAllergyController,
                                    style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 12),
                                    decoration: InputDecoration(
                                      hintText: 'Thêm hoạt chất dị ứng khác...',
                                      hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontSize: 12),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      filled: true,
                                      fillColor: AdminColors.sidebarBackground,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: const BorderSide(color: AdminColors.border),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () {
                                    final text = _customAllergyController.text.trim();
                                    if (text.isNotEmpty && !_selectedAllergies.contains(text)) {
                                      setState(() {
                                        _selectedAllergies.add(text);
                                        _customAllergyController.clear();
                                      });
                                    }
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFFE74C3C),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  ),
                                  child: const Text('Thêm'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // 4. Chống chỉ định lâm sàng
                      Text(
                        '4. Chống chỉ định đặc biệt',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _commonContraindications.map((c) {
                          final isSelected = _selectedContraindications.contains(c);
                          return FilterChip(
                            label: Text(c),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedContraindications.add(c);
                                } else {
                                  _selectedContraindications.remove(c);
                                }
                              });
                            },
                            selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                            backgroundColor: AdminColors.sidebarBackground,
                            labelStyle: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              color: isSelected ? const Color(0xFFFCD34D) : AdminColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFFF59E0B) : AdminColors.border,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // 5. Quy trình dưỡng da tại nhà hiện tại (Homecare Routine)
                      Text(
                        '5. Quy trình dưỡng da tại nhà hiện tại (Homecare)',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AdminColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _routineController,
                        maxLines: 3,
                        style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'VD: Sáng: Sữa rửa mặt dịu nhẹ, Serum B5, Kem chống nắng SPF 50. Tối: Tẩy trang, Nước hoa hồng không cồn...',
                          hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted),
                          filled: true,
                          fillColor: AdminColors.slateTeal,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AdminColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AdminColors.border),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE74C3C)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFE74C3C), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.beVietnamPro(fontSize: 12, color: const Color(0xFFE74C3C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(color: AdminColors.border, height: 1),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      'HỦY',
                      style: GoogleFonts.beVietnamPro(color: AdminColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _handleSubmit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AdminColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(
                      _submitting ? 'ĐANG LƯU...' : 'LƯU HỒ SƠ DA LIỄU',
                      style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

