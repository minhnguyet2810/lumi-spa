import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/admin_colors.dart';
import '../../data/models/admin_financial_analytics_model.dart';
import '../../data/admin_analytics_repository.dart';

class AdminFinancialAnalyticsScreen extends StatefulWidget {
  const AdminFinancialAnalyticsScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<AdminFinancialAnalyticsScreen> createState() => _AdminFinancialAnalyticsScreenState();
}

class _AdminFinancialAnalyticsScreenState extends State<AdminFinancialAnalyticsScreen> {
  String _selectedPeriod = 'last_30_days'; // 'today', 'last_7_days', 'last_30_days', 'this_month'
  String _selectedBranch = 'all'; // 'all', 'central_hub', 'branch_q7', 'branch_tb'

  FinancialReportData? _reportData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminAnalyticsRepository.instance.fetchFinancialOverview(
        period: _selectedPeriod,
        branchId: _selectedBranch,
      );
      if (mounted) {
        setState(() {
          _reportData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = RefreshIndicator(
      onRefresh: _loadReport,
      color: AdminColors.primary,
      backgroundColor: AdminColors.cardSurface,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thanh lọc Thời Gian & Chi Nhánh
            _buildFilterHeader(),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: CircularProgressIndicator(color: AdminColors.primary),
                ),
              )
            else if (_reportData == null)
              _buildErrorState()
            else ...[
              // 4 Thẻ KPI Tài Chính
              _buildKpiSummarySection(_reportData!.summary),
              const SizedBox(height: 24),

              // Cơ Cấu Doanh Thu: Mỹ Phẩm vs Spa Services
              _buildRevenueBreakdownSection(_reportData!.summary),
              const SizedBox(height: 24),

              // Biểu Đồ Xu Hướng Hàng Ngày (Bar & Trend Chart)
              _buildDailyTrendChartSection(_reportData!.dailyTrend),
              const SizedBox(height: 24),

              // Top Performers: Mỹ phẩm & Liệu trình Spa
              _buildTopPerformersSection(_reportData!.topProducts, _reportData!.topServices),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );

    if (!widget.showAppBar) {
      return Container(
        color: AdminColors.background,
        child: bodyContent,
      );
    }

    return Scaffold(
      backgroundColor: AdminColors.background,
      appBar: AppBar(
        backgroundColor: AdminColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AdminColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AdminColors.peach,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminColors.border),
              ),
              child: const Icon(Icons.insights_rounded, color: AdminColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Báo Cáo Doanh Thu & Lợi Nhuận Gộp',
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
            icon: const Icon(Icons.refresh_rounded, color: AdminColors.primary),
            tooltip: 'Tải lại dữ liệu',
            onPressed: _loadReport,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildFilterHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow) ...[
                _buildPeriodChips(),
                const SizedBox(height: 12),
                _buildBranchDropdown(),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPeriodChips(),
                    _buildBranchDropdown(),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildPeriodChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildPeriodChoice('today', 'Hôm nay'),
          const SizedBox(width: 8),
          _buildPeriodChoice('last_7_days', '7 ngày qua'),
          const SizedBox(width: 8),
          _buildPeriodChoice('last_30_days', '30 ngày qua'),
          const SizedBox(width: 8),
          _buildPeriodChoice('this_month', 'Tháng này'),
        ],
      ),
    );
  }

  Widget _buildPeriodChoice(String key, String label) {
    final isSelected = _selectedPeriod == key;
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
        setState(() => _selectedPeriod = key);
        _loadReport();
      },
    );
  }

  Widget _buildBranchDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AdminColors.deepTeal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBranch,
          dropdownColor: AdminColors.cardSurface,
          style: GoogleFonts.beVietnamPro(color: AdminColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
          items: const [
            DropdownMenuItem(value: 'all', child: Text('Toàn bộ chi nhánh')),
            DropdownMenuItem(value: 'central_hub', child: Text('Chi nhánh Quận 1 (Central Hub)')),
            DropdownMenuItem(value: 'branch_q7', child: Text('Chi nhánh Quận 7')),
            DropdownMenuItem(value: 'branch_tb', child: Text('Chi nhánh Tân Bình')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() => _selectedBranch = val);
              _loadReport();
            }
          },
        ),
      ),
    );
  }

  Widget _buildKpiSummarySection(FinancialSummary s) {
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
              child: _buildFinancialCard(
                title: 'Tổng Doanh Thu Gộp',
                value: s.totalRevenueFormatted,
                subtitle: '${s.ordersCount} đơn hàng + ${s.bookingsCount} lượt spa',
                icon: Icons.payments_rounded,
                accentColor: AdminColors.goldAccent,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildFinancialCard(
                title: 'Giá Vốn Hàng Bán (COGS)',
                value: s.totalCogsFormatted,
                subtitle: 'Chi phí vốn sản phẩm & vật tư liệu trình',
                icon: Icons.inventory_2_outlined,
                accentColor: AdminColors.statusPending,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildFinancialCard(
                title: 'Lợi Nhuận Gộp (Gross Profit)',
                value: s.grossProfitFormatted,
                subtitle: 'Doanh thu trừ trực tiếp giá vốn',
                icon: Icons.account_balance_rounded,
                accentColor: AdminColors.emerald,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildFinancialCard(
                title: 'Biên Lợi Nhuận Gộp',
                value: '${s.grossMarginPercent.toStringAsFixed(1)}%',
                subtitle: 'Hiệu quả biên lãi gộp toàn hệ thống',
                icon: Icons.pie_chart_outline_rounded,
                accentColor: AdminColors.cyan,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFinancialCard({
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
        boxShadow: AdminColors.cardShadow,
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

  Widget _buildRevenueBreakdownSection(FinancialSummary s) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cơ Cấu Doanh Thu: Mỹ Phẩm Bán Lẻ vs Liệu Trình Spa',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Phân rã tỷ trọng nguồn thu và chi phí vốn của 2 mảng kinh doanh',
                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: AdminColors.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('Bán lẻ Mỹ phẩm (${s.retailRatio.toStringAsFixed(1)}%)', AdminColors.goldAccent),
                  const SizedBox(width: 16),
                  _buildLegendItem('Dịch vụ Spa (${s.serviceRatio.toStringAsFixed(1)}%)', AdminColors.emerald),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Thanh phân rã tỷ lệ kép
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Expanded(
                    flex: math.max(1, s.retailRatio.round()),
                    child: Container(color: AdminColors.goldAccent),
                  ),
                  Expanded(
                    flex: math.max(1, s.serviceRatio.round()),
                    child: Container(color: AdminColors.emerald),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2 Khối Chi Tiết
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return isWide
                  ? Row(
                      children: [
                        Expanded(child: _buildBreakdownCard(
                          title: 'Mảng Mỹ Phẩm & Sản Phẩm Bán Lẻ',
                          revenue: s.retailRevenueFormatted,
                          cogs: FinancialSummary.formatCurrency(s.retailCogs),
                          grossProfit: FinancialSummary.formatCurrency(s.retailRevenue - s.retailCogs),
                          countText: '${s.ordersCount} đơn hàng thành công',
                          accentColor: AdminColors.goldAccent,
                        )),
                        const SizedBox(width: 16),
                        Expanded(child: _buildBreakdownCard(
                          title: 'Mảng Liệu Trình & Dịch Vụ Spa',
                          revenue: s.serviceRevenueFormatted,
                          cogs: FinancialSummary.formatCurrency(s.serviceCogs),
                          grossProfit: FinancialSummary.formatCurrency(s.serviceRevenue - s.serviceCogs),
                          countText: '${s.bookingsCount} lượt hoàn tất trị liệu',
                          accentColor: AdminColors.emerald,
                        )),
                      ],
                    )
                  : Column(
                      children: [
                        _buildBreakdownCard(
                          title: 'Mảng Mỹ Phẩm & Sản Phẩm Bán Lẻ',
                          revenue: s.retailRevenueFormatted,
                          cogs: FinancialSummary.formatCurrency(s.retailCogs),
                          grossProfit: FinancialSummary.formatCurrency(s.retailRevenue - s.retailCogs),
                          countText: '${s.ordersCount} đơn hàng thành công',
                          accentColor: AdminColors.goldAccent,
                        ),
                        const SizedBox(height: 12),
                        _buildBreakdownCard(
                          title: 'Mảng Liệu Trình & Dịch Vụ Spa',
                          revenue: s.serviceRevenueFormatted,
                          cogs: FinancialSummary.formatCurrency(s.serviceCogs),
                          grossProfit: FinancialSummary.formatCurrency(s.serviceRevenue - s.serviceCogs),
                          countText: '${s.bookingsCount} lượt hoàn tất trị liệu',
                          accentColor: AdminColors.emerald,
                        ),
                      ],
                    );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.beVietnamPro(fontSize: 12, fontWeight: FontWeight.w600, color: AdminColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildBreakdownCard({
    required String title,
    required String revenue,
    required String cogs,
    required String grossProfit,
    required String countText,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdminColors.deepTeal.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AdminColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Doanh thu:', style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textSecondary)),
              Text(revenue, style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w700, color: accentColor)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Giá vốn (COGS):', style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textSecondary)),
              Text(cogs, style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.statusPending)),
            ],
          ),
          const Divider(color: AdminColors.border, height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Lợi nhuận gộp:', style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textPrimary)),
              Text(grossProfit, style: GoogleFonts.beVietnamPro(fontSize: 14, fontWeight: FontWeight.w800, color: AdminColors.emerald)),
            ],
          ),
          const SizedBox(height: 4),
          Text(countText, style: GoogleFonts.beVietnamPro(fontSize: 11, color: AdminColors.textMuted)),
        ],
      ),
    );
  }

  Widget _buildDailyTrendChartSection(List<DailyFinancialTrend> trends) {
    if (trends.isEmpty) return const SizedBox.shrink();

    // Tìm giá trị max để scale biểu đồ
    final maxRev = trends.fold<int>(1, (prev, curr) => math.max(prev, curr.totalRevenue));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Biểu Đồ Xu Hướng Doanh Thu Hàng Ngày (Daily Revenue Trend)',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Biểu diễn doanh thu gộp theo từng ngày và đóng góp từng mảng',
                    style: GoogleFonts.beVietnamPro(fontSize: 12, color: AdminColors.textMuted),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendItem('Mỹ phẩm', AdminColors.goldAccent),
                  const SizedBox(width: 12),
                  _buildLegendItem('Spa Services', AdminColors.emerald),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Container vẽ các cột biểu đồ
          SizedBox(
            height: 220,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // Cuộn về những ngày gần nhất
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: trends.map((day) {
                  final totalH = (day.totalRevenue / maxRev) * 160;
                  final retailH = day.totalRevenue > 0 ? (day.retailRevenue / day.totalRevenue) * totalH : 0.0;
                  final serviceH = totalH - retailH;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 32,
                    child: Tooltip(
                      message: '${day.date}\nDoanh thu: ${FinancialSummary.formatCurrency(day.totalRevenue)}\nLãi gộp: ${FinancialSummary.formatCurrency(day.grossProfit)}',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Cột phân tầng
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: SizedBox(
                              width: 22,
                              height: math.max(6, totalH),
                              child: Column(
                                children: [
                                  Container(height: math.max(0, serviceH), color: AdminColors.emerald),
                                  Container(height: math.max(0, retailH), color: AdminColors.goldAccent),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Ngày
                          Text(
                            day.shortDate,
                            style: GoogleFonts.beVietnamPro(fontSize: 9, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformersSection(List<TopPerformerItem> products, List<TopPerformerItem> services) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildTopProductsTable(products)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTopServicesTable(services)),
                ],
              )
            : Column(
                children: [
                  _buildTopProductsTable(products),
                  const SizedBox(height: 16),
                  _buildTopServicesTable(services),
                ],
              );
      },
    );
  }

  Widget _buildTopProductsTable(List<TopPerformerItem> items) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: AdminColors.goldAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Top 5 Mỹ Phẩm Doanh Thu Cao',
                  style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Chưa có dữ liệu sản phẩm', style: GoogleFonts.beVietnamPro(color: AdminColors.textMuted))),
            )
          else
            ...items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final it = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AdminColors.border, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: idx == 1 ? AdminColors.goldAccent : AdminColors.deepTeal,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$idx',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: idx == 1 ? Colors.black : AdminColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                          ),
                          Text(
                            'Đã bán: ${it.unitsSold ?? 0} sp | Lãi gộp: ${it.profitFormatted}',
                            style: GoogleFonts.beVietnamPro(fontSize: 11, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      it.revenueFormatted,
                      style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.goldAccent),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTopServicesTable(List<TopPerformerItem> items) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_rounded, color: AdminColors.emerald, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Top 5 Liệu Trình Spa Doanh Thu Cao',
                  style: GoogleFonts.beVietnamPro(fontSize: 15, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: Text('Chưa có dữ liệu dịch vụ', style: GoogleFonts.beVietnamPro(color: AdminColors.textMuted))),
            )
          else
            ...items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final it = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AdminColors.border, width: 0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: idx == 1 ? AdminColors.emerald : AdminColors.deepTeal,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$idx',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: idx == 1 ? Colors.black : AdminColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            it.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w600, color: AdminColors.textPrimary),
                          ),
                          Text(
                            'Hoàn tất: ${it.sessionsCount ?? 0} ca | Lãi gộp: ${it.profitFormatted}',
                            style: GoogleFonts.beVietnamPro(fontSize: 11, color: AdminColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      it.revenueFormatted,
                      style: GoogleFonts.beVietnamPro(fontSize: 13, fontWeight: FontWeight.w700, color: AdminColors.emerald),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AdminColors.statusCancelled),
            const SizedBox(height: 12),
            Text(
              'Không thể tải báo cáo tài chính',
              style: GoogleFonts.beVietnamPro(fontSize: 16, fontWeight: FontWeight.w700, color: AdminColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Vui lòng kiểm tra lại kết nối mạng hoặc thử lại sau.',
              style: GoogleFonts.beVietnamPro(fontSize: 13, color: AdminColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
