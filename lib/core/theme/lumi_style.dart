import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LUMI Design System V2 — Soft Luxury Wellness.
/// Pink-led accents (65%), blue (25%), peach (10%) on a calm ivory canvas.
/// Existing API names are preserved for compatibility with current screens.
abstract final class LumiStyle {
  // Original public tokens retained to avoid breaking older screens.
  static const ivory = Color(0xFFFAF7F4);
  static const plum = Color(0xFF392F37);
  static const rose = Color(0xFFB77C88);
  static const muted = Color(0xFF887D80);

  // Brand accents — use as accents, not full-screen color coverage.
  static const dustyRose = Color(0xFFB77C88);
  static const softPink = Color(0xFFF2BDCB);
  static const mutedBlue = Color(0xFF8AA6BF);
  static const aquaBlue = Color(0xFF79C7D9);
  static const peach = Color(0xFFF2C4B3);

  // Supporting surfaces and borders.
  static const canvas = ivory;
  static const surface = Color(0xFFFFFDFC);
  static const blushSurface = Color(0xFFFFF0F3);
  static const blueSurface = Color(0xFFEAF3F7);
  static const line = Color(0xFFEADFE1);
  static const ink = plum;

  static const double radiusSmall = 8;
  static const double radiusMedium = 16;
  static const double radiusLarge = 26;
  static const double screenPadding = 24;

  static const Duration motionFast = Duration(milliseconds: 180);
  static const Duration motionNormal = Duration(milliseconds: 320);
  static const Duration motionSlow = Duration(milliseconds: 520);
  static const Curve motionCurve = Curves.easeInOutCubic;

  static TextStyle heading({double size = 48, Color color = plum}) =>
      GoogleFonts.cormorantGaramond(
        fontSize: size,
        fontWeight: FontWeight.w500,
        height: 1.05,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle body({double size = 15, Color color = muted}) =>
      GoogleFonts.manrope(fontSize: size, height: 1.5, color: color);

  static TextStyle label({double size = 11, Color color = plum}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: color,
      );

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: canvas,
    colorScheme: ColorScheme.fromSeed(
      seedColor: dustyRose,
      brightness: Brightness.light,
      primary: plum,
      secondary: dustyRose,
      surface: surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: plum,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: heading(size: 30),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        side: const BorderSide(color: line),
      ),
    ),
    dividerColor: line,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusSmall),
        borderSide: const BorderSide(color: dustyRose, width: 1.5),
      ),
    ),
  );
}

/// Compatible with existing `LumiButton(label:, onPressed:, light:)` calls.
class LumiButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool light;

  const LumiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.light = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = light ? LumiStyle.plum : LumiStyle.ivory;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: light ? LumiStyle.ivory : LumiStyle.plum,
          foregroundColor: foreground,
          disabledBackgroundColor: LumiStyle.line,
          disabledForegroundColor: LumiStyle.muted,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LumiStyle.radiusSmall),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CustomPaint(
              size: const Size(43, 18),
              painter: _LumiArrowPainter(
                onPressed == null ? LumiStyle.muted : foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LumiArrowPainter extends CustomPainter {
  final Color color;

  const _LumiArrowPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.25
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(0, 9)
      ..lineTo(41, 9)
      ..moveTo(33, 2)
      ..lineTo(41, 9)
      ..lineTo(33, 16);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LumiArrowPainter oldDelegate) =>
      oldDelegate.color != color;
}
