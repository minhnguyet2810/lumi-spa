import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_crm_repository.dart';
import '../../data/models/customer_360_model.dart';
import '../theme/admin_colors.dart';
import 'admin_customer_moderation_dialog.dart';
import 'admin_loyalty_adjust_dialog.dart';
import 'admin_skin_profile_dialog.dart';

class AdminCustomer360Dialog extends StatefulWidget {
  final String customerId;
  final VoidCallback? onDataChanged;

  const AdminCustomer360Dialog({
    super.key,
    required this.customerId,
    this.onDataChanged,
  });

  @override
  State<AdminCustomer360Dialog> createState() => _AdminCustomer360DialogState();
}

class _AdminCustomer360DialogState extends State<AdminCustomer360Dialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Customer360Profile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final p = await AdminCrmRepository.instance.fetchCustomer360(widget.customerId);
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('StateError: ', '');
        _loading = false;
      });
    }
  }

  CustomerListItem _toListItem(Customer360Profile p) {
    return CustomerListItem(
      id: p.customerId,
      uid: p.customerId,
      displayName: p.displayName,
      email: p.email,
      phone: p.phone,
      photoUrl: p.photoUrl,
      role: p.role,
      status: p.status,
      suspendedReason: p.suspendedReason,
      address: p.address,
      points: p.loyalty.points,
      lifetimeSpent: p.loyalty.lifetimeSpent,
      tier: p.loyalty.tier,
      tierLabel: p.loyalty.tierLabel,
      tierColor: p.loyalty.tierColor,
      skinType: p.skinProfile.skinType,
      knownAllergies: p.skinProfile.knownAllergies,
      contraindications: p.skinProfile.contraindications,
      hasAllergyWarning: p.hasAllergyWarning,
      bookingCount: p.metrics.totalBookings,
      orderCount: p.metrics.totalOrders,
      createdAt: p.createdAt,
      updatedAt: p.updatedAt,
    );
  }

  void _openLoyaltyAdjust() {
    if (_profile == null) return;
    showDialog(
      context: context,
      builder: (_) => AdminLoyaltyAdjustDialog(
        customer: _toListItem(_profile!),
        onAdjusted: () {
          _loadProfile();
          widget.onDataChanged?.call();
        },
      ),
    );
  }

  void _openModeration() {
    if (_profile == null) return;
    showDialog(
      context: context,
      builder: (_) => AdminCustomerModerationDialog(
        customer: _toListItem(_profile!),
        onModerated: () {
          _loadProfile();
          widget.onDataChanged?.call();
        },
      ),
    );
  }

  void _openSkinProfileEdit() {
    if (_profile == null) return;
    showDialog(
      context: context,
      builder: (_) => AdminSkinProfileDialog(
        customerId: _profile!.customerId,
        customerName: _profile!.displayName,
        initialProfile: _profile!.skinProfile,
        onUpdated: () {
          _loadProfile();
          widget.onDataChanged?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminColors.darkTeal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF165B52), width: 1.5),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880, maxHeight: 860),
        child: _loading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AdminColors.gold),
                ),
              )
            : _error != null
                ? _buildErrorView()
                : _buildProfileContent(_profile!),
      ),
    );
  }

  Widget _buildErrorView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE74C3C), size: 48),
          const SizedBox(height: 16),
          Text(
            'Không thể tải hồ sơ khách hàng',
            style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(_error ?? 'Lỗi không xác định', style: GoogleFonts.beVietnamPro(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _loadProfile,
            style: FilledButton.styleFrom(backgroundColor: AdminColors.gold, foregroundColor: Colors.black87),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(Customer360Profile p) {
    final tierColor = p.loyalty.parsedColor;

    return Column(
      children: [
        // Top Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
          decoration: const BoxDecoration(
            color: Color(0xFF08201D),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with Tier Ring
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: tierColor, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: tierColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: AdminColors.slateTeal,
                      backgroundImage: p.photoUrl != null && p.photoUrl!.isNotEmpty
                          ? NetworkImage(p.photoUrl!)
                          : null,
                      child: p.photoUrl == null || p.photoUrl!.isEmpty
                          ? Text(
                              p.initials,
                              style: GoogleFonts.beVietnamPro(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Name, Status, Contacts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                p.displayName,
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Tier Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: tierColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: tierColor, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.workspace_premium_rounded, size: 14, color: tierColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    p.loyalty.tierLabel,
                                    style: GoogleFonts.beVietnamPro(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: tierColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Status Tag
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: p.isActive
                                    ? const Color(0xFF1ABC9C).withValues(alpha: 0.2)
                                    : const Color(0xFFE74C3C).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: p.isActive ? const Color(0xFF1ABC9C) : const Color(0xFFE74C3C),
                                ),
                              ),
                              child: Text(
                                p.isActive ? 'Đang hoạt động' : 'Đang tạm khóa',
                                style: GoogleFonts.beVietnamPro(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: p.isActive ? const Color(0xFF1ABC9C) : const Color(0xFFE74C3C),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 14,
                          children: [
                            if (p.phone.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_rounded, size: 13, color: AdminColors.gold),
                                  const SizedBox(width: 5),
                                  Text(p.phone, style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                            if (p.email.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.email_outlined, size: 13, color: AdminColors.gold),
                                  const SizedBox(width: 5),
                                  Text(p.email, style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white70)),
                                ],
                              ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.tag_rounded, size: 13, color: Colors.white38),
                                const SizedBox(width: 3),
                                Text('ID: ${p.customerId}', style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white38)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quick Action Bar
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _openLoyaltyAdjust,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.gold,
                      side: const BorderSide(color: AdminColors.gold),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.military_tech_rounded, size: 16),
                    label: Text(
                      'Điều chỉnh Điểm & Hạng',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _openSkinProfileEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.healing_rounded, size: 16),
                    label: Text(
                      'Cập nhật Hồ sơ Da',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _openModeration,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.isActive ? const Color(0xFFE74C3C) : const Color(0xFF1ABC9C),
                      side: BorderSide(
                        color: p.isActive ? const Color(0xFFE74C3C) : const Color(0xFF1ABC9C),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(
                      p.isActive ? Icons.lock_person_rounded : Icons.lock_open_rounded,
                      size: 16,
                    ),
                    label: Text(
                      p.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tabs Bar
        Container(
          color: AdminColors.slateTeal,
          child: TabBar(
            controller: _tabController,
            dividerColor: const Color(0xFF1E6B60),
            indicatorColor: AdminColors.gold,
            indicatorWeight: 3,
            labelColor: AdminColors.gold,
            unselectedLabelColor: Colors.white60,
            labelStyle: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w500),
            tabs: [
              Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.healing_rounded, size: 16),
                    const SizedBox(width: 6),
                    const Text('Hồ sơ Da & Trị liệu'),
                    if (p.hasAllergyWarning) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE74C3C),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
              ),
              Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('Lịch hẹn (${p.metrics.totalBookings})'),
                  ],
                ),
              ),
              Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text('Đơn hàng (${p.metrics.totalOrders})'),
                  ],
                ),
              ),
              const Tab(
                icon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.military_tech_rounded, size: 16),
                    SizedBox(width: 6),
                    Text('Thẻ & Loyalty'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSkinAndClinicalTab(p),
              _buildBookingsTab(p),
              _buildOrdersTab(p),
              _buildLoyaltyCardTab(p),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 1: HỒ SƠ DA & BỆNH ÁN LÂM SÀNG
  Widget _buildSkinAndClinicalTab(Customer360Profile p) {
    final skin = p.skinProfile;
    final trList = p.treatmentRecords;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⚠️ CẢNH BÁO DỊ ỨNG & CHỐNG CHỈ ĐỊNH (RED ALERT BOX)
          if (skin.hasAllergies)
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE74C3C), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_rounded, color: Color(0xFFE74C3C), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'CẢNH BÁO DỊ ỨNG & CHỐNG CHỈ ĐỊNH LÂM SÀNG',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFE74C3C),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (skin.knownAllergies.isNotEmpty) ...[
                    Text(
                      'Hoạt chất dị ứng đã ghi nhận:',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skin.knownAllergies.map((a) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE74C3C).withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE74C3C)),
                          ),
                          child: Text(
                            '⚠️ $a',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFAAA6),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (skin.contraindications.isNotEmpty) ...[
                    Text(
                      'Chống chỉ định y tế:',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white70),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: skin.contraindications.map((c) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFF59E0B)),
                          ),
                          child: Text(
                            '⛔ $c',
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFCD34D),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

          // Skin diagnosis cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skin Type Card
              Expanded(
                flex: 4,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.slateTeal,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E6B60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Loại da chẩn đoán', style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white60)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: skin.skinTypeColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              skin.skinTypeLabel,
                              style: GoogleFonts.beVietnamPro(fontSize: 11, fontWeight: FontWeight.w800, color: skin.skinTypeColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Vấn đề da quan tâm:', style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white60)),
                      const SizedBox(height: 6),
                      skin.concerns.isEmpty
                          ? Text('Chưa ghi nhận vấn đề da cụ thể.', style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white38))
                          : Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: skin.concerns.map((c) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(c, style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white70)),
                                );
                              }).toList(),
                            ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Homecare routine card
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AdminColors.slateTeal,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E6B60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quy trình dưỡng da tại nhà (Homecare):', style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white60)),
                      const SizedBox(height: 8),
                      Text(
                        skin.currentRoutine.isNotEmpty
                            ? skin.currentRoutine
                            : 'Chưa có thông tin quy trình dưỡng da tại nhà.',
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 12,
                          color: skin.currentRoutine.isNotEmpty ? Colors.white : Colors.white38,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (skin.lastConsultationAt != null)
                        Text(
                          'Tư vấn gần nhất: ${skin.lastConsultationAt!.day}/${skin.lastConsultationAt!.month}/${skin.lastConsultationAt!.year}',
                          style: GoogleFonts.beVietnamPro(fontSize: 10, color: AdminColors.gold),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lịch sử Bệnh án da liễu qua các buổi trị liệu (Treatment Records)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'BỆNH ÁN DA LIỄU & LỊCH SỬ PHÁC ĐỒ (${trList.length})',
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Tự động ghi nhận từ ca điều trị spa',
                style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white38),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (trList.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AdminColors.slateTeal.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E6B60)),
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.assignment_outlined, size: 36, color: Colors.white30),
                  const SizedBox(height: 10),
                  Text(
                    'Chưa có bệnh án lâm sàng nào được ghi nhận cho khách hàng này.',
                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white60),
                  ),
                ],
              ),
            )
          else
            ...trList.map((tr) => _buildTreatmentRecordCard(tr)),
        ],
      ),
    );
  }

  Widget _buildTreatmentRecordCard(CustomerTreatmentRecord tr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.slateTeal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E6B60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.spa_rounded, color: AdminColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    tr.serviceName,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (tr.createdAt != null)
                Text(
                  '${tr.createdAt!.day}/${tr.createdAt!.month}/${tr.createdAt!.year}',
                  style: GoogleFonts.beVietnamPro(fontSize: 11, color: AdminColors.gold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (tr.skinConditionBefore.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white70),
                  children: [
                    const TextSpan(text: '• Trước điều trị: ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    TextSpan(text: tr.skinConditionBefore),
                  ],
                ),
              ),
            ),
          if (tr.skinReactionAfter.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white70),
                  children: [
                    const TextSpan(text: '• Phản ứng da sau liệu trình: ', style: TextStyle(color: Color(0xFF1ABC9C), fontWeight: FontWeight.w600)),
                    TextSpan(text: tr.skinReactionAfter),
                  ],
                ),
              ),
            ),
          if (tr.homecareRecommendations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white70),
                  children: [
                    const TextSpan(text: '• Hướng dẫn chăm sóc: ', style: TextStyle(color: AdminColors.gold, fontWeight: FontWeight.w600)),
                    TextSpan(text: tr.homecareRecommendations),
                  ],
                ),
              ),
            ),
          if (tr.treatmentStepsApplied.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: tr.treatmentStepsApplied.map((step) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(step, style: GoogleFonts.beVietnamPro(fontSize: 10, color: Colors.white60)),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 2: LỊCH HẸN SPA
  Widget _buildBookingsTab(Customer360Profile p) {
    final bookings = p.recentBookings;

    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy_rounded, size: 48, color: Colors.white30),
              const SizedBox(height: 12),
              Text('Chưa có lịch hẹn spa nào', style: GoogleFonts.beVietnamPro(fontSize: 14, color: Colors.white60)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (context, idx) {
        final b = bookings[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AdminColors.slateTeal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E6B60)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.spa_outlined, color: AdminColors.gold, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.serviceName,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b.startAt != null
                          ? '${b.startAt!.hour.toString().padLeft(2, '0')}:${b.startAt!.minute.toString().padLeft(2, '0')} • ${b.startAt!.day}/${b.startAt!.month}/${b.startAt!.year}'
                          : 'Chưa cập nhật thời gian',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${b.price.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: b.status == 'completed'
                          ? const Color(0xFF1ABC9C).withValues(alpha: 0.2)
                          : b.status == 'cancelled'
                              ? const Color(0xFFE74C3C).withValues(alpha: 0.2)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      b.status == 'completed'
                          ? 'Hoàn tất'
                          : b.status == 'cancelled'
                              ? 'Đã hủy'
                              : 'Chờ duyệt / Sắp tới',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: b.status == 'completed'
                            ? const Color(0xFF1ABC9C)
                            : b.status == 'cancelled'
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: ĐƠN HÀNG MỸ PHẨM
  Widget _buildOrdersTab(Customer360Profile p) {
    final orders = p.recentOrders;

    if (orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.remove_shopping_cart_outlined, size: 48, color: Colors.white30),
              const SizedBox(height: 12),
              Text('Chưa có đơn hàng nào', style: GoogleFonts.beVietnamPro(fontSize: 14, color: Colors.white60)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: orders.length,
      itemBuilder: (context, idx) {
        final o = orders[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AdminColors.slateTeal,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E6B60)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_shipping_outlined, color: AdminColors.gold, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.orderId,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      o.createdAt != null
                          ? '${o.createdAt!.day}/${o.createdAt!.month}/${o.createdAt!.year}'
                          : 'Chưa cập nhật ngày',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${o.total.toInt().toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')} đ',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: o.status == 'completed'
                          ? const Color(0xFF1ABC9C).withValues(alpha: 0.2)
                          : o.status == 'cancelled'
                              ? const Color(0xFFE74C3C).withValues(alpha: 0.2)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      o.status.toUpperCase(),
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: o.status == 'completed'
                            ? const Color(0xFF1ABC9C)
                            : o.status == 'cancelled'
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 4: THẺ HỘI VIÊN & LOYALTY
  Widget _buildLoyaltyCardTab(Customer360Profile p) {
    final loyalty = p.loyalty;
    final tierColor = loyalty.parsedColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Virtual Membership Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF08201D),
                  tierColor.withValues(alpha: 0.4),
                  const Color(0xFF0D3B35),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: tierColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: tierColor.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.spa_rounded, color: AdminColors.gold, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'LUMI SPA CLUB',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tierColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        loyalty.tierLabel.toUpperCase(),
                        style: GoogleFonts.beVietnamPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF08201D),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  p.displayName.toUpperCase(),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                Text(
                  p.phone.isNotEmpty ? p.phone : p.email,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: Colors.white70,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ĐIỂM TÍCH LŨY', style: GoogleFonts.beVietnamPro(fontSize: 10, color: Colors.white60)),
                        const SizedBox(height: 2),
                        Text(
                          '${loyalty.points} pts',
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AdminColors.gold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('TỔNG CHI TIÊU', style: GoogleFonts.beVietnamPro(fontSize: 10, color: Colors.white60)),
                        const SizedBox(height: 2),
                        Text(
                          p.displayLifetimeSpent,
                          style: GoogleFonts.beVietnamPro(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Next Tier Progress Bar
          if (loyalty.nextTierLabel != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminColors.slateTeal,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1E6B60)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tiến độ lên hạng ${loyalty.nextTierLabel}:',
                        style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                      Text(
                        'Cần thêm ${loyalty.pointsToNextTier} điểm',
                        style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w700, color: AdminColors.gold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: loyalty.progress,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(AdminColors.gold),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // Benefits Checklist
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AdminColors.slateTeal,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E6B60)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: AdminColors.gold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ĐẶC QUYỀN HẠNG ${loyalty.tierLabel.toUpperCase()}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (loyalty.benefits.isEmpty)
                  Text('Chưa có cấu hình đặc quyền cho hạng này.', style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white60))
                else
                  ...loyalty.benefits.map((b) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF1ABC9C), size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              b,
                              style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

