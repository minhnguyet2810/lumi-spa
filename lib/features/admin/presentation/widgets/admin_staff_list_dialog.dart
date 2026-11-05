import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_hrm_repository.dart';
import '../../data/models/admin_staff_shift_model.dart';
import '../theme/admin_colors.dart';

class AdminStaffListDialog extends StatefulWidget {
  final List<StaffMemberItem> initialStaff;
  final VoidCallback? onStaffUpdated;

  const AdminStaffListDialog({
    super.key,
    required this.initialStaff,
    this.onStaffUpdated,
  });

  @override
  State<AdminStaffListDialog> createState() => _AdminStaffListDialogState();
}

class _AdminStaffListDialogState extends State<AdminStaffListDialog> {
  late List<StaffMemberItem> _staff;
  bool _showAddForm = false;
  bool _submitting = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  String _selectedRole = 'specialist';
  final List<String> _selectedCategories = ['facial'];

  final List<String> _categoryOptions = ['facial', 'body', 'relaxation', 'beauty'];
  final Map<String, String> _categoryLabels = {
    'facial': 'Chăm sóc da mặt',
    'body': 'Trị liệu toàn thân',
    'relaxation': 'Dưỡng sinh thư giãn',
    'beauty': 'Thẩm mỹ công nghệ cao',
  };

  @override
  void initState() {
    super.initState();
    _staff = List.from(widget.initialStaff);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveStaff() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMessage = 'Vui lòng nhập tên nhân viên.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final newMember = await AdminHrmRepository.instance.saveStaffMember(
        name: name,
        role: _selectedRole,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        categories: _selectedCategories,
        isActive: true,
      );

      if (!mounted) return;
      setState(() {
        _staff.add(newMember);
        _showAddForm = false;
        _nameController.clear();
        _phoneController.clear();
        _emailController.clear();
        _submitting = false;
      });

      widget.onStaffUpdated?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm nhân viên ${newMember.name} thành công!'),
          backgroundColor: const Color(0xFF1ABC9C),
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
      backgroundColor: AdminColors.deepTeal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF165B52), width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
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
                      color: AdminColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.badge_rounded,
                      color: AdminColors.gold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DANH SÁCH NHÂN SỰ & CHUYÊN MÔN',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          'Kỹ thuật viên, Lễ tân & Quản lý cơ sở',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFF1E6B60), height: 1),
              const SizedBox(height: 16),

              // Toggle Add form button
              if (!_showAddForm)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tổng cộng: ${_staff.length} nhân sự',
                      style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.gold),
                    ),
                    FilledButton.icon(
                      onPressed: () => setState(() => _showAddForm = true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AdminColors.gold,
                        foregroundColor: const Color(0xFF08201D),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 16),
                      label: Text('Thêm nhân viên mới', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w800, fontSize: 11)),
                    ),
                  ],
                ),

              // Add form view
              if (_showAddForm) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.slateTeal,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.gold.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Thêm nhân sự mới:', style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w800, color: AdminColors.gold)),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                            onPressed: () => setState(() => _showAddForm = false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Họ và tên nhân viên...',
                          hintStyle: GoogleFonts.beVietnamPro(color: Colors.white38),
                          isDense: true,
                          filled: true,
                          fillColor: AdminColors.deepTeal,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Số điện thoại...',
                                hintStyle: GoogleFonts.beVietnamPro(color: Colors.white38),
                                isDense: true,
                                filled: true,
                                fillColor: AdminColors.deepTeal,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AdminColors.deepTeal,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRole,
                                  isExpanded: true,
                                  dropdownColor: AdminColors.deepTeal,
                                  style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 12),
                                  items: const [
                                    DropdownMenuItem(value: 'specialist', child: Text('Kỹ thuật viên')),
                                    DropdownMenuItem(value: 'receptionist', child: Text('Lễ tân')),
                                    DropdownMenuItem(value: 'branch_manager', child: Text('Quản lý cơ sở')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedRole = val);
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text('Chuyên môn thực hiện liệu trình:', style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white70)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _categoryOptions.map((cat) {
                          final isSelected = _selectedCategories.contains(cat);
                          return FilterChip(
                            label: Text(_categoryLabels[cat] ?? cat),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  _selectedCategories.add(cat);
                                } else if (_selectedCategories.length > 1) {
                                  _selectedCategories.remove(cat);
                                }
                              });
                            },
                            selectedColor: AdminColors.gold.withValues(alpha: 0.25),
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            labelStyle: GoogleFonts.beVietnamPro(
                              fontSize: 10,
                              color: isSelected ? AdminColors.gold : Colors.white70,
                            ),
                            side: BorderSide(color: isSelected ? AdminColors.gold : Colors.white12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          );
                        }).toList(),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(_errorMessage!, style: GoogleFonts.beVietnamPro(fontSize: 11, color: const Color(0xFFE74C3C))),
                      ],
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: _submitting ? null : _handleSaveStaff,
                          style: FilledButton.styleFrom(backgroundColor: AdminColors.gold, foregroundColor: Colors.black87),
                          child: Text(_submitting ? 'ĐANG LƯU...' : 'LƯU NHÂN SỰ'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Staff List view
              Expanded(
                child: ListView.builder(
                  itemCount: _staff.length,
                  itemBuilder: (context, idx) {
                    final s = _staff[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AdminColors.slateTeal,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1E6B60)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: s.roleColor.withValues(alpha: 0.2),
                            child: Text(s.initials, style: TextStyle(color: s.roleColor, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(s.name, style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: s.roleColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: s.roleColor, width: 0.8),
                                      ),
                                      child: Text(s.roleLabel, style: GoogleFonts.beVietnamPro(fontSize: 9, fontWeight: FontWeight.w700, color: s.roleColor)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Chuyên môn: ${s.displayCategories}',
                                  style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white60),
                                ),
                                if (s.phone.isNotEmpty)
                                  Text(
                                    'SĐT: ${s.phone}',
                                    style: GoogleFonts.beVietnamPro(fontSize: 10, color: AdminColors.gold),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: s.isActive ? const Color(0xFF1ABC9C).withValues(alpha: 0.2) : Colors.white12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              s.isActive ? 'Đang làm việc' : 'Tạm ngưng',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: s.isActive ? const Color(0xFF1ABC9C) : Colors.white60,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
