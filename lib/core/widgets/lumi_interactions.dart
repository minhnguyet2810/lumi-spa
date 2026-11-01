import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Decorative input feedback only: does not capture taps or modify navigation.
class LumiSparkleTrail extends StatefulWidget {
  const LumiSparkleTrail({super.key, required this.child});
  final Widget child;
  @override
  State<LumiSparkleTrail> createState() => _LumiSparkleTrailState();
}

class _LumiSparkleTrailState extends State<LumiSparkleTrail>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _clock = Stopwatch()..start();
  final _particles = <_Spark>[];
  late final Ticker _ticker;
  int _last = -100;
  bool _active = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((_) {
      final now = _clock.elapsedMilliseconds;
      setState(() => _particles.removeWhere((p) => now - p.born > 650));
      if (_particles.isEmpty) {
        _ticker.stop();
      }
    });
  }

  void _emit(Offset position, {bool burst = false}) {
    if (!_active || MediaQuery.disableAnimationsOf(context)) {
      return;
    }
    final now = _clock.elapsedMilliseconds;
    if (!burst && now - _last < 65) {
      return;
    }
    _last = now;
    setState(() {
      final count = burst ? 6 : 1;
      for (var i = 0; i < count; i++) {
        final angle = (i / count) * math.pi * 2 + now * 0.01;
        _particles.add(
          _Spark(
            position,
            Offset(math.cos(angle), math.sin(angle)) * (burst ? 27 : 12),
            now,
            i % 3,
          ),
        );
      }
      if (_particles.length > 32) {
        _particles.removeRange(0, _particles.length - 32);
      }
    });
    if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _particles.clear();
      _ticker.stop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (!_active) {
      _ticker.stop();
      setState(_particles.clear);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (event) => _emit(event.localPosition, burst: true),
    onPointerMove: (event) => _emit(event.localPosition),
    onPointerHover: (event) => _emit(event.localPosition),
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: ExcludeSemantics(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _SparkPainter(
                    List.of(_particles),
                    _clock.elapsedMilliseconds,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Spark {
  const _Spark(this.position, this.velocity, this.born, this.tint);
  final Offset position, velocity;
  final int born, tint;
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter(this.particles, this.now);
  final List<_Spark> particles;
  final int now;
  @override
  void paint(Canvas canvas, Size size) {
    const colors = [Color(0xFFC88345), Color(0xFF6B9DAD), Color(0xFFA9B989)];
    for (final p in particles) {
      final t = ((now - p.born) / 650).clamp(0.0, 1.0).toDouble();
      final position = p.position + p.velocity * t + Offset(0, -12 * t);
      final radius = (p.tint == 0 ? 5.5 : 3.5) * (1 - t);
      final paint = Paint()
        ..color = colors[p.tint].withValues(alpha: (1 - t) * 0.75);
      final path = Path()
        ..moveTo(position.dx, position.dy - radius)
        ..quadraticBezierTo(
          position.dx + radius * 0.2,
          position.dy - radius * 0.2,
          position.dx + radius,
          position.dy,
        )
        ..quadraticBezierTo(
          position.dx + radius * 0.2,
          position.dy + radius * 0.2,
          position.dx,
          position.dy + radius,
        )
        ..quadraticBezierTo(
          position.dx - radius * 0.2,
          position.dy + radius * 0.2,
          position.dx - radius,
          position.dy,
        )
        ..quadraticBezierTo(
          position.dx - radius * 0.2,
          position.dy - radius * 0.2,
          position.dx,
          position.dy - radius,
        )
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.now != now || oldDelegate.particles != particles;
}

class LumiPressFeedback extends StatefulWidget {
  const LumiPressFeedback({super.key, required this.child});
  final Widget child;
  @override
  State<LumiPressFeedback> createState() => _LumiPressFeedbackState();
}

class _LumiPressFeedbackState extends State<LumiPressFeedback> {
  bool _pressed = false;
  void _set(bool value) {
    if (value != _pressed) {
      setState(() => _pressed = value);
    }
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 130,
      ),
      curve: Curves.easeOutCubic,
      child: widget.child,
    ),
  );
}
