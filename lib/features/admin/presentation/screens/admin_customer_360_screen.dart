import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/admin_crm_repository.dart';
import '../../data/models/customer_360_model.dart';
import '../theme/admin_colors.dart';
import '../widgets/admin_customer_360_dialog.dart';
import '../widgets/admin_customer_moderation_dialog.dart';
import '../widgets/admin_loyalty_adjust_dialog.dart';
import '../widgets/admin_skin_profile_dialog.dart';

class AdminCustomer360Screen extends StatefulWidget {
  const AdminCustomer360Screen({super.key});

  @override
  State<AdminCustomer360Screen> createState() => _AdminCustomer360ScreenState();
}

class _AdminCustomer360ScreenState extends State<AdminCustomer360Screen> {
  final _searchController = TextEditingController();
  String _selectedTier = 'all'; // all, bronze, silver, gold, diamond
  String _selectedStatus = 'all'; // all, active, suspended
  final String _selectedSort = 'spent_desc';

  CustomerKpiStats _stats = const CustomerKpiStats();
  List<CustomerListItem> _customers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await AdminCrmRepository.instance.fetchCustomersWithMetrics(
        query: _searchController.text,
        tier: _selectedTier,
        status: _selectedStatus,
        sortBy: _selectedSort,
        limit: 100,
      );

