import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lumi_spa/core/settings/app_preferences.dart';

class LumiAiHomeCard extends StatefulWidget {
  const LumiAiHomeCard({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  State<LumiAiHomeCard> createState() => _LumiAiHomeCardState();
}

class _LumiAiHomeCardState extends State<LumiAiHomeCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _motion.stop();
    } else if (!_motion.isAnimating) {
      _motion.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFFFF4EA) : const Color(0xFF403735);
    return Semantics(
      button: true,
      label: context.lumiText('Mở trợ lý LUMI AI', 'Open LUMI AI assistant'),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF557C90)
                  .withValues(alpha: dark ? 0.16 : 0.13),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: Material(
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          color: dark ? const Color(0xFF344650) : const Color(0xFFE7F0EF),
          child: InkWell(
            onTap: widget.onTap,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: dark ? 0.14 : 0.22,
                    child: Image.asset(
                      'assets/images/welcome_spa_5.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                          const SizedBox.shrink(),
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: dark
                            ? [const Color(0xF0344650), const Color(0xCC514038)]
                            : [
                                const Color(0xF5FBE7DC),
                                const Color(0xC8D5EBF0),
                              ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 22,
                  child: ExcludeSemantics(
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(
                          0,
                          math.sin(_motion.value * math.pi) * 10,
                        ),
                        child: Transform.rotate(
                          angle: (_motion.value - .5) * .18,
                          child: child,
                        ),
                      ),
                      child: Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: ink.withValues(alpha: .15)),
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: .45),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 49,
                          color: dark
                              ? const Color(0xFFF5BEA5)
                              : const Color(0xFFA5553E),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: dark ? 0.12 : 0.65,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'LUMI AI',
                          style: TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(right: 75),
                        child: Text(
                          context.lumiText(
                            'Một người bạn\nhiểu cách bạn chăm mình.',
                            'A little guidance,\njust for you.',
                          ),
                          style: TextStyle(
                            color: ink,
                            fontSize: 24,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.lumiText(
                          'Hỏi về mỹ phẩm, khám phá liệu trình\nvà gửi ảnh để tham khảo cùng AI.',
                          'Explore cosmetics and spa services.\nAsk a question or share a photo.',
                        ),
                        style: TextStyle(
                          color: ink.withValues(alpha: .85),
                          height: 1.5,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA5553E),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    context.lumiText(
                                      'Trò chuyện ngay',
                                      'Let’s chat',
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            context.lumiText(
                              'Chăm sóc theo cách của bạn',
                              'Care, your way',
                            ),
                            style: TextStyle(color: ink, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
