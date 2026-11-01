import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'lumi_booking_screen.dart';
import 'spa_catalog.dart';
import 'lumi_shop_catalog.dart';
import 'notifications_screen.dart';
import 'lumi_journal_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/session/session_store.dart';
import '../../../../core/services/fcm_service.dart';
import '../../../../core/theme/lumi_style.dart';

import 'lumi_appointments_screen.dart';
import '../../../../core/data/lumi_catalog_repository.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _ivory = LumiStyle.ivory;
  static const _plum = LumiStyle.plum;
  static const _rose = LumiStyle.rose;

  int _tab = 0;
  bool _isLoggedIn = false;
  bool _loadingSession = true;
  bool _loggingOut = false;
  String _memberName = 'bạn';
  late Future<List<Map<String, dynamic>>> _servicesFuture;
  late Future<List<Map<String, dynamic>>> _productsFuture;

  static const _pink = LumiStyle.rose;
  static const _softPink = Color(0xFFF8D5C2);
  static const _blue = Color(0xFFA9CEDD);
  static const _ink = Color(0xFF403735);
  static const _canvas = Color(0xFFFFF8EF);
  static const _muted = LumiStyle.muted;

  int _unreadNotifCount = 0;
  StreamSubscription? _notifSubscription;
  final Set<String> _seenNotifIds = {};

  @override
  void initState() {
    super.initState();
    _loadSession();
    _servicesFuture = _fetchServices();
    _productsFuture = _fetchProducts();
    _listenToRealtimeNotifications();

    // Lắng nghe Push Notification khi người dùng đang mở app (Foreground)
    FcmService.instance.onForegroundMessage = (message) {
      final notif = message.notification;
      if (notif != null && mounted) {
        _showHeadsUpNotification(
          title: notif.title ?? 'LUMI SPA',
          message: notif.body ?? '',
          type: message.data['type']?.toString(),
        );
      }
    };

    // Khi người dùng bấm vào Push Notification trên thanh Status Bar
    FcmService.instance.onNotificationTap = (message) {
      if (!mounted) return;
      final type = message.data['type']?.toString();
      if (type == 'appointment') {
        setState(() => _tab = 3); // Mở tab Lịch hẹn
      } else {
        _openNotifications();
      }
    };
  }

  @override
  void dispose() {
    _notifSubscription?.cancel();
    super.dispose();
  }

  void _listenToRealtimeNotifications() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _notifSubscription?.cancel();
      if (user == null) {
        if (mounted) setState(() => _unreadNotifCount = 0);
        return;
      }

      _notifSubscription = FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .snapshots()
          .listen((snapshot) {
            if (!mounted) return;

            for (final change in snapshot.docChanges) {
              final data = change.doc.data();
              if (data == null) continue;

              if (change.type == DocumentChangeType.added) {
                final docId = change.doc.id;
                if (!_seenNotifIds.contains(docId)) {
                  _seenNotifIds.add(docId);
                  DateTime createdAt = DateTime.now();
                  if (data['createdAt'] is Timestamp) {
                    createdAt = (data['createdAt'] as Timestamp).toDate();
                  }
                  if (DateTime.now().difference(createdAt).inMinutes < 5) {
                    _showHeadsUpNotification(
                      title:
                          data['title']?.toString() ?? 'Thông báo từ LUMI SPA',
                      message: data['message']?.toString() ?? '',
                      type: data['type']?.toString(),
                    );
                  }
                }
              }
            }

            final totalUnread = snapshot.docs
                .where((d) => d.data()['isRead'] != true)
                .length;
            setState(() {
              _unreadNotifCount = totalUnread;
            });
          }, onError: (_) {});
    });
  }

  void _showHeadsUpNotification({
    required String title,
    required String message,
    String? type,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
    ScaffoldMessenger.of(context).showMaterialBanner(
      MaterialBanner(
        elevation: 8,
        backgroundColor: const Color(0xFFFFF8EF),
        surfaceTintColor: Colors.transparent,
        dividerColor: const Color(0xFFF0E4E6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Color(0xFFFBE7DC),
            shape: BoxShape.circle,
          ),
          child: Icon(
            type == 'appointment'
                ? Icons.calendar_month_outlined
                : type == 'order'
                ? Icons.shopping_bag_outlined
                : Icons.notifications_active_outlined,
            color: _rose,
            size: 22,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: _plum,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              message,
              style: GoogleFonts.dmSans(
                fontSize: 12.5,
                color: _muted,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              _openNotifications();
            },
            child: Text(
              'XEM',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                color: _rose,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: _muted),
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
            },
          ),
        ],
      ),
    );

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
      }
    });
  }

  Future<void> _loadSession() async {
    try {
      final loggedIn = await SessionStore.hasSession();
      final name = loggedIn ? await SessionStore.getName() : 'bạn';

      if (!mounted) return;

      setState(() {
        _isLoggedIn = loggedIn;
        _memberName = name;
        _loadingSession = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoggedIn = false;
        _memberName = 'bạn';
        _loadingSession = false;
      });
    }
  }

  Future<void> _logout() async {
    if (_loggingOut) return;

    setState(() => _loggingOut = true);

    try {
      await SessionStore.logout();

      if (!mounted) return;

      setState(() {
        _isLoggedIn = false;
        _memberName = 'bạn';
        _tab = 0;
        _loggingOut = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đã đăng xuất khỏi LUMI.')),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _loggingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể đăng xuất. Vui lòng thử lại.')),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature đang được phát triển.')));
  }

  void _requireLogin(String action) {
    if (_loadingSession) return;

    if (_isLoggedIn) {
      _showComingSoon(action);
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ivory,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 30, 26, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A little more personal.',
                  style: LumiStyle.heading(size: 36),
                ),
                const SizedBox(height: 12),
                Text(
                  'Đăng nhập để $action. Bạn vẫn có thể '
                  'khám phá dịch vụ và mỹ phẩm LUMI '
                  'mà không cần tài khoản.',
                  style: LumiStyle.body(size: 15),
                ),
                const SizedBox(height: 24),
                _filledButton('ĐĂNG NHẬP', () {
                  Navigator.of(sheetContext).pop();
                  context.push('/login').then((_) async {
                    if (!mounted) return;
                    await _loadSession();
                    if (!mounted) return;
                    // Checkout cần Login nhưng giỏ hàng vẫn còn nguyên.
                    // Trở lại giỏ để khách xem lại trước khi tạo đơn hàng.
                    if (action == 'thanh toán đơn hàng' && _isLoggedIn) {
                      setState(() => _tab = 2);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) LumiShopCatalog.openActiveCart?.call();
                      });
                    }
                  });
                }),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                    },
                    child: Text(
                      'TIẾP TỤC KHÁM PHÁ',
                      style: GoogleFonts.dmSans(
                        color: _plum,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filledButton(String label, VoidCallback? onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _plum,
          foregroundColor: _ivory,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _image(String path, {double? height}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset(
        path,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height ?? 200,
            color: const Color(0xFFEADBD8),
            alignment: Alignment.center,
            child: const Icon(Icons.spa_outlined, size: 36, color: _rose),
          );
        },
      ),
    );
  }

  // ignore: unused_element
  Widget _sectionHeading(String eyebrow, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 11,
            letterSpacing: 2.1,
            fontWeight: FontWeight.w600,
            color: _rose,
          ),
        ),
        const SizedBox(height: 7),
        Text(title, style: LumiStyle.heading(size: 36)),
      ],
    );
  }

  void _openSearch() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFFFFF8EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LumiSearchSheet(
        servicesFuture: _servicesFuture,
        productsFuture: _productsFuture,
        onResultSelected: (isService) {
          if (mounted) setState(() => _tab = isService ? 1 : 2);
        },
      ),
    );
  }

  // No fake notifications: an empty state until a real source is connected.
  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  // Home V3: Figma Make layout + editorial featured banner.
  String? _homeImageUrl(Map<String, dynamic> item) {
    final urls = item['imageUrls'];
    if (urls is List) {
      for (final url in urls) {
        if (url is String && url.trim().isNotEmpty) return url.trim();
      }
    }
    final url = item['imageUrl'];
    return url is String && url.trim().isNotEmpty ? url.trim() : null;
  }

  Widget _homePhoto(Map<String, dynamic> item, {required double height}) {
    final url = _homeImageUrl(item);
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: url == null
            ? const ColoredBox(
                color: Color(0xFFFBE7DC),
                child: Center(
                  child: Icon(Icons.spa_outlined, color: Color(0xFFA5553E)),
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                errorBuilder: (context, error, stack) => const ColoredBox(
                  color: Color(0xFFFBE7DC),
                  child: Center(
                    child: Icon(Icons.image_outlined, color: Color(0xFFA5553E)),
                  ),
                ),
              ),
      ),
    );
  }

  void _openJournal() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LumiJournalScreen()));
  }

  Widget _home() {
    const blush = Color(0xFFFBE7DC);
    const babyBlue = Color(0xFFE8F2F6);
    const rose = Color(0xFFA5553E);
    const textColor = Color(0xFF403735);

    Widget heading(String title, String action, VoidCallback onTap) => Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.dmSans(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            action,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: rose,
            ),
          ),
        ),
      ],
    );

    Widget category(
      IconData icon,
      String label,
      Color color,
      VoidCallback onTap,
    ) => Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: textColor, size: 27),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );

    return RefreshIndicator(
      color: rose,
      onRefresh: () async {
        final services = _fetchServices();
        final products = _fetchProducts();
        setState(() {
          _servicesFuture = services;
          _productsFuture = products;
        });
        await Future.wait([
          services.then<void>((_) {}, onError: (Object _) {}),
          products.then<void>((_) {}, onError: (Object _) {}),
        ]);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
        children: [
          Text(
            _isLoggedIn ? 'Chào $_memberName' : 'Chào bạn',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Chăm sóc theo cách của bạn.',
            style: GoogleFonts.dmSans(
              fontSize: 15,
              color: textColor.withValues(alpha: .78),
            ),
          ),
          const SizedBox(height: 20),
          _LumiFirebaseBannerCarousel(
            onNavigate: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: _openSearch,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFEBDDE0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: rose, size: 25),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tìm dịch vụ, mỹ phẩm',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        color: textColor.withValues(alpha: .75),
                      ),
                    ),
                  ),
                  const Icon(Icons.tune_rounded, color: textColor, size: 23),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SizedBox(height: 26),
          heading('Danh mục', 'Xem tất cả', () => setState(() => _tab = 1)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              category(
                Icons.face_retouching_natural_outlined,
                'Chăm da',
                blush,
                () => setState(() => _tab = 1),
              ),
              const SizedBox(width: 9),
              category(
                Icons.spa_outlined,
                'Massage',
                babyBlue,
                () => setState(() => _tab = 1),
              ),
              const SizedBox(width: 9),
              category(
                Icons.auto_awesome_outlined,
                'Mỹ phẩm',
                blush,
                () => setState(() => _tab = 2),
              ),
              const SizedBox(width: 9),
              category(
                Icons.calendar_month_outlined,
                'Đặt lịch',
                babyBlue,
                () => _requireLogin('đặt lịch chăm sóc'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          heading(
            'Liệu trình nổi bật',
            'Xem tất cả',
            () => setState(() => _tab = 1),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _servicesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _loadingPanel('Đang tải liệu trình...');
              }
              if (snapshot.hasError) {
                return _errorPanel(
                  'Chưa tải được liệu trình.',
                  () => setState(() => _servicesFuture = _fetchServices()),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return _loadingPanel('Chưa có liệu trình nào.');
              }
              return SizedBox(
                height:
                    320 +
                    (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(
                          0.0,
                          100.0,
                        ) *
                        5,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length > 6 ? 6 : items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () => setState(() => _tab = 1),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 190,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _homePhoto(item, height: 150),
                            const SizedBox(height: 14),
                            Text(
                              item['name']?.toString() ?? 'Liệu trình LUMI',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 18,
                                height: 1.2,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${item['durationMinutes'] ?? '—'} phút',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _priceVnd(item['price']),
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          heading(
            'Mỹ phẩm tại LUMI',
            'Cửa hàng',
            () => setState(() => _tab = 2),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _loadingPanel('Đang tải mỹ phẩm...');
              }
              if (snapshot.hasError) {
                return _errorPanel(
                  'Chưa tải được mỹ phẩm.',
                  () => setState(() => _productsFuture = _fetchProducts()),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) return _loadingPanel('Chưa có mỹ phẩm nào.');
              return SizedBox(
                height:
                    290 +
                    (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(
                          0.0,
                          100.0,
                        ) *
                        5,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length > 6 ? 6 : items.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () => setState(() => _tab = 2),
                      borderRadius: BorderRadius.circular(19),
                      child: Container(
                        width: 180,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(color: const Color(0xFFEDDFE2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _homePhoto(item, height: 142),
                            const SizedBox(height: 14),
                            Text(
                              item['name']?.toString() ?? 'Mỹ phẩm LUMI',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _priceVnd(item['price']),
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: rose,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          Material(
            color: const Color(0xFFE8F2F6),
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _openJournal,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    const Icon(
                      Icons.menu_book_outlined,
                      size: 28,
                      color: Color(0xFF403735),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Góc chăm sóc da',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF403735),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: blush,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dịch vụ tại LUMI',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: rose,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Đặt lịch chăm sóc',
                  style: GoogleFonts.dmSans(
                    fontSize: 29,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Chọn liệu trình và thời gian phù hợp.',
                  style: GoogleFonts.dmSans(fontSize: 15, color: textColor),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => _requireLogin('đặt lịch tại LUMI'),
                    style: FilledButton.styleFrom(
                      backgroundColor: LumiStyle.peach,
                      foregroundColor: LumiStyle.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      'Đặt lịch ngay',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _eyebrow(String label) => Text(
    label,
    style: GoogleFonts.dmSans(
      color: _pink,
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.7,
    ),
  );

  // ignore: unused_element
  Widget _heroSlide(
    String asset,
    String title,
    String eyebrow,
    String action,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: _softPink),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    const Color(0xFF312831).withValues(alpha: .76),
                  ],
                  stops: const [.24, 1],
                ),
              ),
            ),
            Positioned(
              left: 22,
              right: 20,
              bottom: 23,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFFE2E9),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    title,
                    style: GoogleFonts.cormorantGaramond(
                      color: Colors.white,
                      fontSize: 39,
                      height: .98,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    height: 43,
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: _pink,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 17),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            action,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              letterSpacing: .7,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.arrow_forward, size: 17),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _quickAction(
    IconData icon,
    String label,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 66,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: fg, size: 26),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _ink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _homeSectionTitle(
    String eyebrow,
    String title,
    String action,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow(eyebrow),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              TextButton(
                onPressed: onTap,
                child: Text(
                  action,
                  style: GoogleFonts.dmSans(
                    color: _pink,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _loadingPanel(String message) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFFBE7DC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        message,
        style: GoogleFonts.dmSans(color: _ink, fontSize: 13),
      ),
    ),
  );

  Widget _errorPanel(String message, VoidCallback retry) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFBE7DC),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.dmSans(color: _ink, fontSize: 12),
            ),
          ),
          TextButton(onPressed: retry, child: const Text('THỬ LẠI')),
        ],
      ),
    ),
  );

  // ignore: unused_element
  void _showJournal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _canvas,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 28, 25, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _eyebrow('LUMI JOURNAL · BÀI VIẾT MẪU'),
              const SizedBox(height: 10),
              Text(
                'Một làn da đẹp bắt đầu từ sự dịu dàng.',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Chăm sóc da không nhất thiết phải phức tạp. '
                'Hãy làm sạch nhẹ nhàng, dưỡng ẩm phù hợp và '
                'sử dụng kem chống nắng mỗi ngày. '
                'Dành thời gian nghỉ ngơi cũng là một phần của hành trình chăm sóc bản thân.',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  height: 1.6,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Nội dung minh họa giao diện; mục tin tức sẽ kết nối CMS sau.',
                style: GoogleFonts.dmSans(fontSize: 11, color: _blue),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(backgroundColor: _pink),
                  child: const Text('ĐÓNG'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    return LumiCatalogRepository.fetchProducts();
  }

  Future<List<Map<String, dynamic>>> _fetchServices() async {
    return LumiCatalogRepository.fetchServices();
  }

  Future<void> _refreshServices() async {
    final future = _fetchServices();
    setState(() => _servicesFuture = future);
    try {
      await future;
    } catch (_) {
      // FutureBuilder displays the error and retry action.
    }
  }

  String _priceVnd(dynamic raw) {
    final value = (raw as num?)?.toInt() ?? 0;
    final digits = value.toString();
    return '${digits.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';
  }

  // ignore: unused_element
  Widget _serviceTile(String number, Map<String, dynamic> service) {
    final name = service['name']?.toString() ?? 'Dịch vụ LUMI';
    final description = service['description']?.toString() ?? '';
    final duration = service['durationMinutes']?.toString() ?? '—';
    final price = _priceVnd(service['price']);

    return Column(
      children: [
        const Divider(height: 25),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(number, style: GoogleFonts.dmSans(fontSize: 12, color: _rose)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: LumiStyle.heading(size: 26)),
                  const SizedBox(height: 4),
                  Text(description, style: LumiStyle.body(size: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '$duration phút  ·  $price',
                    style: GoogleFonts.dmSans(
                      color: _plum,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _spa() => LumiSpaCatalog(
    servicesFuture: _servicesFuture,
    onRefresh: _refreshServices,
    onBook: (service) async {
      final booked = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => LumiBookingScreen(service: service),
        ),
      );
      if (booked == true && mounted) {
        setState(() => _tab = 3);
      }
    },
  );

  Widget _shop() {
    return LumiShopCatalog(
      onCheckout: () => _requireLogin('thanh toán đơn hàng'),
    );
  }

  Widget _protectedPage({
    required String eyebrow,
    required String title,
    required String description,
    required IconData icon,
    required String action,
  }) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 45, color: _rose),
            const SizedBox(height: 22),
            Text(
              eyebrow,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: _rose,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: LumiStyle.heading(size: 41),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: LumiStyle.body(size: 15),
            ),
            const SizedBox(height: 28),
            _filledButton('ĐĂNG NHẬP', () => _requireLogin(action)),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _memberAppointments() {
    return _protectedPage(
      eyebrow: 'LỊCH HẸN',
      title: 'Khoảnh khắc\ndành cho bạn.',
      description:
          'Bạn đã đăng nhập. Chức năng xem và '
          'quản lý lịch hẹn sẽ được bổ sung sau.',
      icon: Icons.calendar_month_outlined,
      action: 'quản lý lịch hẹn',
    );
  }

  Widget _profile() => ProfileScreen(
    isLoggedIn: _isLoggedIn,
    isLoggingOut: _loggingOut,
    onLogin: () {
      context.push('/login').then((_) {
        if (mounted) _loadSession();
      });
    },
    onLogout: _logout,
    onAppointments: () => setState(() => _tab = 3),
    onSupport: () => _showComingSoon('Hỗ trợ và liên hệ'),
  );

  Widget _luxuryNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final selected = _tab == index;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (_tab != index) setState(() => _tab = index);
            },
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                color: selected ? LumiStyle.peach : Colors.transparent,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    selected ? selectedIcon : icon,
                    size: 23,
                    color: LumiStyle.ink,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: LumiStyle.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMenuMembership() async {
    if (!_isLoggedIn) {
      await context.push('/login');
      if (!mounted) return;
      await _loadSession();
      if (!mounted || !_isLoggedIn) return;
    }
    if (!mounted) return;
    context.push('/membership');
  }

  Widget _buildLumiMenu() {
    const ink = Color(0xFF403735);
    const muted = Color(0xFF5F5550);
    const cream = Color(0xFFFFF8EF);
    const peach = Color(0xFFFBE7DC);
    const accent = Color(0xFFA5553E);

    TextStyle type(double size, {bool bold = false, Color color = ink}) =>
        GoogleFonts.dmSans(
          fontSize: size,
          height: 1.4,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          letterSpacing: 0,
          wordSpacing: 0,
          color: color,
        );

    void open(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    Widget item(IconData icon, String title, VoidCallback action) => ListTile(
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: ink, size: 25),
      title: Text(title, style: type(18, bold: true)),
      trailing: const Icon(Icons.chevron_right_rounded, color: muted, size: 22),
      onTap: () => open(action),
    );

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.88,
      backgroundColor: cream,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 14, 12, 20),
              child: Row(
                children: [
                  Expanded(child: Text('LUMI', style: type(30, bold: true))),
                  IconButton(
                    tooltip: 'Đóng menu',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: ink),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    backgroundColor: Color(0xFFEAF3F7),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: ink,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isLoggedIn ? _memberName : 'Chào bạn',
                      style: type(22, bold: true),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: peach,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => open(() {
                    _openMenuMembership();
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          color: accent,
                          size: 30,
                        ),
                        const SizedBox(height: 12),
                        Text('Thành viên LUMI', style: type(22, bold: true)),

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Xem quyền lợi',
                                style: type(17, bold: true, color: accent),
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: accent,
                              size: 22,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            item(Icons.auto_stories_outlined, 'Góc chăm sóc da', _openJournal),
            item(
              Icons.notifications_none_rounded,
              'Thông báo',
              _openNotifications,
            ),
            item(Icons.workspace_premium_outlined, 'Thẻ thành viên', () {
              _openMenuMembership();
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Divider(color: Color(0xFFEADFD5)),
            ),
            item(Icons.settings_outlined, 'Cài đặt', () {
              context.push('/settings');
            }),
            if (!_isLoggedIn)
              item(Icons.login_rounded, 'Đăng nhập / Đăng ký', () {
                context.push('/login').then((_) {
                  if (mounted) _loadSession();
                });
              }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingSession) {
      return const Scaffold(
        backgroundColor: _ivory,
        body: Center(child: CircularProgressIndicator(color: _rose)),
      );
    }

    final pages = [
      _home(),
      _spa(),
      _shop(),
      LumiAppointmentsScreen(
        isLoggedIn: _isLoggedIn,
        onExploreServices: () => setState(() => _tab = 1),
        onLogin: () => _requireLogin('xem và quản lý lịch hẹn'),
      ),
      _profile(),
    ];

    return Scaffold(
      drawer: _buildLumiMenu(),
      backgroundColor: _canvas,
      appBar: _tab == 4
          ? null
          : AppBar(
              backgroundColor: _canvas,
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 60,
              leading: Builder(
                builder: (drawerContext) => IconButton(
                  tooltip: 'Mở menu',
                  icon: const Icon(Icons.menu_rounded, color: _ink),
                  onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                ),
              ),
              title: Text(
                'LUMI',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 35,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              actions: [
                // LUMI V4.1: Context-aware action for each tab.
                if (_tab == 0)
                  IconButton(
                    tooltip: 'Tìm kiếm',
                    onPressed: _openSearch,
                    icon: const Icon(
                      Icons.search_rounded,
                      color: _plum,
                      size: 25,
                    ),
                  ),

                if (_tab == 1)
                  IconButton(
                    tooltip: 'Lịch hẹn',
                    onPressed: () => setState(() => _tab = 3),
                    icon: const Icon(
                      Icons.event_available_outlined,
                      color: _plum,
                      size: 25,
                    ),
                  ),

                if (_tab == 2)
                  IconButton(
                    tooltip: 'Giỏ hàng',
                    onPressed: () {
                      final openCart = LumiShopCatalog.openActiveCart;
                      if (openCart != null) {
                        openCart();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Giỏ hàng đang được tải.'),
                          ),
                        );
                      }
                    },
                    icon: ValueListenableBuilder<int>(
                      valueListenable: LumiShopCatalog.cartQuantityNotifier,
                      builder: (context, quantity, _) => Badge(
                        isLabelVisible: quantity > 0,
                        backgroundColor: const Color(0xFFA5553E),
                        textColor: Colors.white,
                        label: Text(quantity > 99 ? '99+' : '$quantity'),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: _plum,
                          size: 25,
                        ),
                      ),
                    ),
                  ),

                if (_tab == 3)
                  IconButton(
                    tooltip: 'Tài khoản',
                    onPressed: () => setState(() => _tab = 4),
                    icon: const Icon(
                      Icons.person_outline_rounded,
                      color: _plum,
                      size: 25,
                    ),
                  ),

                if (_tab == 4 && !_isLoggedIn)
                  IconButton(
                    tooltip: 'Đăng nhập',
                    onPressed: () {
                      context.push('/login').then((_) {
                        if (mounted) _loadSession();
                      });
                    },
                    icon: const Icon(
                      Icons.login_rounded,
                      color: _plum,
                      size: 25,
                    ),
                  ),

                IconButton(
                  tooltip: 'Thông báo',
                  onPressed: _openNotifications,
                  icon: _unreadNotifCount > 0
                      ? Badge.count(
                          count: _unreadNotifCount,
                          backgroundColor: _rose,
                          textColor: Colors.white,
                          child: const Icon(
                            Icons.notifications_active_rounded,
                            color: _plum,
                            size: 26,
                          ),
                        )
                      : const Icon(
                          Icons.notifications_none_rounded,
                          color: _plum,
                          size: 26,
                        ),
                ),

                const SizedBox(width: 10),
              ],
            ),
      body: pages[_tab],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 7, 18, 12),
          child: Container(
            height: 76,
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: LumiStyle.surface,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: _plum.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _luxuryNavItem(0, Icons.home_outlined, Icons.home, 'Trang chủ'),
                _luxuryNavItem(1, Icons.spa_outlined, Icons.spa, 'Spa'),
                _luxuryNavItem(
                  2,
                  Icons.shopping_bag_outlined,
                  Icons.shopping_bag,
                  'Cửa hàng',
                ),
                _luxuryNavItem(
                  3,
                  Icons.calendar_month_outlined,
                  Icons.calendar_month,
                  'Lịch hẹn',
                ),
                _luxuryNavItem(4, Icons.person_outline, Icons.person, 'Tôi'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Owns its TextEditingController for the entire sheet lifecycle.
class _LumiSearchSheet extends StatefulWidget {
  const _LumiSearchSheet({
    required this.servicesFuture,
    required this.productsFuture,
    required this.onResultSelected,
  });

  final Future<List<Map<String, dynamic>>> servicesFuture;
  final Future<List<Map<String, dynamic>>> productsFuture;
  final ValueChanged<bool> onResultSelected;

  @override
  State<_LumiSearchSheet> createState() => _LumiSearchSheetState();
}

class _LumiSearchSheetState extends State<_LumiSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  late final Future<List<List<Map<String, dynamic>>>> _resultsFuture;
  String _query = '';
  String _filter = 'Tất cả';

  @override
  void initState() {
    super.initState();
    _resultsFuture = Future.wait([
      widget.servicesFuture.catchError((Object _) => <Map<String, dynamic>>[]),
      widget.productsFuture.catchError((Object _) => <Map<String, dynamic>>[]),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 14, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tìm kiếm',
                      style: GoogleFonts.dmSans(
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF403735),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value.trim()),
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  color: const Color(0xFF403735),
                ),
                decoration: InputDecoration(
                  hintText: 'Nhập tên dịch vụ hoặc mỹ phẩm...',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: Color(0xFFA5553E),
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Xóa tìm kiếm',
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(color: Color(0xFFEADFD5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: const BorderSide(
                      color: Color(0xFFA5553E),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: ['Tất cả', 'Dịch vụ', 'Mỹ phẩm']
                    .map(
                      (label) => Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: ChoiceChip(
                          label: Text(label),
                          selected: _filter == label,
                          selectedColor: const Color(0xFFFBE7DC),
                          backgroundColor: const Color(0xFFE8F2F6),
                          labelStyle: GoogleFonts.dmSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF403735),
                          ),
                          onSelected: (_) => setState(() => _filter = label),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<List<Map<String, dynamic>>>>(
                future: _resultsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFA5553E),
                      ),
                    );
                  }
                  final services = snapshot.data![0];
                  final products = snapshot.data![1];
                  final all = <({Map<String, dynamic> item, bool service})>[
                    if (_filter != 'Mỹ phẩm')
                      ...services.map((e) => (item: e, service: true)),
                    if (_filter != 'Dịch vụ')
                      ...products.map((e) => (item: e, service: false)),
                  ];
                  final normalized = _query.toLowerCase();
                  final matches = all.where((entry) {
                    if (normalized.isEmpty) return true;
                    final name = entry.item['name']?.toString() ?? '';
                    final description =
                        entry.item['description']?.toString() ?? '';
                    return '$name $description'.toLowerCase().contains(
                      normalized,
                    );
                  }).toList();
                  if (matches.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(28),
                        child: Text(
                          'Chưa tìm thấy kết quả phù hợp.\nThử từ khóa khác nhé!',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            height: 1.5,
                            color: const Color(0xFF756863),
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final entry = matches[index];
                      return Material(
                        color: index.isEven
                            ? const Color(0xFFFBE7DC)
                            : const Color(0xFFE8F2F6),
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 5,
                          ),
                          leading: Icon(
                            entry.service
                                ? Icons.spa_outlined
                                : Icons.water_drop_outlined,
                            color: const Color(0xFFA5553E),
                          ),
                          title: Text(
                            entry.item['name']?.toString() ?? 'LUMI',
                            style: GoogleFonts.dmSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF403735),
                            ),
                          ),
                          subtitle: Text(
                            entry.service ? 'Dịch vụ' : 'Mỹ phẩm',
                            style: GoogleFonts.dmSans(fontSize: 13),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onResultSelected(entry.service);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// LUMI Home: Firestore-powered banners. Does not modify bottom navigation.

class _LumiFirebaseBannerCarousel extends StatefulWidget {
  const _LumiFirebaseBannerCarousel({required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<_LumiFirebaseBannerCarousel> createState() =>
      _LumiFirebaseBannerCarouselState();
}

class _LumiFirebaseBannerCarouselState
    extends State<_LumiFirebaseBannerCarousel> {
  final PageController _controller = PageController();
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _stream = FirebaseFirestore.instance
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _notice(String message, {bool retry = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              height: 1.5,
              color: LumiStyle.ink,
            ),
          ),
          if (retry) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(_connect),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _notice('Chưa tải được banner.', retry: true);
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 240,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data!.docs.toList();
        docs.sort((a, b) {
          final x = a.data()['sortOrder'];
          final y = b.data()['sortOrder'];
          return (x is num ? x : 999).compareTo(y is num ? y : 999);
        });

        if (docs.isEmpty) return const SizedBox.shrink();

        final selected = _page.clamp(0, docs.length - 1);
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        final height = 300.0 + (scale > 1 ? (scale - 1) * 200 : 0);

        return Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                controller: _controller,
                itemCount: docs.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final title = (data['title'] ?? '').toString().trim();
                  final image = (data['imageUrl'] ?? '').toString().trim();
                  final target = (data['targetType'] ?? '').toString();
                  final int? tab = target == 'products'
                      ? 2
                      : target == 'services'
                      ? 1
                      : null;

                  return _banner(title: title, image: image, tab: tab);
                },
              ),
            ),
            if (docs.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  docs.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 6,
                    width: index == selected ? 20 : 6,
                    decoration: BoxDecoration(
                      color: index == selected
                          ? LumiStyle.rose
                          : LumiStyle.line,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _banner({
    required String title,
    required String image,
    required int? tab,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (image.isNotEmpty)
            Image.network(
              image,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              excludeFromSemantics: true,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const ColoredBox(
                  color: Color(0xFFFBE7DC),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                final uri = Uri.tryParse(image);
                debugPrint(
                  'LUMI_BANNER: scheme=${uri?.scheme}, '
                  'asset=${image.startsWith("assets/")}, '
                  'error=${error.runtimeType}',
                );
                if (error is NetworkImageLoadException) {
                  debugPrint('LUMI_BANNER: HTTP ${error.statusCode}');
                }
                return _imageUnavailable();
              },
            )
          else
            _imageUnavailable(),

          // Vùng nền đủ sáng để tiêu đề dễ đọc trên ảnh Firebase.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFFFFF8EF),
                  Color(0xF2FFF8EF),
                  Color(0x1AFFF8EF),
                ],
                stops: [0, 0.38, 1],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.72,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 26,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.4,
                          color: LumiStyle.ink,
                        ),
                      ),
                    if (tab != null) ...[
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: () => widget.onNavigate(tab),
                        style: FilledButton.styleFrom(
                          backgroundColor: LumiStyle.peach,
                          foregroundColor: LumiStyle.ink,
                          minimumSize: const Size(48, 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(
                          tab == 2 ? 'Xem mỹ phẩm →' : 'Xem dịch vụ →',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageUnavailable() => const ColoredBox(
    color: Color(0xFFE8F2F6),
    child: Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Icon(
          Icons.broken_image_outlined,
          color: Color(0xFF557C90),
          size: 36,
        ),
      ),
    ),
  );
}
