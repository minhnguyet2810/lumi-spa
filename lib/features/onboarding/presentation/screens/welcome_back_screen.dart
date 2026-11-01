import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/session/session_store.dart';

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen>
    with SingleTickerProviderStateMixin {
  static const _cream = Color(0xFFFFF8EF);
  static const _ink = Color(0xFF403735);
  static const _muted = Color(0xFF6F625D);
  static const _peach = Color(0xFFF5BEA5);

  late final AnimationController _animation;
  String _name = '';
  bool _pressed = false;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _loadName();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _animation.value = 1;
    } else if (_animation.status == AnimationStatus.dismissed) {
      _animation.forward();
    }
  }

  Future<void> _loadName() async {
    try {
      final name = await SessionStore.getName();
      if (!mounted) return;
      setState(() => _name = name.trim());
    } catch (_) {
      // Vẫn cho phép tiếp tục nếu chưa đọc được tên.
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  Widget _reveal(double start, Widget child) {
    final progress = _animation.drive(
      CurveTween(curve: Interval(start, 1, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: progress.drive(
          Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  void _continue() {
    if (_leaving) return;
    _leaving = true;
    HapticFeedback.lightImpact();
    context.go('/home');
  }

  Widget _button() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1,
      duration: Duration(milliseconds: reduceMotion ? 0 : 120),
      child: Material(
        color: _peach,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _continue,
          onHighlightChanged: (value) {
            if (mounted) setState(() => _pressed = value);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 19),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Khám phá LUMI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 17,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.arrow_forward_rounded, color: _ink, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _photo(double height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.asset(
        'assets/images/welcome_spa_5.png',
        fit: BoxFit.cover,
        alignment: const Alignment(0.15, 0),
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: Color(0xFFFBE7DC)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: _cream,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _cream,
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                _photo(constraints.maxHeight),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.26, 0.48, 0.76, 1],
                      colors: [
                        Color(0xFFFFF1E6),
                        Color(0xF5FFF1E6),
                        Color(0x22FFF1E6),
                        Color(0x153F3028),
                        Color(0xCC403735),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, safeConstraints) {
                      final heroSpace = (safeConstraints.maxHeight * 0.24)
                          .clamp(100.0, 260.0)
                          .toDouble();

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (safeConstraints.maxHeight - 36)
                                .clamp(0.0, double.infinity)
                                .toDouble(),
                          ),
                          child: IntrinsicHeight(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _reveal(
                                  0,
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'LUMI',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 23,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                            color: _ink,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF8EF),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x153F3028),
                                              blurRadius: 16,
                                              offset: Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.spa_outlined,
                                          color: Color(0xFFA5553E),
                                          size: 24,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 26),
                                _reveal(
                                  0.06,
                                  Text(
                                    'Một chút\nbình yên.',
                                    style: GoogleFonts.lora(
                                      fontSize: 43,
                                      height: 1.16,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.8,
                                      color: _ink,
                                    ),
                                  ),
                                ),
                                SizedBox(height: heroSpace),
                                const Spacer(),
                                _reveal(
                                  0.18,
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: _cream,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(0xFFFFFDFA),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x243F3028),
                                          blurRadius: 30,
                                          offset: Offset(0, 12),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _name.isEmpty
                                              ? 'Chào bạn.'
                                              : 'Chào $_name.',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 27,
                                            height: 1.25,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0,
                                            color: _ink,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Hôm nay, dành thời gian\n'
                                          'chăm sóc mình nhé.',
                                          style: GoogleFonts.dmSans(
                                            fontSize: 17,
                                            height: 1.5,
                                            letterSpacing: 0,
                                            color: _muted,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        SizedBox(
                                          width: double.infinity,
                                          child: _button(),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
