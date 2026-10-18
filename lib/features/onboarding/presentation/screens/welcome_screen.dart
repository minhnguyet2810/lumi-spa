import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/session/session_store.dart';
import '../../../../core/theme/lumi_style.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const _images = [
    'assets/images/welcome_spa_1.png',
    'assets/images/welcome_spa_2.png',
    'assets/images/welcome_spa_3.png',
    'assets/images/welcome_spa_4.png',
    'assets/images/welcome_spa_5.png',
  ];

  static const _titles = [
    'Beauty, in your own rhythm.',
    'A softer way to unwind.',
    'Rituals made for you.',
    'Where care meets innovation.',
    'Your radiance begins here.',
  ];

  static const _subtitles = [
    'Một hành trình chăm sóc sắc đẹp dành riêng cho bạn.',
    'Dành thời gian cho sự thư thái và cân bằng.',
    'Từng trải nghiệm được chăm chút tỉ mỉ.',
    'Sự tinh tế kết hợp cùng công nghệ chăm sóc da.',
    'Chào mừng bạn đến với LUMI SPA.',
  ];

  late final PageController _pages;
  late final AnimationController _zoom;

  Timer? _timer;
  int _index = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();

    _pages = PageController();

    _zoom = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..forward();

    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted &&
          !_busy &&
          _pages.hasClients &&
          _index < _images.length - 1) {
        _pages.nextPage(
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    for (final path in _images) {
      precacheImage(AssetImage(path), context);
    }
  }

  Future<void> _finish({bool login = false}) async {
    if (_busy) return;

    setState(() => _busy = true);
    _timer?.cancel();

    try {
      await SessionStore.completeOnboarding();

      if (!mounted) return;

      context.go(login ? '/login' : '/home');
    } catch (_) {
      if (!mounted) return;

      setState(() => _busy = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể lưu tiến trình. Vui lòng thử lại.'),
        ),
      );
    }
  }

  void _next() {
    if (_busy || !_pages.hasClients) return;

    if (_index == _images.length - 1) {
      _finish();
      return;
    }

    _pages.nextPage(
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pages.dispose();
    _zoom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compact = size.height < 760;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: LumiStyle.ivory,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pages,
            itemCount: _images.length,
            onPageChanged: (i) {
              setState(() => _index = i);
              _zoom.forward(from: 0);
            },
            itemBuilder: (context, i) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedBuilder(
                    animation: _zoom,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: i == _index
                            ? 1.06 -
                                  0.06 * Curves.easeOut.transform(_zoom.value)
                            : 1,
                        child: child,
                      );
                    },
                    child: Image.asset(_images[i], fit: BoxFit.cover),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x44000000),
                          Colors.transparent,
                          Color(0x55241B20),
                          Color(0xDD241B20),
                        ],
                        stops: [0, 0.32, 0.58, 1],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                26,
                compact ? 14 : 20,
                26,
                bottomInset > 0 ? 12 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BRAND
                  Row(
                    children: [
                      Text(
                        'LUMI',
                        style: LumiStyle.heading(size: 36, color: Colors.white),
                      ),
                      const Spacer(),
                      Text(
                        '0${_index + 1} / 05',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // EDITORIAL LABEL
                  Text(
                    'THE ART OF SELF-CARE',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2.3,
                    ),
                  ),

                  SizedBox(height: compact ? 8 : 12),

                  // LARGE HEADING
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    child: Text(
                      _titles[_index],
                      key: ValueKey(_index),
                      style: LumiStyle.heading(
                        size: compact ? 42 : 47,
                        color: Colors.white,
                      ).copyWith(height: 1.02, letterSpacing: -0.6),
                    ),
                  ),

                  SizedBox(height: compact ? 8 : 12),

                  // DESCRIPTION
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      _subtitles[_index],
                      key: ValueKey('subtitle_$_index'),
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        height: 1.45,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  SizedBox(height: compact ? 16 : 23),

                  // IMAGE PROGRESS
                  Row(
                    children: List.generate(
                      _images.length,
                      (i) => Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (_busy) return;

                            _pages.animateToPage(
                              i,
                              duration: const Duration(milliseconds: 650),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              height: i == _index ? 3 : 2,
                              margin: const EdgeInsets.only(right: 6),
                              color: i == _index
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: compact ? 9 : 15),

                  // PRIMARY CTA
                  LumiButton(
                    label: _index == _images.length - 1
                        ? 'Khám phá LUMI'
                        : 'Tiếp tục',
                    light: true,
                    onPressed: _busy ? null : _next,
                  ),

                  const SizedBox(height: 12),

                  // SECONDARY CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _finish(login: true),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Color(0xCCFFFFFF),
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      child: Text(
                        'ĐÃ CÓ TÀI KHOẢN? ĐĂNG NHẬP',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
