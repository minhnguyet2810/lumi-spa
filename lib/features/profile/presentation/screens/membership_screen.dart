import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/data/lumi_account_repository.dart';
import '../../../../core/theme/lumi_adaptive.dart';
import '../../../../core/theme/lumi_style.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late Future<LumiMembership> _membershipFuture;
  int _selectedTierIndex = 0;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _membershipFuture = LumiAccountRepository.fetchMembership();
  }

  void _retry() {
    setState(() {
      _membershipFuture = LumiAccountRepository.fetchMembership();
    });
  }

  Future<void> _sync() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final updated = await LumiAccountRepository.syncMembership();
      setState(() {
        _membershipFuture = Future.value(updated);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LumiAdaptive.text('Đã cập nhật dữ liệu điểm thành viên mới nhất ✨'),
              style: GoogleFonts.beVietnamPro(),
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              LumiAdaptive.text('Không thể đồng bộ điểm. Vui lòng thử lại sau.'),
              style: GoogleFonts.beVietnamPro(),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  String _formatCurrency(num amount) {
    final value = amount.toInt();
    final parts = <String>[];
    String s = value.toString();
    while (s.length > 3) {
      parts.insert(0, s.substring(s.length - 3));
      s = s.substring(0, s.length - 3);
    }
    parts.insert(0, s);
    return '${parts.join('.')} đ';
  }

  String _formatNumber(int number) {
    final parts = <String>[];
    String s = number.toString();
    while (s.length > 3) {
      parts.insert(0, s.substring(s.length - 3));
      s = s.substring(0, s.length - 3);
    }
    parts.insert(0, s);
    return parts.join('.');
  }

  @override
  Widget build(BuildContext context) => LumiAdaptive.watch(
    context,
    () => Scaffold(
      appBar: AppBar(
        title: Text(
          LumiAdaptive.text('Thẻ thành viên LUMI'),
          style: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: LumiAdaptive.text('Đồng bộ điểm'),
            onPressed: _isSyncing ? null : _sync,
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final updated = await LumiAccountRepository.syncMembership();
          setState(() {
            _membershipFuture = Future.value(updated);
          });
        },
        child: FutureBuilder<LumiMembership>(
          future: _membershipFuture,
          builder: (context, snapshot) {
            final membership = snapshot.data;
            final loading = snapshot.connectionState == ConnectionState.waiting;

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _messageCard(
                    icon: Icons.cloud_off_outlined,
                    title: 'Không tải được dữ liệu thành viên',
                    message: snapshot.error.toString(),
                    action: FilledButton(
                      onPressed: _retry,
                      child: Text(LumiAdaptive.text('Thử lại')),
                    ),
                  ),
                ],
              );
            }

            if (loading && membership == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.dustyRose),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
              children: [
                _digitalMemberCard(membership),
                const SizedBox(height: 16),
                _progressSection(membership),
                const SizedBox(height: 16),
                _conversionRateBanner(),
                const SizedBox(height: 20),
                _tierPerksSection(membership),
              ],
            );
          },
        ),
      ),
    ),
  );

  /// Thẻ thành viên kỹ thuật số cao cấp (Digital Member Card)
  Widget _digitalMemberCard(LumiMembership? membership) {
    final tier = (membership?.tier ?? 'Member').toLowerCase();
    final points = membership?.points ?? 0;
    final totalSpent = membership?.totalSpent ?? 0;
    final discount = membership?.discountPercent ?? 0;

    // Gradient và màu sắc chủ đạo theo hạng
    List<Color> cardGradient;
    Color badgeColor;
    IconData tierIcon;

    if (tier == 'diamond') {
      cardGradient = [
        const Color(0xFF0F172A),
        const Color(0xFF0369A1),
        const Color(0xFF0284C7),
      ];
      badgeColor = const Color(0xFF38BDF8);
      tierIcon = Icons.diamond_outlined;
    } else if (tier == 'gold') {
      cardGradient = [
        const Color(0xFF451A03),
        const Color(0xFF92400E),
        const Color(0xFFD97706),
      ];
      badgeColor = const Color(0xFFFBBF24);
      tierIcon = Icons.workspace_premium_rounded;
    } else if (tier == 'silver') {
      cardGradient = [
        const Color(0xFF1E293B),
        const Color(0xFF475569),
        const Color(0xFF64748B),
      ];
      badgeColor = const Color(0xFFE2E8F0);
      tierIcon = Icons.military_tech_rounded;
    } else {
      // Member / Bronze
      cardGradient = [
        const Color(0xFF3B1E19),
        const Color(0xFF7C3E32),
        const Color(0xFFA5553E),
      ];
      badgeColor = const Color(0xFFFDBA74);
      tierIcon = Icons.spa_rounded;
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: cardGradient,
        ),
        boxShadow: [
          BoxShadow(
            color: cardGradient.last.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Hoa văn chìm
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(
              tierIcon,
              size: 160,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(tierIcon, color: badgeColor, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'LUMI SPA',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: badgeColor.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        LumiAdaptive.text(membership?.tierLabel ?? (membership?.tier ?? 'Thành viên')),
                        style: GoogleFonts.beVietnamPro(
                          color: badgeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  LumiAdaptive.text('Điểm tích lũy hiện có'),
                  style: GoogleFonts.beVietnamPro(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _formatNumber(points),
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      LumiAdaptive.text('điểm'),
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (discount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Giảm $discount%',
                          style: GoogleFonts.beVietnamPro(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24, height: 1),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LumiAdaptive.text('Tổng chi tiêu: ${_formatCurrency(totalSpent)}'),
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '1.000 đ = 1 điểm',
                      style: GoogleFonts.beVietnamPro(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
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

  /// Khối tiến trình thăng hạng
  Widget _progressSection(LumiMembership? membership) {
    final isDiamond = (membership?.tier ?? '').toLowerCase() == 'diamond';
    final nextTierLabel = membership?.nextTierLabel ?? membership?.nextTier;
    final pointsToNext = membership?.pointsToNextTier ?? 0;
    final spentToNext = membership?.spentToNextTier ?? (pointsToNext * 1000);
    final progress = (membership?.progress ?? 0.0).clamp(0.0, 1.0);

    return _card(
      background: LumiAdaptive.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: LumiAdaptive.color(AppColors.dustyRose),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  LumiAdaptive.text(
                    isDiamond ? 'Hạng thành viên tối cao' : 'Tiến trình thăng hạng',
                  ),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: LumiAdaptive.color(LumiStyle.plum),
                  ),
                ),
              ),
              if (!isDiamond)
                Text(
                  '${(progress * 100).toInt()}%',
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LumiAdaptive.color(AppColors.dustyRose),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (isDiamond) ...[
            Text(
              LumiAdaptive.text(
                'Chúc mừng quý khách! Bạn đang nắm giữ thẻ Kim Cương – hạng thành viên đặc quyền cao nhất của LUMI SPA.',
              ),
              style: GoogleFonts.beVietnamPro(
                fontSize: 14,
                color: LumiAdaptive.color(LumiStyle.ink),
                height: 1.4,
              ),
            ),
          ] else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                backgroundColor: LumiAdaptive.color(const Color(0xFFE2E8F0)),
                valueColor: AlwaysStoppedAnimation<Color>(
                  LumiAdaptive.color(AppColors.dustyRose),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text.rich(
              TextSpan(
                text: LumiAdaptive.text('Cần tích luỹ thêm '),
                children: [
                  TextSpan(
                    text: '${_formatNumber(pointsToNext)} điểm',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: ' (~${_formatCurrency(spentToNext)}) để thăng lên ',
                  ),
                  TextSpan(
                    text: LumiAdaptive.text(nextTierLabel ?? 'hạng kế tiếp'),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: LumiAdaptive.color(AppColors.dustyRose),
                    ),
                  ),
                ],
              ),
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                color: LumiAdaptive.color(LumiStyle.ink),
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Banner quy chế quy đổi điểm minh bạch
  Widget _conversionRateBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: LumiAdaptive.isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: LumiAdaptive.isDark ? const Color(0xFF334155) : const Color(0xFFFFEDD5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Color(0xFFEA580C),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LumiAdaptive.text('Quy ước tích điểm LUMI'),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: LumiAdaptive.isDark ? Colors.white : const Color(0xFF9A3412),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  LumiAdaptive.text('1.000 VNĐ = 1 điểm. Điểm tự động cộng ngay khi hoàn thành đơn mua hoặc liệu trình spa.'),
                  style: GoogleFonts.beVietnamPro(
                    fontSize: 12,
                    color: LumiAdaptive.isDark ? const Color(0xFF94A3B8) : const Color(0xFFC2410C),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Danh mục so sánh và khám phá đặc quyền của từng hạng thành viên
  Widget _tierPerksSection(LumiMembership? membership) {
    final allTiers = membership?.allTiers ?? _defaultTiers();
    if (allTiers.isEmpty) return const SizedBox.shrink();

    final safeIndex = _selectedTierIndex.clamp(0, allTiers.length - 1);
    final selectedTier = allTiers[safeIndex];
    final userTierName = (membership?.tier ?? 'Member').toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LumiAdaptive.text('Bảng quyền lợi các hạng thành viên'),
          style: GoogleFonts.beVietnamPro(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: LumiAdaptive.color(LumiStyle.plum),
          ),
        ),
        const SizedBox(height: 12),
        // Bộ chọn Tab Hạng
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(allTiers.length, (index) {
              final t = allTiers[index];
              final isSelected = index == safeIndex;
              final isUserCurrentTier = t.name.toLowerCase() == userTierName;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LumiAdaptive.text(t.label),
                        style: GoogleFonts.beVietnamPro(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (isUserCurrentTier) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.dustyRose),
                      ],
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() => _selectedTierIndex = index);
                  },
                  selectedColor: AppColors.dustyRose.withValues(alpha: 0.15),
                  checkmarkColor: AppColors.dustyRose,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected ? AppColors.dustyRose : Colors.transparent,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 14),
        // Chi tiết quyền lợi của hạng đang chọn
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.dustyRose.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Hạng ${selectedTier.label}',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.dustyRose,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    selectedTier.discountPercent > 0
                        ? 'Giảm ${selectedTier.discountPercent}% dịch vụ'
                        : 'Tích điểm chuẩn',
                    style: GoogleFonts.beVietnamPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: LumiAdaptive.color(LumiStyle.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                LumiAdaptive.text(
                  selectedTier.maxPoints != null
                      ? 'Yêu cầu: ${_formatNumber(selectedTier.minPoints)} – ${_formatNumber(selectedTier.maxPoints!)} điểm'
                      : 'Yêu cầu: Từ ${_formatNumber(selectedTier.minPoints)} điểm trở lên',
                ),
                style: GoogleFonts.beVietnamPro(
                  fontSize: 12,
                  color: LumiAdaptive.color(LumiStyle.muted),
                ),
              ),
              const Divider(height: 20),
              ...selectedTier.benefits.map((benefit) => _perkItem(benefit)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _perkItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.dustyRose.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.dustyRose,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              LumiAdaptive.text(benefit),
              style: GoogleFonts.beVietnamPro(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: LumiAdaptive.color(LumiStyle.plum),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _messageCard({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) => _card(
    child: Column(
      children: [
        Icon(icon, size: 36, color: LumiAdaptive.color(LumiStyle.rose)),
        const SizedBox(height: 10),
        Text(
          LumiAdaptive.text(title),
          style: GoogleFonts.beVietnamPro(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: LumiAdaptive.color(LumiStyle.plum),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          LumiAdaptive.text(message),
          textAlign: TextAlign.center,
          style: GoogleFonts.beVietnamPro(
            fontSize: 13,
            color: LumiAdaptive.color(LumiStyle.ink),
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 12),
          action,
        ],
      ],
    ),
  );

  Widget _card({required Widget child, Color background = LumiStyle.surface}) =>
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: LumiAdaptive.color(background, surface: true),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: LumiAdaptive.isDark
                ? const Color(0xFF334155)
                : const Color(0xFFEDE4DB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );

  List<LumiTierInfo> _defaultTiers() => const [
    LumiTierInfo(
      id: 'member',
      name: 'Member',
      label: 'Thành viên',
      minPoints: 0,
      maxPoints: 999,
      minSpent: 0,
      discountPercent: 0,
      color: '#C5A880',
      badge: 'Bronze',
      benefits: [
        'Tích lũy 1 điểm cho mỗi 1.000 VNĐ chi tiêu',
        'Quà tặng chào mừng: Voucher 5% cho đơn đầu tiên',
        'Cập nhật ưu đãi & sự kiện sớm nhất',
        'Tư vấn da chuyên sâu 1:1 miễn phí',
      ],
    ),
    LumiTierInfo(
      id: 'silver',
      name: 'Silver',
      label: 'Hạng Bạc',
      minPoints: 1000,
      maxPoints: 4999,
      minSpent: 1000000,
      discountPercent: 5,
      color: '#94A3B8',
      badge: 'Silver',
      benefits: [
        'Giảm 5% trực tiếp trên mọi dịch vụ & mỹ phẩm',
        'Tặng Voucher sinh nhật 100.000 đ',
        'Ưu tiên chọn khung giờ hẹn & chuyên viên yêu thích',
      ],
    ),
    LumiTierInfo(
      id: 'gold',
      name: 'Gold',
      label: 'Hạng Vàng',
      minPoints: 5000,
      maxPoints: 14999,
      minSpent: 5000000,
      discountPercent: 10,
      color: '#F59E0B',
      badge: 'Gold',
      benefits: [
        'Giảm 10% trực tiếp trên mọi dịch vụ & mỹ phẩm',
        'Miễn phí vận chuyển (Freeship) toàn quốc',
        'Voucher sinh nhật cao cấp 300.000 đ',
        'Miễn phí ngâm chân thảo mộc & thức uống cao cấp',
      ],
    ),
    LumiTierInfo(
      id: 'diamond',
      name: 'Diamond',
      label: 'Kim Cương',
      minPoints: 15000,
      minSpent: 15000000,
      discountPercent: 15,
      color: '#38BDF8',
      badge: 'Diamond',
      benefits: [
        'Giảm 15% VIP trọn đời trên mọi dịch vụ & mỹ phẩm',
        'Tặng 01 liệu trình chăm sóc da mặt miễn phí tháng sinh nhật',
        'Phòng dịch vụ VIP riêng biệt & Master KTV',
        'Chuyên viên hỗ trợ 24/7',
      ],
    ),
  ];
}
