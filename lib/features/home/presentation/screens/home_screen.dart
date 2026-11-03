import '../../../../core/widgets/lumi_interactions.dart';
import '../../../../core/widgets/lumi_catalog_image.dart';
import '../../../../core/theme/lumi_adaptive.dart';
import 'lumi_journal_media.dart';

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import 'lumi_booking_screen.dart';
import 'spa_catalog.dart';
import 'lumi_shop_catalog.dart';
import 'lumi_checkout_screen.dart';
import 'notifications_screen.dart';
import 'lumi_journal_screen.dart';
import 'lumi_my_orders_screen.dart';

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
        backgroundColor: LumiAdaptive.color(
          const Color(0xFFFFF8EF),
          surface: true,
        ),
        surfaceTintColor: Colors.transparent,
        dividerColor: LumiAdaptive.color(const Color(0xFFF0E4E6)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: LumiAdaptive.color(Color(0xFFFBE7DC), surface: true),
            shape: BoxShape.circle,
          ),
          child: Icon(
            type == 'appointment'
                ? Icons.calendar_month_outlined
                : type == 'order'
                ? Icons.shopping_bag_outlined
                : Icons.notifications_active_outlined,
            color: LumiAdaptive.color(_rose),
            size: 22,
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              LumiAdaptive.text(title),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: LumiAdaptive.color(_plum),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              LumiAdaptive.text(message),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  fontSize: 12.5,
                  color: LumiAdaptive.color(_muted),
                  height: 1.3,
                ),
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
              LumiAdaptive.text('XEM'),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  fontWeight: FontWeight.w700,
                  color: LumiAdaptive.color(_rose),
                  fontSize: 13,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 18,
              color: LumiAdaptive.color(_muted),
            ),
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
        SnackBar(
          content: Text(LumiAdaptive.text('Bạn đã đăng xuất khỏi LUMI.')),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() => _loggingOut = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LumiAdaptive.text('Không thể đăng xuất. Vui lòng thử lại.'),
          ),
        ),
      );
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LumiAdaptive.text('$feature đang được phát triển.')),
      ),
    );
  }

  void _requireLogin(String action) {
    if (_loadingSession) return;

    if (_isLoggedIn) {
      if (action == 'Thanh toán đơn hàng') {
        _openCheckout();
      } else {
        _showComingSoon(action);
      }
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: LumiAdaptive.color(_ivory, surface: true),
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
                  LumiAdaptive.text('A little more personal.'),
                  style: LumiAdaptive.style(LumiStyle.heading(size: 36)),
                ),
                const SizedBox(height: 12),
                Text(
                  LumiAdaptive.text(
                    'Đăng nhập để $action. Bạn vẫn có thể '
                    'khám phá dịch vụ và mỹ phẩm LUMI '
                    'mà không cần tài khoản.',
                  ),
                  style: LumiAdaptive.style(LumiStyle.body(size: 15)),
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
                      LumiAdaptive.text('TIẾP TỤC KHÁM PHÁ'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          color: LumiAdaptive.color(_plum),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
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
        style: LumiAdaptive.style(
          FilledButton.styleFrom(
            backgroundColor: LumiAdaptive.color(_plum, surface: true),
            foregroundColor: LumiAdaptive.color(_ivory),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        child: Text(
          LumiAdaptive.text(label),
          style: LumiAdaptive.style(
            GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  void _openSearch() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: LumiAdaptive.color(
        const Color(0xFFFFF8EF),
        surface: true,
      ),
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

  // Opens the existing notifications screen.
  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  // Shared catalog image presentation.
  Widget _homePhoto(Map<String, dynamic> item, {required double height}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: LumiCatalogImage(item: item, height: height),
      );

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
            LumiAdaptive.text(title),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 21,
                fontWeight: FontWeight.w700,
                color: LumiAdaptive.color(textColor),
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: onTap,
          child: Text(
            LumiAdaptive.text(action),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: LumiAdaptive.color(rose),
              ),
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
              decoration: BoxDecoration(
                color: LumiAdaptive.color(color, surface: true),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: LumiAdaptive.color(textColor), size: 27),
            ),
            const SizedBox(height: 9),
            Text(
              LumiAdaptive.text(label),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: LumiAdaptive.color(textColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return RefreshIndicator(
      color: LumiAdaptive.color(rose, surface: true),
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
            LumiAdaptive.text(_isLoggedIn ? 'Chào $_memberName' : 'Chào bạn'),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: LumiAdaptive.color(textColor),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            LumiAdaptive.text('Chăm sóc theo cách của bạn.'),
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 15,
                color: LumiAdaptive.color(textColor.withValues(alpha: .78)),
              ),
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
                color: LumiAdaptive.color(Colors.white, surface: true),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: LumiAdaptive.color(const Color(0xFFEBDDE0)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: LumiAdaptive.color(rose), size: 25),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      LumiAdaptive.text('Tìm dịch vụ, mỹ phẩm'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 15,
                          color: LumiAdaptive.color(
                            textColor.withValues(alpha: .75),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.tune_rounded,
                    color: LumiAdaptive.color(textColor),
                    size: 23,
                  ),
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
                          color: LumiAdaptive.color(
                            Colors.white,
                            surface: true,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _homePhoto(item, height: 150),
                            const SizedBox(height: 14),
                            Text(
                              LumiAdaptive.text(
                                item['name']?.toString() ?? 'Liệu trình LUMI',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: LumiAdaptive.style(
                                GoogleFonts.dmSans(
                                  fontSize: 18,
                                  height: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: LumiAdaptive.color(textColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              LumiAdaptive.text(
                                '${item['durationMinutes'] ?? '—'} phút',
                              ),
                              style: LumiAdaptive.style(
                                GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: LumiAdaptive.color(textColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              LumiAdaptive.text(_priceVnd(item['price'])),
                              style: LumiAdaptive.style(
                                GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: LumiAdaptive.color(textColor),
                                ),
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
                          color: LumiAdaptive.color(
                            Colors.white,
                            surface: true,
                          ),
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: LumiAdaptive.color(const Color(0xFFEDDFE2)),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _homePhoto(item, height: 142),
                            const SizedBox(height: 14),
                            Text(
                              LumiAdaptive.text(
                                item['name']?.toString() ?? 'Mỹ phẩm LUMI',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: LumiAdaptive.style(
                                GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: LumiAdaptive.color(textColor),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              LumiAdaptive.text(_priceVnd(item['price'])),
                              style: LumiAdaptive.style(
                                GoogleFonts.dmSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: LumiAdaptive.color(rose),
                                ),
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
          LumiJournalFeature(onTap: _openJournal),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(21),
            decoration: BoxDecoration(
              color: LumiAdaptive.color(blush, surface: true),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LumiAdaptive.text('Dịch vụ tại LUMI'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      fontSize: 14,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: LumiAdaptive.color(rose),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  LumiAdaptive.text('Đặt lịch chăm sóc'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      fontSize: 29,
                      fontWeight: FontWeight.w700,
                      color: LumiAdaptive.color(textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  LumiAdaptive.text('Chọn liệu trình và thời gian phù hợp.'),
                  style: LumiAdaptive.style(
                    GoogleFonts.dmSans(
                      fontSize: 15,
                      color: LumiAdaptive.color(textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => setState(() => _tab = 1),
                    style: LumiAdaptive.style(
                      FilledButton.styleFrom(
                        backgroundColor: LumiAdaptive.color(
                          LumiStyle.peach,
                          surface: true,
                        ),
                        foregroundColor: LumiAdaptive.color(LumiStyle.ink),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                    child: Text(
                      LumiAdaptive.text('Đặt lịch ngay'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _loadingPanel(String message) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Container(
      height: 100,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: LumiAdaptive.color(const Color(0xFFFBE7DC), surface: true),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(
        LumiAdaptive.text(message),
        style: LumiAdaptive.style(
          GoogleFonts.dmSans(color: LumiAdaptive.color(_ink), fontSize: 13),
        ),
      ),
    ),
  );

  Widget _errorPanel(String message, VoidCallback retry) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: LumiAdaptive.color(const Color(0xFFFBE7DC), surface: true),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              LumiAdaptive.text(message),
              style: LumiAdaptive.style(
                GoogleFonts.dmSans(
                  color: LumiAdaptive.color(_ink),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: retry,
            child: Text(LumiAdaptive.text('THỬ LẠI')),
          ),
        ],
      ),
    ),
  );

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

  void _openCheckout() {
    final cartItems = LumiShopCatalog.currentCart;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LumiCheckoutScreen(cartItems: cartItems),
      ),
    );
  }

  Widget _shop() {
    return LumiShopCatalog(
      onCheckout: () => _requireLogin('Thanh toán đơn hàng'),
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
    onOrders: () {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LumiMyOrdersScreen()),
      );
    },
  );

  Widget _luxuryNavItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final selected = _tab == index;
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? const Color(0xFF6C5143) : const Color(0xFFF8D5C2);
    final foreground = colors.onSurface;
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: LumiAdaptive.text(label),
        child: LumiPressFeedback(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                if (_tab != index) {
                  setState(() => _tab = index);
                }
              },
              borderRadius: BorderRadius.circular(27),
              hoverColor: colors.primary.withValues(alpha: 0.10),
              splashColor: colors.primary.withValues(alpha: 0.18),
              child: AnimatedContainer(
                duration: Duration(milliseconds: reduce ? 0 : 260),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                decoration: BoxDecoration(
                  color: selected ? fill : Colors.transparent,
                  borderRadius: BorderRadius.circular(27),
                  border: Border.all(
                    color: selected
                        ? colors.primary.withValues(alpha: 0.25)
                        : Colors.transparent,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(
                              alpha: dark ? 0.18 : 0.16,
                            ),
                            blurRadius: 13,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: selected ? 1.10 : 1,
                      duration: Duration(milliseconds: reduce ? 0 : 220),
                      child: Icon(
                        selected ? selectedIcon : icon,
                        size: 23,
                        color: selected ? colors.primary : foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Text(
                        LumiAdaptive.text(label),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: foreground,
                        ),
                      ),
                    ),
                  ],
                ),
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
          color: LumiAdaptive.color(color),
        );

    void open(VoidCallback action) {
      Navigator.of(context).pop();
      action();
    }

    Widget item(IconData icon, String title, VoidCallback action) => ListTile(
      minVerticalPadding: 14,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(icon, color: LumiAdaptive.color(ink), size: 25),
      title: Text(
        LumiAdaptive.text(title),
        style: LumiAdaptive.style(type(18, bold: true)),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: LumiAdaptive.color(muted),
        size: 22,
      ),
      onTap: () => open(action),
    );

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.88,
      backgroundColor: LumiAdaptive.color(cream, surface: true),
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
                  Expanded(
                    child: Text(
                      LumiAdaptive.text('LUMI'),
                      style: LumiAdaptive.style(type(30, bold: true)),
                    ),
                  ),
                  IconButton(
                    tooltip: LumiAdaptive.optionalText('Đóng menu'),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: LumiAdaptive.color(ink),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: LumiAdaptive.color(
                      Color(0xFFEAF3F7),
                      surface: true,
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: LumiAdaptive.color(ink),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      LumiAdaptive.text(_isLoggedIn ? _memberName : 'Chào bạn'),
                      style: LumiAdaptive.style(type(22, bold: true)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: LumiAdaptive.color(peach, surface: true),
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
                        Icon(
                          Icons.workspace_premium_outlined,
                          color: LumiAdaptive.color(accent),
                          size: 30,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          LumiAdaptive.text('Thành viên LUMI'),
                          style: LumiAdaptive.style(type(22, bold: true)),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                LumiAdaptive.text('Xem quyền lợi'),
                                style: LumiAdaptive.style(
                                  type(
                                    17,
                                    bold: true,
                                    color: LumiAdaptive.color(
                                      accent,
                                      surface: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: LumiAdaptive.color(accent),
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
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Divider(
                color: LumiAdaptive.color(Color(0xFFEADFD5), surface: true),
              ),
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
    LumiAdaptive.depend(context);
    if (_loadingSession) {
      return Scaffold(
        backgroundColor: LumiAdaptive.color(_ivory, surface: true),
        body: Center(
          child: CircularProgressIndicator(color: LumiAdaptive.color(_rose)),
        ),
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
      backgroundColor: LumiAdaptive.color(_canvas, surface: true),
      appBar: _tab == 4
          ? null
          : AppBar(
              backgroundColor: LumiAdaptive.color(_canvas, surface: true),
              elevation: 0,
              scrolledUnderElevation: 0,
              toolbarHeight: 60,
              leading: Builder(
                builder: (drawerContext) => IconButton(
                  tooltip: LumiAdaptive.optionalText('Mở menu'),
                  icon: Icon(
                    Icons.menu_rounded,
                    color: LumiAdaptive.color(_ink),
                  ),
                  onPressed: () => Scaffold.of(drawerContext).openDrawer(),
                ),
              ),
              title: Text(
                LumiAdaptive.text('LUMI'),
                style: LumiAdaptive.style(
                  GoogleFonts.cormorantGaramond(
                    fontSize: 35,
                    fontWeight: FontWeight.w600,
                    color: LumiAdaptive.color(_ink),
                  ),
                ),
              ),
              actions: [
                // LUMI V4.1: Context-aware action for each tab.
                if (_tab == 0)
                  IconButton(
                    tooltip: LumiAdaptive.optionalText('Tìm kiếm'),
                    onPressed: _openSearch,
                    icon: Icon(
                      Icons.search_rounded,
                      color: LumiAdaptive.color(_plum),
                      size: 25,
                    ),
                  ),

                if (_tab == 1)
                  IconButton(
                    tooltip: LumiAdaptive.optionalText('Lịch hẹn'),
                    onPressed: () => setState(() => _tab = 3),
                    icon: Icon(
                      Icons.event_available_outlined,
                      color: LumiAdaptive.color(_plum),
                      size: 25,
                    ),
                  ),

                if (_tab == 2)
                  IconButton(
                    tooltip: LumiAdaptive.optionalText('Giỏ hàng'),
                    onPressed: () {
                      final openCart = LumiShopCatalog.openActiveCart;
                      if (openCart != null) {
                        openCart();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              LumiAdaptive.text('Giỏ hàng đang được tải.'),
                            ),
                          ),
                        );
                      }
                    },
                    icon: ValueListenableBuilder<int>(
                      valueListenable: LumiShopCatalog.cartQuantityNotifier,
                      builder: (context, quantity, _) => Badge(
                        isLabelVisible: quantity > 0,
                        backgroundColor: LumiAdaptive.color(
                          const Color(0xFFA5553E),
                          surface: true,
                        ),
                        textColor: Colors.white,
                        label: Text(
                          LumiAdaptive.text(
                            quantity > 99 ? '99+' : '$quantity',
                          ),
                        ),
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          color: LumiAdaptive.color(_plum),
                          size: 25,
                        ),
                      ),
                    ),
                  ),

                if (_tab == 3)
                  IconButton(
                    tooltip: LumiAdaptive.optionalText('Tài khoản'),
                    onPressed: () => setState(() => _tab = 4),
                    icon: Icon(
                      Icons.person_outline_rounded,
                      color: LumiAdaptive.color(_plum),
                      size: 25,
                    ),
                  ),

                if (_tab == 4 && !_isLoggedIn)
                  IconButton(
                    tooltip: LumiAdaptive.optionalText('Đăng nhập'),
                    onPressed: () {
                      context.push('/login').then((_) {
                        if (mounted) _loadSession();
                      });
                    },
                    icon: Icon(
                      Icons.login_rounded,
                      color: LumiAdaptive.color(_plum),
                      size: 25,
                    ),
                  ),

                IconButton(
                  tooltip: LumiAdaptive.optionalText('Thông báo'),
                  onPressed: _openNotifications,
                  icon: _unreadNotifCount > 0
                      ? Badge.count(
                          count: _unreadNotifCount,
                          backgroundColor: LumiAdaptive.color(
                            _rose,
                            surface: true,
                          ),
                          textColor: Colors.white,
                          child: Icon(
                            Icons.notifications_active_rounded,
                            color: LumiAdaptive.color(_plum),
                            size: 26,
                          ),
                        )
                      : Icon(
                          Icons.notifications_none_rounded,
                          color: LumiAdaptive.color(_plum),
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
              color: LumiAdaptive.color(LumiStyle.surface, surface: true),
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: LumiAdaptive.color(
                    _plum.withValues(alpha: 0.08),
                    surface: true,
                  ),
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
    LumiAdaptive.depend(context);
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
                      LumiAdaptive.text('Tìm kiếm'),
                      style: LumiAdaptive.style(
                        GoogleFonts.dmSans(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: LumiAdaptive.color(const Color(0xFF403735)),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: LumiAdaptive.optionalText('Đóng'),
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
                style: LumiAdaptive.style(
                  GoogleFonts.dmSans(
                    fontSize: 16,
                    color: LumiAdaptive.color(const Color(0xFF403735)),
                  ),
                ),
                decoration: InputDecoration(
                  hintText: LumiAdaptive.optionalText(
                    'Nhập tên dịch vụ hoặc mỹ phẩm...',
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: LumiAdaptive.color(Color(0xFFA5553E)),
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: LumiAdaptive.optionalText('Xóa tìm kiếm'),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: LumiAdaptive.color(Colors.white, surface: true),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide(
                      color: LumiAdaptive.color(Color(0xFFEADFD5)),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(17),
                    borderSide: BorderSide(
                      color: LumiAdaptive.color(Color(0xFFA5553E)),
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
                          label: Text(LumiAdaptive.text(label)),
                          selected: _filter == label,
                          selectedColor: LumiAdaptive.color(
                            const Color(0xFFFBE7DC),
                            surface: true,
                          ),
                          backgroundColor: LumiAdaptive.color(
                            const Color(0xFFE8F2F6),
                            surface: true,
                          ),
                          labelStyle: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: LumiAdaptive.color(
                                const Color(0xFF403735),
                              ),
                            ),
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
                    return Center(
                      child: CircularProgressIndicator(
                        color: LumiAdaptive.color(Color(0xFFA5553E)),
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
                          LumiAdaptive.text(
                            'Chưa tìm thấy kết quả phù hợp.\nThử từ khóa khác nhé!',
                          ),
                          textAlign: TextAlign.center,
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 16,
                              height: 1.5,
                              color: LumiAdaptive.color(
                                const Color(0xFF756863),
                              ),
                            ),
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
                        color: LumiAdaptive.color(
                          index.isEven
                              ? const Color(0xFFFBE7DC)
                              : const Color(0xFFE8F2F6),
                          surface: true,
                        ),
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
                            color: LumiAdaptive.color(const Color(0xFFA5553E)),
                          ),
                          title: Text(
                            LumiAdaptive.text(
                              entry.item['name']?.toString() ?? 'LUMI',
                            ),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: LumiAdaptive.color(
                                  const Color(0xFF403735),
                                ),
                              ),
                            ),
                          ),
                          subtitle: Text(
                            LumiAdaptive.text(
                              entry.service ? 'Dịch vụ' : 'Mỹ phẩm',
                            ),
                            style: LumiAdaptive.style(
                              GoogleFonts.dmSans(fontSize: 13),
                            ),
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
        color: LumiAdaptive.color(Colors.white, surface: true),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            LumiAdaptive.text(message),
            textAlign: TextAlign.center,
            style: LumiAdaptive.style(
              GoogleFonts.dmSans(
                fontSize: 16,
                height: 1.5,
                color: LumiAdaptive.color(LumiStyle.ink),
              ),
            ),
          ),
          if (retry) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => setState(_connect),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(LumiAdaptive.text('Thử lại')),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LumiAdaptive.depend(context);
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
                      color: LumiAdaptive.color(
                        index == selected ? LumiStyle.rose : LumiStyle.line,
                        surface: true,
                      ),
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
                return ColoredBox(
                  color: LumiAdaptive.color(Color(0xFFFBE7DC), surface: true),
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
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  LumiAdaptive.color(Color(0xFFFFF8EF), surface: true),
                  LumiAdaptive.color(Color(0xF2FFF8EF), surface: true),
                  LumiAdaptive.color(Color(0x1AFFF8EF), surface: true),
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
                        LumiAdaptive.text(title),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: LumiAdaptive.style(
                          GoogleFonts.dmSans(
                            fontSize: 26,
                            height: 1.2,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.4,
                            color: LumiAdaptive.color(LumiStyle.ink),
                          ),
                        ),
                      ),
                    if (tab != null) ...[
                      const SizedBox(height: 22),
                      FilledButton(
                        onPressed: () => widget.onNavigate(tab),
                        style: LumiAdaptive.style(
                          FilledButton.styleFrom(
                            backgroundColor: LumiAdaptive.color(
                              LumiStyle.peach,
                              surface: true,
                            ),
                            foregroundColor: LumiAdaptive.color(LumiStyle.ink),
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            shape: const StadiumBorder(),
                          ),
                        ),
                        child: Text(
                          LumiAdaptive.text(
                            tab == 2 ? 'Xem mỹ phẩm →' : 'Xem dịch vụ →',
                          ),
                          style: LumiAdaptive.style(
                            GoogleFonts.dmSans(
                              fontSize: 16,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
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

  Widget _imageUnavailable() => ColoredBox(
    color: LumiAdaptive.color(Color(0xFFE8F2F6), surface: true),
    child: Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Icon(
          Icons.broken_image_outlined,
          color: LumiAdaptive.color(Color(0xFF557C90)),
          size: 36,
        ),
      ),
    ),
  );
}