      if (!mounted) return;
      setState(() {
        _stats = res.stats;
        _customers = res.customers;
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

  void _open360Dialog(CustomerListItem c) {
    showDialog(
      context: context,
      builder: (_) => AdminCustomer360Dialog(
        customerId: c.id,
        onDataChanged: _fetchData,
      ),
    );
  }

  void _openLoyaltyAdjust(CustomerListItem c) {
    showDialog(
      context: context,
      builder: (_) => AdminLoyaltyAdjustDialog(
        customer: c,
        onAdjusted: _fetchData,
      ),
    );
  }

  void _openModeration(CustomerListItem c) {
    showDialog(
      context: context,
      builder: (_) => AdminCustomerModerationDialog(
        customer: c,
        onModerated: _fetchData,
      ),
    );
  }

  void _openSkinProfileEdit(CustomerListItem c) {
    showDialog(
      context: context,
      builder: (_) => AdminSkinProfileDialog(
        customerId: c.id,
        customerName: c.displayName,
        initialProfile: SkinProfile(
          skinType: c.skinType,
          knownAllergies: c.knownAllergies,
          contraindications: c.contraindications,
        ),
        onUpdated: _fetchData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF08201D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF08201D),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AdminColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminColors.gold.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.people_alt_rounded, color: AdminColors.gold, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HỒ SƠ KHÁCH HÀNG 360° & HỘI VIÊN',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Quản trị thông tin khách hàng, hồ sơ da liễu chuyên sâu & điểm thưởng hội viên',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 10,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            icon: const Icon(Icons.refresh_rounded, color: AdminColors.gold),
            onPressed: _fetchData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            children: [
              // 1. KPI Metrics Overview Bar
              _buildKpiMetricsBar(),

              // 2. Filters & Search Toolbar
              _buildFilterToolbar(),

              // 3. Customer Cards Grid / List
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: AdminColors.gold),
                      )
                    : _error != null
                        ? _buildErrorView()
                        : _buildCustomerList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiMetricsBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.darkTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF165B52)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 750;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            children: [
              _kpiCard(
                title: 'Tổng Khách Hàng',
                value: '${_stats.totalCustomers}',
                subtitle: '${_stats.activeCustomers} đang hoạt động',
                icon: Icons.groups_rounded,
                color: const Color(0xFF38BDF8),
                width: isCompact ? constraints.maxWidth / 2 - 12 : 180,
              ),
              _kpiCard(
                title: 'Hội Viên VIP',
                value: '${_stats.vipCustomers}',
                subtitle: 'Hạng Vàng & Kim Cương',
                icon: Icons.workspace_premium_rounded,
                color: AdminColors.gold,
                width: isCompact ? constraints.maxWidth / 2 - 12 : 180,
              ),
              _kpiCard(
                title: 'Chi Tiêu Trung Bình',
                value: _stats.displayAverageSpend,
                subtitle: 'ARPU / Khách hàng',
                icon: Icons.monetization_on_rounded,
                color: const Color(0xFF1ABC9C),
                width: isCompact ? constraints.maxWidth / 2 - 12 : 210,
              ),
              _kpiCard(
                title: 'Tài Khoản Tạm Khóa',
                value: '${_stats.suspendedCustomers}',
                subtitle: 'Cần kiểm tra can thiệp',
                icon: Icons.lock_clock_rounded,
                color: const Color(0xFFE74C3C),
                width: isCompact ? constraints.maxWidth / 2 - 12 : 180,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.slateTeal,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E6B60)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.beVietnamPro(fontSize: 10, color: Colors.white60),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.beVietnamPro(fontSize: 9, color: color),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToolbar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.darkTeal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF165B52)),
      ),
      child: Column(
        children: [
          // Row 1: Search + Sort
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.beVietnamPro(color: Colors.white, fontSize: 13),
                  onSubmitted: (_) => _fetchData(),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên khách, số điện thoại, email hoặc mã UID...',
                    hintStyle: GoogleFonts.beVietnamPro(color: Colors.white38, fontSize: 13),
                    isDense: true,
                    filled: true,
                    fillColor: AdminColors.slateTeal,
                    prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.gold, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white54, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchData();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E6B60)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF1E6B60)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AdminColors.gold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _fetchData,
                style: FilledButton.styleFrom(
                  backgroundColor: AdminColors.gold,
                  foregroundColor: const Color(0xFF08201D),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  'LỌC',
                  style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Tier Chips + Status Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text('Hạng: ', style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white60)),
                _filterChip('all', 'Tất cả (${_stats.totalCustomers})', isTier: true),
                _filterChip('bronze', 'Đồng (${_stats.tierBreakdown['bronze'] ?? 0})', isTier: true, color: const Color(0xFFC5A880)),
                _filterChip('silver', 'Bạc (${_stats.tierBreakdown['silver'] ?? 0})', isTier: true, color: const Color(0xFF94A3B8)),
                _filterChip('gold', 'Vàng (${_stats.tierBreakdown['gold'] ?? 0})', isTier: true, color: const Color(0xFFF59E0B)),
                _filterChip('diamond', 'Kim Cương (${_stats.tierBreakdown['diamond'] ?? 0})', isTier: true, color: const Color(0xFF38BDF8)),
                const SizedBox(width: 16),
                const SizedBox(height: 20, child: VerticalDivider(color: Colors.white24)),
                const SizedBox(width: 16),
                Text('Trạng thái: ', style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white60)),
                _filterChip('all', 'Tất cả', isTier: false),
                _filterChip('active', 'Hoạt động', isTier: false, color: const Color(0xFF1ABC9C)),
                _filterChip('suspended', 'Tạm khóa', isTier: false, color: const Color(0xFFE74C3C)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label, {required bool isTier, Color? color}) {
    final isSelected = isTier ? _selectedTier == key : _selectedStatus == key;
    final chipColor = color ?? AdminColors.gold;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() {
              if (isTier) {
                _selectedTier = key;
              } else {
                _selectedStatus = key;
              }
            });
            _fetchData();
          }
        },
        selectedColor: chipColor.withValues(alpha: 0.25),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        labelStyle: GoogleFonts.beVietnamPro(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? chipColor : Colors.white70,
        ),
        side: BorderSide(
          color: isSelected ? chipColor : Colors.white12,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildCustomerList() {
    if (_customers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.person_search_rounded, size: 54, color: Colors.white30),
              const SizedBox(height: 14),
              Text(
                'Không tìm thấy khách hàng nào phù hợp với bộ lọc.',
                style: GoogleFonts.beVietnamPro(fontSize: 14, color: Colors.white60),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1050
            ? 3
            : constraints.maxWidth > 700
                ? 2
                : 1;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: crossAxisCount == 1 ? 2.4 : 1.6,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemCount: _customers.length,
          itemBuilder: (context, idx) => _buildCustomerCard(_customers[idx]),
        );
      },
    );
  }

  Widget _buildCustomerCard(CustomerListItem c) {
    final tierColor = c.parsedTierColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.darkTeal,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: c.isSuspended
              ? const Color(0xFFE74C3C).withValues(alpha: 0.6)
              : c.hasAllergyWarning
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                  : const Color(0xFF165B52),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Avatar + Info + Badges
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tierColor, width: 2),
                ),
                child: CircleAvatar(
                  backgroundColor: AdminColors.slateTeal,
                  backgroundImage: c.photoUrl != null && c.photoUrl!.isNotEmpty
                      ? NetworkImage(c.photoUrl!)
                      : null,
                  child: c.photoUrl == null || c.photoUrl!.isEmpty
                      ? Text(
                          c.initials,
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Names & Phone
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            c.displayName,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (c.isSuspended) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE74C3C),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('KHÓA', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      c.phone.isNotEmpty ? c.phone : (c.email.isNotEmpty ? c.email : 'Chưa có SĐT'),
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: Colors.white60),
                    ),
                    const SizedBox(height: 4),
                    // Tier badge + Skin badge
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tierColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: tierColor, width: 0.8),
                          ),
                          child: Text(
                            c.tierLabel,
                            style: GoogleFonts.beVietnamPro(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: tierColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.skinType.toUpperCase(),
                            style: GoogleFonts.beVietnamPro(fontSize: 9, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Allergy Warning tag if present
          if (c.hasAllergyWarning)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFE74C3C)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dị ứng: ${c.knownAllergies.isNotEmpty ? c.knownAllergies.join(", ") : c.contraindications.join(", ")}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFAAA6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Points & Spent Metrics Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AdminColors.slateTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech_rounded, size: 14, color: AdminColors.gold),
                    const SizedBox(width: 4),
                    Text(
                      '${c.points} pts',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AdminColors.gold,
                      ),
                    ),
                  ],
                ),
                Text(
                  c.displayLifetimeSpent,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons Bar
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _open360Dialog(c),
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.gold,
                    foregroundColor: const Color(0xFF08201D),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.visibility_rounded, size: 14),
                  label: Text(
                    'HỒ SƠ 360°',
                    style: GoogleFonts.beVietnamPro(fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Điều chỉnh Điểm & Hạng',
                icon: const Icon(Icons.military_tech_rounded, color: AdminColors.gold, size: 18),
                onPressed: () => _openLoyaltyAdjust(c),
                style: IconButton.styleFrom(
                  backgroundColor: AdminColors.slateTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Hồ sơ Da Liễu',
                icon: const Icon(Icons.healing_rounded, color: Color(0xFF38BDF8), size: 18),
                onPressed: () => _openSkinProfileEdit(c),
                style: IconButton.styleFrom(
                  backgroundColor: AdminColors.slateTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: c.isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                icon: Icon(
                  c.isActive ? Icons.lock_person_rounded : Icons.lock_open_rounded,
                  color: c.isActive ? const Color(0xFFE74C3C) : const Color(0xFF1ABC9C),
                  size: 18,
                ),
                onPressed: () => _openModeration(c),
                style: IconButton.styleFrom(
                  backgroundColor: AdminColors.slateTeal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFE74C3C)),
            const SizedBox(height: 14),
            Text(
              'Không thể tải dữ liệu CRM',
              style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(_error ?? 'Lỗi kết nối', style: GoogleFonts.beVietnamPro(fontSize: 12, color: Colors.white60)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _fetchData,
              style: FilledButton.styleFrom(backgroundColor: AdminColors.gold, foregroundColor: Colors.black87),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

