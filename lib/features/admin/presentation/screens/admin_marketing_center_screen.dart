import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../theme/admin_colors.dart';
import '../../data/models/admin_voucher_model.dart';
import '../../data/admin_marketing_repository.dart';
import '../widgets/admin_voucher_form_dialog.dart';
import '../widgets/admin_broadcast_push_dialog.dart';

class AdminMarketingCenterScreen extends StatefulWidget {
  const AdminMarketingCenterScreen({super.key});

  @override
  State<AdminMarketingCenterScreen> createState() => _AdminMarketingCenterScreenState();
}

class _AdminMarketingCenterScreenState extends State<AdminMarketingCenterScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedStatus = 'all'; // 'all', 'active', 'expired', 'exhausted', 'disabled'

  List<AdminVoucherItem> _vouchers = [];
  AdminMarketingKpi _kpi = const AdminMarketingKpi();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final vouchers = await AdminMarketingRepository.instance.fetchVouchers(
        status: _selectedStatus,
        search: _searchCtrl.text.trim(),
      );
      final kpi = await AdminMarketingRepository.instance.fetchMarketingKpis();
      if (mounted) {
        setState(() {
          _vouchers = vouchers;
          _kpi = kpi;
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onToggleStatus(AdminVoucherItem v, bool val) async {
    final success = await AdminMarketingRepository.instance.toggleVoucherStatus(v.code, val);
    if (success && mounted) {
      _loadData();
    }
  }

  Future<void> _onDeleteVoucher(AdminVoucherItem v) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.deepTeal,
        title: Text(
          'Xác nhận xóa Voucher',
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa hoặc hủy kích hoạt mã [${v.code}] không?',
          style: GoogleFonts.beVietnamPro(color: AdminColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Hủy', style: GoogleFonts.beVietnamPro(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.statusCancelled),
            child: Text('Xác nhận xóa', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminMarketingRepository.instance.deleteVoucher(v.code);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa mã [${v.code}] thành công.'), backgroundColor: AdminColors.emerald),
        );
        _loadData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.deepTeal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AdminColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AdminColors.goldAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.loyalty_rounded, color: AdminColors.goldAccent, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Cấu Hình Voucher & Chiến Dịch Marketing',
              style: GoogleFonts.beVietnamPro(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AdminColors.goldAccent),
            tooltip: 'Tải lại',
            onPressed: _loadData,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AdminColors.goldAccent,
        backgroundColor: AdminColors.deepTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 4 Thẻ KPI Marketing
              _buildKpiSection(),
              const SizedBox(height: 24),

              // Thanh điều khiển & nút tác vụ
              _buildControlBar(),
              const SizedBox(height: 20),

              // Danh sách Voucher Cards
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(color: AdminColors.goldAccent),
                  ),
                )
              else if (_vouchers.isEmpty)
                _buildEmptyState()
              else
                _buildVoucherGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiSection() {
    final currencyFmt = NumberFormat('#,###', 'vi_VN');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Tổng Mã Voucher',
                value: '${_kpi.totalVouchers}',
                subtitle: '${_kpi.activeVouchers} mã đang hoạt động',
                icon: Icons.confirmation_number_rounded,
                accentColor: AdminColors.goldAccent,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Lượt Khách Đã Áp Dụng',
                value: '${_kpi.totalUses}',
                subtitle: 'Lượt đổi thành công trên đơn hàng',
                icon: Icons.shopping_bag_outlined,
                accentColor: AdminColors.emerald,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Ngân Sách Đã Tài Trợ',
                value: '${currencyFmt.format(_kpi.totalDiscountSponsored)}đ',
                subtitle: 'Tổng chiết khấu tích lũy toàn hệ thống',
                icon: Icons.account_balance_wallet_rounded,
                accentColor: const Color(0xFFE67E22),
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                title: 'Chiến Dịch Push Đã Gửi',
                value: '${_kpi.totalCampaigns}',
                subtitle: '${_kpi.totalPushSent} thông báo phân khúc gửi đi',
                icon: Icons.campaign_rounded,
                accentColor: AdminColors.cyan,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AdminColors.textSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.beVietnamPro(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AdminColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.beVietnamPro(
              fontSize: 11,
              color: AdminColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Search & Action Buttons
          Row(
            children: [
              // Search Field
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (_) => _loadData(),
                  style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo mã voucher, tiêu đề khuyến mãi...',
                    hintStyle: GoogleFonts.beVietnamPro(color: AdminColors.textMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AdminColors.goldAccent, size: 20),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AdminColors.textMuted, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _loadData();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AdminColors.deepTeal,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AdminColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AdminColors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Button Bắn Push Chiến Dịch
              OutlinedButton.icon(
                onPressed: () async {
                  final sent = await AdminBroadcastPushDialog.show(
                    context,
                    availableVouchers: _vouchers.where((v) => v.isActive).toList(),
                  );
                  if (sent == true) _loadData();
                },
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text('Bắn Chiến Dịch Push', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AdminColors.cyan,
                  side: const BorderSide(color: AdminColors.cyan),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),

              // Button Tạo Voucher Mới
              ElevatedButton.icon(
                onPressed: () async {
                  final created = await AdminVoucherFormDialog.show(context);
                  if (created == true) _loadData();
                },
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text('Tạo Voucher Mới', style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.goldAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'Tất cả (${_vouchers.length})'),
                const SizedBox(width: 8),
                _buildFilterChip('active', 'Đang áp dụng'),
                const SizedBox(width: 8),
                _buildFilterChip('expired', 'Đã hết hạn'),
                const SizedBox(width: 8),
                _buildFilterChip('exhausted', 'Đã hết lượt'),
                const SizedBox(width: 8),
                _buildFilterChip('disabled', 'Tạm dừng'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.beVietnamPro(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.black : AdminColors.textSecondary,
        ),
      ),
      selected: isSelected,
      selectedColor: AdminColors.goldAccent,
      backgroundColor: AdminColors.deepTeal,
      side: BorderSide(color: isSelected ? AdminColors.goldAccent : AdminColors.border),
      onSelected: (_) {
        setState(() => _selectedStatus = value);
        _loadData();
      },
    );
  }

  Widget _buildVoucherGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1080 ? 3 : (constraints.maxWidth > 700 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 16) / crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _vouchers.map((v) {
            return SizedBox(
              width: cardWidth,
              child: _buildVoucherTicketCard(v),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildVoucherTicketCard(AdminVoucherItem v) {
    Color statusBadgeColor = AdminColors.emerald;
    String statusText = 'Đang kích hoạt';

    if (!v.isActive) {
      statusBadgeColor = AdminColors.textMuted;
      statusText = 'Tạm dừng';
    } else if (v.isExpired) {
      statusBadgeColor = AdminColors.statusCancelled;
      statusText = 'Hết hạn';
    } else if (v.isExhausted) {
      statusBadgeColor = AdminColors.statusPending;
      statusText = 'Hết lượt';
    }

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: v.isActive ? AdminColors.border : AdminColors.border.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header cuống vé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AdminColors.slateTeal.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
              border: const Border(bottom: BorderSide(color: AdminColors.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AdminColors.goldAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AdminColors.goldAccent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    v.code,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.goldAccent,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBadgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusBadgeColor,
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: v.isActive,
                  activeThumbColor: AdminColors.goldAccent,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: (val) => _onToggleStatus(v, val),
                ),
              ],
            ),
          ),

          // Thân vé
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  v.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  v.discountDisplayText,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.softGold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  v.description.isNotEmpty ? v.description : 'Áp dụng cho mọi đơn hàng đủ điều kiện.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: AdminColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),

                // Thông tin điều kiện
                Row(
                  children: [
                    const Icon(Icons.shopping_cart_outlined, size: 14, color: AdminColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      v.minOrderFormatted,
                      style: GoogleFonts.beVietnamPro(fontSize: 12, color: AdminColors.textSecondary),
                    ),
                    const Spacer(),
                    const Icon(Icons.group_outlined, size: 14, color: AdminColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      v.targetAudience == 'vip' ? 'VIP Only' : 'Mọi khách',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: v.targetAudience == 'vip' ? AdminColors.goldAccent : AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Thanh tiến độ sử dụng
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đã dùng: ${v.usedCount}/${v.usageLimit}',
                      style: GoogleFonts.beVietnamPro(fontSize: 11, color: AdminColors.textMuted),
                    ),
                    Text(
                      'Còn lại: ${v.remainingUses}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: v.remainingUses > 0 ? AdminColors.emerald : AdminColors.statusCancelled,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: v.usagePercent,
                    backgroundColor: AdminColors.deepTeal,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      v.usagePercent >= 1.0 ? AdminColors.statusCancelled : AdminColors.goldAccent,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 14),

                // Hạn dùng & Nút thao tác
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AdminColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        v.validRangeFormatted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.beVietnamPro(fontSize: 11, color: AdminColors.textMuted),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AdminColors.textSecondary),
                      tooltip: 'Sửa cấu hình',
                      onPressed: () async {
                        final updated = await AdminVoucherFormDialog.show(context, initialVoucher: v);
                        if (updated == true) _loadData();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AdminColors.statusCancelled),
                      tooltip: 'Xóa voucher',
                      onPressed: () => _onDeleteVoucher(v),
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AdminColors.cardSurface,
                shape: BoxShape.circle,
                border: Border.all(color: AdminColors.border),
              ),
              child: const Icon(Icons.search_off_rounded, size: 48, color: AdminColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy voucher nào',
              style: GoogleFonts.beVietnamPro(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AdminColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hãy thử thay đổi từ khóa tìm kiếm hoặc nhấn "+ Tạo Voucher Mới".',
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
