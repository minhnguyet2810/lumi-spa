import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/lumi_style.dart';
import '../../data/admin_user_repository.dart';
import '../../data/models/admin_user_item.dart';
import '../widgets/admin_user_card.dart';
import '../widgets/admin_user_detail_dialog.dart';
import '../widgets/admin_user_table.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final _searchController = TextEditingController();
  int _selectedRoleFilter = 0; // 0: Tất cả, 1: Khách hàng, 2: Quản trị viên
  bool? _forceTableView;

  List<AdminUserItem>? _fallbackApiUsers;
  bool _isFetchingFallback = false;
  bool _fallbackFailed = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchFallbackApi() async {
    if (_isFetchingFallback) {
      return;
    }
    setState(() {
      _isFetchingFallback = true;
      _fallbackFailed = false;
    });

    try {
      final list = await AdminUserRepository.instance.fetchUsersFromApi();
      if (!mounted) {
        return;
      }
      setState(() {
        _fallbackApiUsers = list;
        _isFetchingFallback = false;
        _fallbackFailed = list.isEmpty;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isFetchingFallback = false;
        _fallbackFailed = true;
      });
    }
  }

  void _showRulesGuideDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kiểm tra quyền quản trị'),
        content: const Text(
          'Đăng nhập bằng tài khoản đã được cấp quyền admin, sau đó chọn Làm mới quyền. Nếu vẫn không tải được dữ liệu, hãy kiểm tra kết nối máy chủ hoặc liên hệ người quản lý hệ thống.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void _showUserDetail(AdminUserItem user) {
    showDialog(
      context: context,
      builder: (_) => AdminUserDetailDialog(user: user),
    );
  }

  List<AdminUserItem> _filterUsers(List<AdminUserItem> allUsers) {
    var result = allUsers;

    switch (_selectedRoleFilter) {
      case 1: // Khách hàng
        result = result.where((u) => !u.isAdmin).toList();
        break;
      case 2: // Quản trị viên
        result = result.where((u) => u.isAdmin).toList();
        break;
    }

    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((u) {
        return u.displayName.toLowerCase().contains(query) ||
            u.email.toLowerCase().contains(query) ||
            u.phone.toLowerCase().contains(query) ||
            u.id.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  Widget _buildFallbackNoticeBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_sync_rounded,
            color: Color(0xFFB45309),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đang đồng bộ người dùng qua Backend API (Port 3000)',
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Firestore Security Rules hiện chặn quyền đọc trực tiếp từ máy khách.',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: _showRulesGuideDialog,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFB45309)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
            ),
            child: Text(
              'Kiểm tra quyền',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminUserItem>>(
      stream: AdminUserRepository.instance.streamAllUsers(),
      builder: (context, snapshot) {
        List<AdminUserItem> allUsers = [];
        bool isUsingFallback = false;

        if (snapshot.connectionState == ConnectionState.waiting &&
            _fallbackApiUsers == null) {
          return const Center(
            child: CircularProgressIndicator(color: LumiStyle.rose),
          );
        }

        if (snapshot.hasError) {
          if (_fallbackApiUsers != null) {
            allUsers = _fallbackApiUsers!;
            isUsingFallback = true;
          } else {
            if (!_isFetchingFallback && !_fallbackFailed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _fetchFallbackApi();
              });
            }

            if (_isFetchingFallback) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: LumiStyle.rose),
                    const SizedBox(height: 16),
                    Text(
                      'Phát hiện lỗi Firestore Rules. Đang chuyển sang nạp qua Backend API...',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: LumiStyle.muted,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lỗi kết nối người dùng Firestore',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: LumiStyle.plum,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: LumiStyle.muted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FilledButton.icon(
                          onPressed: _fetchFallbackApi,
                          style: FilledButton.styleFrom(
                            backgroundColor: LumiStyle.rose,
                          ),
                          icon: const Icon(
                            Icons.cloud_download_rounded,
                            size: 16,
                          ),
                          label: Text(
                            'Tải qua Backend API',
                            style: GoogleFonts.dmSans(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _showRulesGuideDialog,
                          icon: const Icon(Icons.security_rounded, size: 16),
                          label: Text(
                            'Kiểm tra quyền',
                            style: GoogleFonts.dmSans(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        } else {
          allUsers = snapshot.data ?? [];
        }

        final filteredUsers = _filterUsers(allUsers);
        final customerCount = allUsers.where((u) => !u.isAdmin).length;
        final adminCount = allUsers.where((u) => u.isAdmin).length;
        final activeCount = allUsers
            .where((u) => u.bookingCount > 0 || u.orderCount > 0)
            .length;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            final showTableView = _forceTableView ?? isDesktop;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isUsingFallback) _buildFallbackNoticeBanner(),

                        // Responsive summary cards
                        _statGrid(
                          children: [
                            _buildStatCard(
                              title: 'Tổng người dùng',
                              count: allUsers.length,
                              color: LumiStyle.plum,
                              icon: Icons.people_rounded,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              title: 'Khách hàng',
                              count: customerCount,
                              color: const Color(0xFF2563EB),
                              icon: Icons.person_rounded,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              title: 'Quản trị viên',
                              count: adminCount,
                              color: const Color(0xFF7C3AED),
                              icon: Icons.admin_panel_settings_rounded,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              title: 'Đã có giao dịch',
                              count: activeCount,
                              color: const Color(0xFF16A34A),
                              icon: Icons.how_to_reg_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search & View Mode Switcher
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: InputDecoration(
                                  hintText: 'Tìm kiếm theo tên khách, email, số điện thoại hoặc User ID...',
                                  hintStyle: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    color: LumiStyle.muted,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: LumiStyle.rose,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: LumiStyle.line,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: LumiStyle.line,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: LumiStyle.rose,
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: LumiStyle.line),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Hiển thị dạng Bảng',
                                    icon: Icon(
                                      Icons.table_chart_rounded,
                                      color: showTableView
                                          ? LumiStyle.rose
                                          : LumiStyle.muted,
                                    ),
                                    onPressed: () =>
                                        setState(() => _forceTableView = true),
                                  ),
                                  IconButton(
                                    tooltip: 'Hiển thị dạng Thẻ',
                                    icon: Icon(
                                      Icons.grid_view_rounded,
                                      color: !showTableView
                                          ? LumiStyle.rose
                                          : LumiStyle.muted,
                                    ),
                                    onPressed: () =>
                                        setState(() => _forceTableView = false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Role Filter Tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(0, 'Tất cả', allUsers.length),
                              _buildFilterChip(1, 'Khách hàng', customerCount),
                              _buildFilterChip(2, 'Quản trị viên', adminCount),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Users List / Table
                if (filteredUsers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_search_outlined,
                              size: 56,
                              color: LumiStyle.muted.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Không tìm thấy người dùng nào',
                              style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: LumiStyle.plum,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc vai trò.',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                color: LumiStyle.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (showTableView)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: AdminUserTable(
                        users: filteredUsers,
                        onTapDetail: _showUserDetail,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final user = filteredUsers[index];
                        return AdminUserCard(
                          user: user,
                          onTapDetail: () => _showUserDetail(user),
                        );
                      }, childCount: filteredUsers.length),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _statGrid({required List<Widget> children}) {
    final cards = children.where((widget) => widget is! SizedBox).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720
            ? 4
            : (constraints.maxWidth >= 240 ? 2 : 1);
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final card in cards) SizedBox(width: width, child: card),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.07), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: color.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$count',
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        height: 1,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF403735),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF756863),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label, int count) {
    final isSelected = _selectedRoleFilter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedRoleFilter = index);
          }
        },
        selectedColor: LumiStyle.plum,
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? LumiStyle.plum : LumiStyle.line),
        labelStyle: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : LumiStyle.plum,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }
}
