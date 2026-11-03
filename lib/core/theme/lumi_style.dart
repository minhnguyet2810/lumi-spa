import 'lumi_adaptive.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LUMI — Warm cream, pastel peach and soft sky blue.
/// Light surfaces with dark, readable text.
/// Existing API names are preserved for compatibility with current screens.
abstract final class LumiStyle {
  // Original public tokens retained to avoid breaking older screens.
  static const ivory = Color(0xFFFFF8EF);
  static const plum = Color(0xFF403735);
  static const rose = Color(0xFFA5553E);
  static const muted = Color(0xFF756863);

  // Brand accents — use as accents, not full-screen color coverage.
  static const dustyRose = Color(0xFFA5553E);
  static const softPink = Color(0xFFF8D5C2);
  static const mutedBlue = Color(0xFF557C90);
  static const aquaBlue = Color(0xFFA9CEDD);
  static const peach = Color(0xFFF5BEA5);

  // Supporting surfaces and borders.
  static const canvas = ivory;
  static const surface = Color(0xFFFFFDFA);
  static const blushSurface = Color(0xFFFBE7DC);
  static const blueSurface = Color(0xFFEAF3F7);
  static const line = Color(0xFFEADFD5);
  static const ink = plum;

  static const double radiusSmall = 16;
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
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle body({double size = 16, Color color = muted}) =>
      GoogleFonts.dmSans(fontSize: size, height: 1.5, color: color);

  static TextStyle label({double size = 14, Color color = plum}) =>
      GoogleFonts.dmSans(
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: color,
      );

  /// Theme-aware screens read these colors through Theme.of(context).
  static ThemeData get darkTheme {
    final colors = ColorScheme.fromSeed(
      seedColor: peach,
      brightness: Brightness.dark,
      primary: const Color(0xFFF5BEA5),
      onPrimary: const Color(0xFF40271D),
      primaryContainer: const Color(0xFF56392F),
      onPrimaryContainer: const Color(0xFFFFE5D6),
      secondary: const Color(0xFFA9CEDD),
      secondaryContainer: const Color(0xFF2B414A),
      onSecondaryContainer: const Color(0xFFDCEFF7),
      surface: const Color(0xFF343D44),
      onSurface: const Color(0xFFF6EDE6),
      onSurfaceVariant: const Color(0xFFD8CEC4),
      outline: const Color(0xFF9B887D),
      outlineVariant: const Color(0xFF667680),
    );
    final base = ThemeData(
      useMaterial3: true,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: colors,
      scaffoldBackgroundColor: const Color(0xFF262D32),
    );
    final text = GoogleFonts.dmSansTextTheme(base.textTheme)
        .apply(bodyColor: colors.onSurface, displayColor: colors.onSurface);
    return base.copyWith(
      textTheme: text.copyWith(
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 17, height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 16, height: 1.5),
        bodySmall: text.bodySmall?.copyWith(
          fontSize: 14,
          height: 1.45,
          color: colors.onSurfaceVariant,
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: text.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: base.scaffoldBackgroundColor,
        foregroundColor: colors.onSurface,
        elevation: 2,
        shadowColor: dustyRose.withValues(alpha: 0.18),
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 2,
        shadowColor: dustyRose.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      dividerColor: colors.outlineVariant,
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(48, 52),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(48, 52),
          side: BorderSide(color: colors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        hintStyle: TextStyle(color: colors.onSurfaceVariant),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: canvas,
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      bodyLarge: GoogleFonts.dmSans(fontSize: 16, height: 1.55, color: ink),
      bodyMedium: GoogleFonts.dmSans(fontSize: 16, height: 1.5, color: ink),
      bodySmall: GoogleFonts.dmSans(fontSize: 14, height: 1.45, color: muted),
      titleLarge: GoogleFonts.dmSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: GoogleFonts.dmSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
      labelLarge: GoogleFonts.dmSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: peach,
        foregroundColor: ink,
        minimumSize: const Size(48, 52),
        textStyle: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 52),
        side: const BorderSide(color: line),
        textStyle: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: peach,
        foregroundColor: ink,
        elevation: 2,
        shadowColor: dustyRose.withValues(alpha: 0.18),
        minimumSize: const Size(48, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: dustyRose,
      brightness: Brightness.light,
      primary: dustyRose,
      secondary: mutedBlue,
      surface: surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: canvas,
      foregroundColor: plum,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.dmSans(
        fontSize: 23,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
    final foreground = light
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: light
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.primary,
          foregroundColor: foreground,
          disabledBackgroundColor: LumiStyle.line,
          disabledForegroundColor: Theme.of(context)
              .colorScheme
              .onSurfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                LumiAdaptive.text(label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
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
