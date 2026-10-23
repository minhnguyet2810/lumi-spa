import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/session/session_store.dart';

class WelcomeBackScreen extends StatefulWidget {
  const WelcomeBackScreen({super.key});

  @override
  State<WelcomeBackScreen> createState() => _WelcomeBackScreenState();
}

class _WelcomeBackScreenState extends State<WelcomeBackScreen> {
  static const _cream = Color(0xFFFFFAF8);
  static const _pink = Color(0xFFF4E4E8);
  static const _rose = Color(0xFFB56F86);
  static const _blue = Color(0xFFDDECEF);
  static const _ink = Color(0xFF503B42);

  String _name = 'bạn';

  @override
  void initState() {
    super.initState();
    _loadName();
  }

  Future<void> _loadName() async {
    final name = await SessionStore.getName();
    if (!mounted) return;
    setState(() {
      _name = name.trim().isEmpty ? 'bạn' : name.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final imageHeight = (screenHeight * 0.35).clamp(190.0, 310.0);

    return Scaffold(
      backgroundColor: _cream,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 38,
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
                              'LUMI',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 43,
                                fontWeight: FontWeight.w600,
                                height: 0.95,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SPA & WELLNESS',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                letterSpacing: 2.1,
                                fontWeight: FontWeight.w600,
                                color: _rose,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: _pink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.spa_outlined,
                            color: _rose,
                            size: 25,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: SizedBox(
                        height: imageHeight,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/welcome_spa_5.png',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'CHÀO MỪNG TRỞ LẠI',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: _rose,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'Thật vui khi gặp lại,\n$_name.',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 39,
                        fontWeight: FontWeight.w600,
                        height: 1.02,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Một khoảng lặng dịu dàng đang chờ bạn tại LUMI. '
                      'Hãy tiếp tục hành trình chăm sóc bản thân nhé.',
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        height: 1.55,
                        color: const Color(0xFF765F67),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 13,
                      ),
                      decoration: BoxDecoration(
                        color: _blue,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_outlined,
                            color: Color(0xFF638A94),
                            size: 23,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Hôm nay, hãy dành thời gian cho chính mình.',
                              style: GoogleFonts.dmSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                color: _ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _rose,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Tiếp tục trải nghiệm',
                              style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Icon(Icons.arrow_forward_rounded),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        'LUMI SPA  ·  KHOẢNH KHẮC DÀNH CHO BẠN',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          letterSpacing: 1.1,
                          color: const Color(0xFF987F87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
