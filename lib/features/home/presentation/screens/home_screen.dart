
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/session/session_store.dart';
import '../../../../core/theme/lumi_style.dart';

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
  final PageController _heroController = PageController();
  Timer? _heroTimer;
  int _heroIndex = 0;

  static const _pink = Color(0xFFD98B99);
  static const _softPink = Color(0xFFF2BDCB);
  static const _blue = Color(0xFF8AA6BF);
  static const _aqua = Color(0xFF79C7D9);
  static const _peach = Color(0xFFF2C4B3);
  static const _ink = Color(0xFF493C46);
  static const _canvas = Color(0xFFFFFAF9);


  @override
  void initState() {
    super.initState();
    _loadSession();
    _servicesFuture = _fetchServices();
    _productsFuture = _fetchProducts();
    _heroTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_heroController.hasClients || _tab != 0) return;
      final next = (_heroIndex + 1) % 3;
      _heroController.animateToPage(
        next,
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroController.dispose();
    super.dispose();
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
                  context.push('/login').then((_) {
                    if (mounted) _loadSession();
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

  Widget _discoveryCard(
      String image,
      String title,
      String subtitle,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _image(image, height: 190),
          const SizedBox(height: 12),
          Text(title, style: LumiStyle.heading(size: 25)),
          const SizedBox(height: 4),
          Text(subtitle, style: LumiStyle.body(size: 13)),
          const SizedBox(height: 8),
          const Icon(Icons.arrow_outward, size: 19, color: _plum),
        ],
      ),
    );
  }


  Widget _home() {
    return RefreshIndicator(
      color: _pink,
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
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _eyebrow('YOUR DAILY MOMENT OF CARE'),
                      const SizedBox(height: 6),
                      Text(
                        _isLoggedIn ? 'Chào, $_memberName ♡' : 'A little glow, every day.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 36, height: 1.03,
                          fontWeight: FontWeight.w600, color: _ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Dành một chút dịu dàng cho chính mình.',
                          style: GoogleFonts.dmSans(fontSize: 12, color: _ink.withValues(alpha: .7))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE5EB),
                    shape: BoxShape.circle,
                    border: Border.all(color: _softPink),
                  ),
                  child: const Icon(Icons.spa_outlined, color: _pink, size: 25),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 370,
            child: PageView(
              controller: _heroController,
              onPageChanged: (value) => setState(() => _heroIndex = value),
              children: [
                _heroSlide('assets/images/welcome_spa_2.png',
                    'A softer kind\nof beautiful.',
                    'LUMI SPA & WELLNESS',
                    'KHÁM PHÁ LIỆU TRÌNH', () => setState(() => _tab = 1)),
                _heroSlide('assets/images/welcome_spa_3.png',
                    'Pause. Breathe.\nBloom.',
                    'A MOMENT FOR YOU',
                    'ĐẶT LỊCH CHĂM SÓC', () => _requireLogin('đặt lịch tại LUMI')),
                _heroSlide('assets/images/welcome_spa_1.png',
                    'Your glow,\nyour ritual.',
                    'LUMI BEAUTY',
                    'KHÁM PHÁ MỸ PHẨM', () => setState(() => _tab = 2)),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _heroIndex == index ? 22 : 6, height: 6,
              decoration: BoxDecoration(
                color: _heroIndex == index ? _pink : _softPink,
                borderRadius: BorderRadius.circular(12),
              ),
            )),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _eyebrow('EXPLORE LUMI'),
                const SizedBox(height: 9),
                Text('What feels good today?',
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 32, fontWeight: FontWeight.w600, color: _ink)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _quickAction(Icons.calendar_month_outlined, 'Đặt lịch',
                        const Color(0xFFFFE5EB), _pink,
                            () => _requireLogin('đặt lịch tại LUMI')),
                    const SizedBox(width: 9),
                    _quickAction(Icons.spa_outlined, 'Dịch vụ',
                        const Color(0xFFE5F3F7), _blue,
                            () => setState(() => _tab = 1)),
                    const SizedBox(width: 9),
                    _quickAction(Icons.shopping_bag_outlined, 'Mỹ phẩm',
                        const Color(0xFFFFEDE5), _pink,
                            () => setState(() => _tab = 2)),
                    const SizedBox(width: 9),
                    _quickAction(Icons.favorite_border, 'Của tôi',
                        const Color(0xFFF4E6F1), _pink,
                            () => setState(() => _tab = 4)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 31),
          _homeSectionTitle('THE LUMI RITUALS', 'Care made for you',
              'XEM TẤT CẢ', () => setState(() => _tab = 1)),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _servicesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _loadingPanel('Đang tải liệu trình...');
              }
              if (snapshot.hasError) {
                return _errorPanel('Chưa kết nối được danh sách liệu trình.', () {
                  setState(() => _servicesFuture = _fetchServices());
                });
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) return _loadingPanel('Chưa có liệu trình nào.');
              return SizedBox(
                height: 224,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final name = item['name']?.toString() ?? 'LUMI Ritual';
                    final minutes = item['durationMinutes']?.toString() ?? '—';
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(() => _tab = 1),
                      child: Container(
                        width: 235,
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: index.isEven
                              ? const Color(0xFFFFE8EC)
                              : const Color(0xFFEAF4F6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(Icons.spa_outlined,
                                      color: index.isEven ? _pink : _blue, size: 29),
                                  const Icon(Icons.arrow_outward, color: _ink, size: 18),
                                ]),
                            const Spacer(),
                            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cormorantGaramond(
                                    fontSize: 27, fontWeight: FontWeight.w600,
                                    height: 1, color: _ink)),
                            const SizedBox(height: 9),
                            Text('$minutes phút  ·  ${_priceVnd(item['price'])}',
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
                            const SizedBox(height: 6),
                            Text('Chạm để xem chi tiết',
                                style: GoogleFonts.dmSans(
                                    fontSize: 11, color: _ink.withValues(alpha: .6))),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          _homeSectionTitle('LUMI BEAUTY', 'The beauty shelf',
              'ĐẾN CỬA HÀNG', () => setState(() => _tab = 2)),
          const SizedBox(height: 12),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return _loadingPanel('Đang tải mỹ phẩm...');
              }
              if (snapshot.hasError) {
                return _errorPanel('Chưa kết nối được danh sách mỹ phẩm.', () {
                  setState(() => _productsFuture = _fetchProducts());
                });
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) return _loadingPanel('Chưa có mỹ phẩm nào.');
              return SizedBox(
                height: 186,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () => setState(() => _tab = 2),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 172,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFF4DCE3)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.water_drop_outlined, size: 32, color: _blue),
                            const Spacer(),
                            Text(item['name']?.toString() ?? 'LUMI Beauty',
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.dmSans(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                            const SizedBox(height: 7),
                            Text(_priceVnd(item['price']),
                                style: GoogleFonts.dmSans(fontSize: 13, color: _pink,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 33),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined, color: _blue, size: 34),
                  const SizedBox(width: 15),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your next moment of calm',
                          style: GoogleFonts.cormorantGaramond(
                              fontSize: 24, fontWeight: FontWeight.w600, color: _ink)),
                      const SizedBox(height: 4),
                      Text('Đặt lịch chăm sóc dành riêng cho bạn.',
                          style: GoogleFonts.dmSans(fontSize: 12, color: _ink)),
                    ],
                  )),
                  IconButton(
                    onPressed: () => _requireLogin('đặt lịch tại LUMI'),
                    icon: const Icon(Icons.arrow_forward, color: _ink),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 33),
          _homeSectionTitle('THE LUMI JOURNAL', 'Little notes on beauty',
              'KHÁM PHÁ', () => _showJournal()),
          const SizedBox(height: 13),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _showJournal,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _image('assets/images/welcome_spa_1.png', height: 190),
                    Container(
                      color: const Color(0xFFFFE8EC),
                      width: double.infinity,
                      padding: const EdgeInsets.all(17),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _eyebrow('WELLNESS NOTES · NỘI DUNG MẪU'),
                          const SizedBox(height: 8),
                          Text('Một làn da đẹp bắt đầu từ sự dịu dàng.',
                              style: GoogleFonts.cormorantGaramond(
                                  fontSize: 27, fontWeight: FontWeight.w600,
                                  height: 1.05, color: _ink)),
                          const SizedBox(height: 8),
                          Text('Đọc những gợi ý nhỏ để chăm sóc bản thân mỗi ngày  ↗',
                              style: GoogleFonts.dmSans(fontSize: 12, color: _ink)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text('LUMI · A SOFTER WAY TO GLOW',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                    fontSize: 10, letterSpacing: 2, color: _pink,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String label) => Text(
      label, style: GoogleFonts.dmSans(
      color: _pink, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.7));

  Widget _heroSlide(String asset, String title, String eyebrow,
      String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset(asset, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: _softPink)),
          DecoratedBox(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.transparent, const Color(0xFF312831).withValues(alpha: .76)],
              stops: const [.24, 1],
            ),
          )),
          Positioned(left: 22, right: 20, bottom: 23,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(eyebrow, style: GoogleFonts.dmSans(
                    fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFE2E9))),
                const SizedBox(height: 7),
                Text(title, style: GoogleFonts.cormorantGaramond(
                    color: Colors.white, fontSize: 39, height: .98,
                    fontWeight: FontWeight.w600)),
                const SizedBox(height: 17),
                SizedBox(height: 43, child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: _pink, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(action, style: GoogleFonts.dmSans(
                        fontSize: 11, letterSpacing: .7, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward, size: 17),
                  ]),
                )),
              ])),
        ]),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, Color bg, Color fg,
      VoidCallback onTap) {
    return Expanded(child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Column(children: [
        Container(height: 66, alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: fg, size: 26)),
        const SizedBox(height: 7),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: _ink)),
      ]),
    ));
  }

  Widget _homeSectionTitle(String eyebrow, String title,
      String action, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _eyebrow(eyebrow),
        const SizedBox(height: 5),
        Row(children: [
          Expanded(child: Text(title,
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 30, fontWeight: FontWeight.w600, color: _ink))),
          TextButton(onPressed: onTap,
              child: Text(action, style: GoogleFonts.dmSans(
                  color: _pink, fontSize: 10, fontWeight: FontWeight.w700))),
        ]),
      ]),
    );
  }

  Widget _loadingPanel(String message) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Container(
      height: 100, alignment: Alignment.center,
      decoration: BoxDecoration(
          color: const Color(0xFFFFE8EC), borderRadius: BorderRadius.circular(15)),
      child: Text(message, style: GoogleFonts.dmSans(color: _ink, fontSize: 13)),
    ),
  );

  Widget _errorPanel(String message, VoidCallback retry) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFFFFE8EC), borderRadius: BorderRadius.circular(15)),
      child: Row(children: [
        Expanded(child: Text(message,
            style: GoogleFonts.dmSans(color: _ink, fontSize: 12))),
        TextButton(onPressed: retry, child: const Text('THỬ LẠI')),
      ]),
    ),
  );

  void _showJournal() {
    showModalBottomSheet<void>(
      context: context, isScrollControlled: true,
      backgroundColor: _canvas,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 28, 25, 32),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                _eyebrow('LUMI JOURNAL · BÀI VIẾT MẪU'),
                const SizedBox(height: 10),
                Text('Một làn da đẹp bắt đầu từ sự dịu dàng.',
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 34, fontWeight: FontWeight.w600, color: _ink)),
                const SizedBox(height: 12),
                Text('Chăm sóc da không nhất thiết phải phức tạp. '
                    'Hãy làm sạch nhẹ nhàng, dưỡng ẩm phù hợp và '
                    'sử dụng kem chống nắng mỗi ngày. '
                    'Dành thời gian nghỉ ngơi cũng là một phần của hành trình chăm sóc bản thân.',
                    style: GoogleFonts.dmSans(fontSize: 14, height: 1.6, color: _ink)),
                const SizedBox(height: 20),
                Text('Nội dung minh họa giao diện; mục tin tức sẽ kết nối CMS sau.',
                    style: GoogleFonts.dmSans(fontSize: 11, color: _blue)),
                const SizedBox(height: 16),
                SizedBox(width: double.infinity,
                  child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: FilledButton.styleFrom(backgroundColor: _pink),
                      child: const Text('ĐÓNG')),
                ),
              ]),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchProducts() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/products'),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final payload = jsonDecode(utf8.decode(response.bodyBytes));
    if (payload is! Map || payload['success'] != true || payload['data'] is! List) {
      throw const FormatException('Dữ liệu mỹ phẩm không hợp lệ');
    }
    return (payload['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchServices() async {
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/api/services'),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }
    final payload = jsonDecode(utf8.decode(response.bodyBytes));
    if (payload is! Map || payload['success'] != true || payload['data'] is! List) {
      throw const FormatException('Dữ liệu dịch vụ không hợp lệ');
    }
    return (payload['data'] as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
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
                  Text('$duration phút  ·  $price',
                      style: GoogleFonts.dmSans(
                        color: _plum,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _spa() {
    return RefreshIndicator(
      onRefresh: _refreshServices,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          _sectionHeading('LUMI SPA', 'Your time to unwind.'),
          const SizedBox(height: 10),
          Text(
            'Khám phá không gian thư giãn và các liệu trình chăm sóc tại LUMI.',
            style: LumiStyle.body(size: 15),
          ),
          const SizedBox(height: 22),
          _image('assets/images/welcome_spa_3.png', height: 260),
          const SizedBox(height: 24),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _servicesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: _rose)),
                );
              }
              if (snapshot.hasError) {
                return Column(
                  children: [
                    Text('Không tải được dịch vụ. Kiểm tra backend rồi thử lại.',
                        style: LumiStyle.body(size: 14)),
                    TextButton(
                      onPressed: _refreshServices,
                      child: const Text('THỬ LẠI'),
                    ),
                  ],
                );
              }
              final services = snapshot.data ?? [];
              if (services.isEmpty) {
                return Text('Chưa có dịch vụ nào.', style: LumiStyle.body(size: 14));
              }
              return Column(
                children: [
                  for (var i = 0; i < services.length; i++)
                    _serviceTile((i + 1).toString().padLeft(2, '0'), services[i]),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          _filledButton(
            'ĐẶT LỊCH TƯ VẤN',
                () => _requireLogin('đặt lịch tại LUMI'),
          ),
          const SizedBox(height: 12),
          Text('Dữ liệu dịch vụ đang được lấy từ LUMI API.',
              style: LumiStyle.body(size: 12)),
        ],
      ),
    );
  }

  Widget _shop() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        _sectionHeading('LUMI BEAUTY', 'The skincare edit.'),
        const SizedBox(height: 10),
        Text(
          'Khám phá thế giới chăm sóc da tại nhà của LUMI.',
          style: LumiStyle.body(size: 15),
        ),
        const SizedBox(height: 20),
        _image('assets/images/welcome_spa_1.png', height: 230),
        const SizedBox(height: 26),
        Text(
          'COMING SOON',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: _rose,
            letterSpacing: 2.2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text('The LUMI Collection', style: LumiStyle.heading(size: 35)),
        const SizedBox(height: 10),
        Text(
          'Bộ sưu tập mỹ phẩm LUMI đang được hoàn thiện. '
              'Danh sách sản phẩm, thành phần và giá bán '
              'sẽ được cập nhật khi có dữ liệu chính thức.',
          style: LumiStyle.body(size: 15),
        ),
        const SizedBox(height: 24),
        _filledButton(
          'KHÁM PHÁ BỘ SƯU TẬP',
              () => _showComingSoon('Bộ sưu tập mỹ phẩm'),
        ),
      ],
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

  Widget _memberAppointments() {
    return _protectedPage(
      eyebrow: 'YOUR APPOINTMENTS',
      title: 'Your moments,\nbeautifully planned.',
      description:
      'Bạn đã đăng nhập. Chức năng xem và '
          'quản lý lịch hẹn sẽ được bổ sung sau.',
      icon: Icons.calendar_month_outlined,
      action: 'quản lý lịch hẹn',
    );
  }

  Widget _profile() {
    if (!_isLoggedIn) {
      return _protectedPage(
        eyebrow: 'YOUR LUMI',
        title: 'A space,\njust for you.',
        description:
        'Đăng nhập để quản lý tài khoản, '
            'lịch sử mua hàng và thông tin cá nhân.',
        icon: Icons.person_outline,
        action: 'quản lý tài khoản',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(26, 32, 26, 32),
      children: [
        Text(
          'YOUR LUMI',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            color: _rose,
            letterSpacing: 2.1,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Text('Hello,\n$_memberName.', style: LumiStyle.heading(size: 46)),
        const SizedBox(height: 14),
        Text(
          'Không gian cá nhân của bạn tại LUMI.',
          style: LumiStyle.body(size: 15),
        ),
        const SizedBox(height: 32),
        _profileTile(
          Icons.calendar_month_outlined,
          'Lịch hẹn của tôi',
              () => setState(() => _tab = 3),
        ),
        _profileTile(
          Icons.shopping_bag_outlined,
          'Đơn hàng của tôi',
              () => _showComingSoon('Quản lý đơn hàng'),
        ),
        _profileTile(
          Icons.favorite_border,
          'Yêu thích',
              () => _showComingSoon('Danh sách yêu thích'),
        ),
        const SizedBox(height: 35),
        _filledButton(
          _loggingOut ? 'ĐANG ĐĂNG XUẤT...' : 'ĐĂNG XUẤT',
          _loggingOut ? null : _logout,
        ),
        const SizedBox(height: 12),
        Text(
          'Bạn đang sử dụng tài khoản demo. '
              'Xác thực tài khoản thật sẽ được tích hợp sau.',
          style: LumiStyle.body(size: 12),
        ),
      ],
    );
  }

  Widget _profileTile(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        const Divider(height: 20),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: _plum),
          title: Text(
            title,
            style: GoogleFonts.dmSans(fontSize: 15, color: _plum),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: _rose),
          onTap: onTap,
        ),
      ],
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
      _isLoggedIn
          ? _memberAppointments()
          : _protectedPage(
        eyebrow: 'YOUR APPOINTMENTS',
        title: 'Your moments,\nbeautifully planned.',
        description:
        'Đăng nhập để xem lịch hẹn và quản lý '
            'những buổi chăm sóc tại LUMI.',
        icon: Icons.calendar_month_outlined,
        action: 'xem và quản lý lịch hẹn',
      ),
      _profile(),
    ];

    return Scaffold(
      backgroundColor: _canvas,
      appBar: AppBar(
        backgroundColor: _canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 66,
        title: Text('LUMI', style: GoogleFonts.cormorantGaramond(fontSize: 35, fontWeight: FontWeight.w600, color: _ink)),
        actions: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 125),
              child: Text(
                _isLoggedIn ? _memberName.toUpperCase() : 'GUEST',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: _rose,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Shop',
            onPressed: () => setState(() => _tab = 2),
            icon: const Icon(Icons.shopping_bag_outlined, color: _plum),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: pages[_tab],
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: _canvas,
          indicatorColor: const Color(0xFFFFDCE5),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _plum,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _tab,
          height: 72,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            setState(() => _tab = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.spa_outlined),
              selectedIcon: Icon(Icons.spa),
              label: 'Spa',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_bag_outlined),
              selectedIcon: Icon(Icons.shopping_bag),
              label: 'Shop',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Lịch hẹn',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Tôi',
            ),
          ],
        ),
      ),
    );
  }
}
