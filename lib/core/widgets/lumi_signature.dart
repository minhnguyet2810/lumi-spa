import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lumi_spa/core/settings/app_preferences.dart';

/// A shared editorial header. Content sizes naturally for larger text settings.
class LumiSignatureHeader extends StatelessWidget {
  const LumiSignatureHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.icon = Icons.spa_outlined,
    this.image,
    this.footer,
  });
  final String eyebrow, title, description;
  final IconData icon;
  final String? image;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final ink = dark ? const Color(0xFFFFF1E7) : const Color(0xFF443932);
    final accent = dark ? const Color(0xFFF3BC9D) : const Color(0xFF9A4F36);
    return LumiSoftEntrance(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: .10),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              if (image != null)
                Positioned.fill(
                  child: Image.asset(
                    image!,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                    errorBuilder: (_, error, stack) => const SizedBox.shrink(),
                  ),
                ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: dark
                          ? [const Color(0xF53B403C), const Color(0xEC2F4650)]
                          : [
                              const Color(0xF9F9E2D2),
                              const Color(0xE8E3EDE7),
                              const Color(0xE5D9EAF0),
                            ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -40,
                top: -50,
                child: ExcludeSemantics(
                  child: Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ink.withValues(alpha: .10),
                        width: 26,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            eyebrow,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: ink.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(icon, color: accent, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      title,
                      style: TextStyle(
                        color: ink,
                        fontSize: 29,
                        height: 1.17,
                        letterSpacing: -.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: TextStyle(
                        color: ink.withValues(alpha: .83),
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 20),
                      footer!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Runs once per mounted header; reduced-motion users see the final state.
class LumiSoftEntrance extends StatelessWidget {
  const LumiSoftEntrance({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: Duration(
      milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 620,
    ),
    curve: Curves.easeOutCubic,
    child: child,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 16 * (1 - value)),
        child: child,
      ),
    ),
  );
}

class LumiMomentCard extends StatefulWidget {
  const LumiMomentCard({super.key});
  @override
  State<LumiMomentCard> createState() => _LumiMomentCardState();
}

class _LumiMomentCardState extends State<LumiMomentCard>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  );
  bool _pressed = false, _hovered = false, _active = true;
  bool _reduce = false, _visible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _syncMotion() {
    if (_active && _visible && !_reduce) {
      if (!_drift.isAnimating) {
        _drift.repeat(reverse: true);
      }
    } else {
      _drift.stop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduce = MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _syncMotion();
  }

  void _press(bool value) {
    if (mounted && _pressed != value) {
      setState(() => _pressed = value);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.lumiText('Mở khoảng nghỉ LUMI Moment', 'Open LUMI Moment'),
    child: MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: Listener(
        onPointerDown: (_) => _press(true),
        onPointerUp: (_) => _press(false),
        onPointerCancel: (_) => _press(false),
        child: AnimatedScale(
          scale: _reduce
              ? 1
              : _pressed
              ? .98
              : _hovered
              ? 1.012
              : 1,
          duration: Duration(milliseconds: _reduce ? 0 : 190),
          curve: Curves.easeOutCubic,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(29),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF634537).withValues(alpha: .19),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Material(
              color: const Color(0xFF3B3029),
              borderRadius: BorderRadius.circular(29),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => const _MomentSheet(),
                ),
                splashColor: const Color(0x33F4D2BB),
                highlightColor: Colors.transparent,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: RepaintBoundary(
                          child: AnimatedBuilder(
                            animation: _drift,
                            child: Image.asset(
                              'assets/images/welcome_spa_3.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.centerRight,
                              errorBuilder: (_, error, stack) =>
                                  const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF49372D),
                                          Color(0xFF947A60),
                                        ],
                                      ),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Padding(
                                        padding: EdgeInsets.all(28),
                                        child: Icon(
                                          Icons.spa_outlined,
                                          color: Color(0x44FFFFFF),
                                          size: 95,
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                            builder: (_, child) => Transform.scale(
                              scale: 1.02 + (_reduce ? 0 : _drift.value * .055),
                              alignment: Alignment.centerRight,
                              child: child,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Color(0xF027201B),
                                Color(0xCF33271F),
                                Color(0x8943362A),
                              ],
                              stops: [0, .53, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 19,
                      top: 20,
                      child: ExcludeSemantics(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0x33251A12),
                            border: Border.all(color: const Color(0x66FFF5E8)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '1–3 MIN',
                            style: TextStyle(
                              color: Color(0xFFFFF5E8),
                              fontSize: 10,
                              letterSpacing: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 78),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.auto_awesome_outlined,
                                  size: 15,
                                  color: Color(0xFFF8C8A8),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'LUMI MOMENT',
                                    style: TextStyle(
                                      color: const Color(0xFFF8D5BD),
                                      fontSize: 10,
                                      letterSpacing: 2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 27),
                          Text(
                            context.lumiText(
                              'Tắt ồn ào.\nBật bình yên.',
                              'Less noise.\nMore you.',
                            ),
                            style: const TextStyle(
                              color: Color(0xFFFFF8EE),
                              fontSize: 31,
                              height: 1.12,
                              letterSpacing: -.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 245),
                            child: Text(
                              context.lumiText(
                                'Một khoảng nghỉ nhỏ,\ndành riêng cho bạn.',
                                'A little pause,\njust for you.',
                              ),
                              style: const TextStyle(
                                color: Color(0xFFEEDCCD),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.lumiText(
                                    'BẮT ĐẦU KHOẢNG NGHỈ',
                                    'TAKE A MOMENT',
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFFFFF4E5),
                                    letterSpacing: 1.1,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              AnimatedContainer(
                                duration: Duration(
                                  milliseconds: _reduce ? 0 : 220,
                                ),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _hovered || _pressed
                                      ? const Color(0xFFF6C5A5)
                                      : const Color(0xFFFFF2DF),
                                ),
                                child: AnimatedRotation(
                                  turns: !_reduce && _hovered ? .125 : 0,
                                  duration: Duration(
                                    milliseconds: _reduce ? 0 : 220,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 23,
                                    color: Color(0xFF473427),
                                  ),
                                ),
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
        ),
      ),
    ),
  );
}

class _MomentSheet extends StatefulWidget {
  const _MomentSheet();
  @override
  State<_MomentSheet> createState() => _MomentSheetState();
}

class _MomentSheetState extends State<_MomentSheet>
    with WidgetsBindingObserver {
  int _elapsed = 0, _lastTick = 0;
  bool _running = false;
  Timer? _timer;
  int _seconds = 60;
  bool _started = false;
  int get _remaining => math.max(0, _seconds - _elapsed);
  bool get _finished => _started && _remaining == 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _pause() {
    _running = false;
    _timer?.cancel();
    if (mounted) {
      setState(() {});
    }
  }

  void _start() {
    if (_finished) {
      _elapsed = 0;
    }
    _started = true;
    _running = true;
    _lastTick = 0;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsed += timer.tick - _lastTick;
      _lastTick = timer.tick;
      if (_remaining == 0) {
        _running = false;
        _timer?.cancel();
      }
      if (mounted) {
        setState(() {});
      }
    });
    setState(() {});
  }

  void _reset(int seconds) {
    _pause();
    setState(() {
      _elapsed = 0;
      _seconds = seconds;
      _started = false;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _running = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final scale = reduce || !_running
        ? 1.0
        : 1 + math.sin(_elapsed * math.pi / 4) * .06;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'LUMI MOMENT',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    letterSpacing: 2,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.lumiText(
              _finished
                  ? 'Cảm ơn bạn đã dành thời gian cho mình.'
                  : 'Để ngày chậm lại một chút.',
              _finished
                  ? 'Thank you for taking a moment.'
                  : 'Let your day slow down.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              height: 1.25,
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.lumiText(
              'Ngồi thoải mái và thở tự nhiên. Bạn có thể dừng bất cứ lúc nào.',
              'Get comfortable and breathe naturally. You can stop at any time.',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 24),
          AnimatedScale(
            scale: scale,
            duration: Duration(milliseconds: reduce ? 0 : 1000),
            curve: Curves.easeInOut,
            child: SizedBox(
              width: 170,
              height: 170,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [colors.primaryContainer, colors.surface],
                      ),
                      border: Border.all(
                        color: colors.primary.withValues(alpha: .15),
                        width: 10,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 158,
                    height: 158,
                    child: CircularProgressIndicator(
                      value: 1 - _remaining / _seconds,
                      strokeWidth: 3,
                      color: colors.primary,
                      backgroundColor: colors.primary.withValues(alpha: .10),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _finished ? Icons.check_rounded : Icons.spa_outlined,
                        color: colors.primary,
                        size: 30,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 29,
                          color: colors.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final minutes in [1, 2, 3])
                ChoiceChip(
                  label: Text(
                    context.lumiText('$minutes phút', '$minutes min'),
                  ),
                  selected: _seconds == minutes * 60,
                  onSelected: (_) => _reset(minutes * 60),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _running ? _pause : _start,
              icon: Icon(
                _running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              ),
              label: Text(
                context.lumiText(
                  _running
                      ? 'Tạm dừng'
                      : _finished
                      ? 'Thêm một khoảng nghỉ'
                      : _started
                      ? 'Tiếp tục'
                      : 'Bắt đầu khoảng nghỉ',
                  _running
                      ? 'Pause'
                      : _finished
                      ? 'Another moment'
                      : _started
                      ? 'Continue'
                      : 'Start my moment',
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _reset(_seconds),
            child: Text(context.lumiText('Bắt đầu lại', 'Reset')),
          ),
        ],
      ),
    );
  }
}
