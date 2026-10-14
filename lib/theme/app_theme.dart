import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's colours: cream paper, deep green ink and gold, like a printed
/// mushaf. The dark set is the same page at night.
@immutable
class Palette extends ThemeExtension<Palette> {
  final Color background; // the page
  final Color card; // panels resting on the page
  final Color sunk; // wells inside a panel: fields, answer buttons
  final Color border;
  final Color borderStrong;
  final Color ink; // main text
  final Color muted; // secondary text
  final Color faint; // hints, inactive things
  final Color green; // the main colour: buttons, the current prayer
  final Color onGreen;
  final Color gold; // ornament, Arabic headings, highlights
  final Color blue; // listening
  final Color right;
  final Color wrong;
  final Color flame; // streaks

  const Palette({
    required this.background,
    required this.card,
    required this.sunk,
    required this.border,
    required this.borderStrong,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.green,
    required this.onGreen,
    required this.gold,
    required this.blue,
    required this.right,
    required this.wrong,
    required this.flame,
  });

  static const light = Palette(
    background: Color(0xFFF6F1E7),
    card: Color(0xFFFFFCF5),
    sunk: Color(0xFFF1EADB),
    border: Color(0xFFE6DBC6),
    borderStrong: Color(0xFFD2C2A1),
    ink: Color(0xFF1E2B25),
    muted: Color(0xFF5E6A63),
    faint: Color(0xFF959A90),
    green: Color(0xFF1F4D3A),
    onGreen: Color(0xFFF6F1E7),
    gold: Color(0xFFA9802F),
    blue: Color(0xFF2D6A78),
    right: Color(0xFF2E7D55),
    wrong: Color(0xFFB4473B),
    flame: Color(0xFFD9822B),
  );

  static const dark = Palette(
    background: Color(0xFF111614),
    card: Color(0xFF19201D),
    sunk: Color(0xFF0D1110),
    border: Color(0xFF26302B),
    borderStrong: Color(0xFF3A4640),
    ink: Color(0xFFEFE8D8),
    muted: Color(0xFFAAA696),
    faint: Color(0xFF747A71),
    green: Color(0xFF86BFA0),
    onGreen: Color(0xFF0F1F18),
    gold: Color(0xFFD8B56A),
    blue: Color(0xFF85B9C4),
    right: Color(0xFF6CC08F),
    wrong: Color(0xFFE27C6E),
    flame: Color(0xFFF0A04B),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) => other == null || t < 0.5 ? this : other;
}

extension PaletteOf on BuildContext {
  Palette get palette {
    final theme = Theme.of(this);
    return theme.extension<Palette>() ?? (theme.brightness == Brightness.dark ? Palette.dark : Palette.light);
  }
}

ThemeData appTheme(Brightness brightness) {
  final p = brightness == Brightness.light ? Palette.light : Palette.dark;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    colorScheme: ColorScheme.fromSeed(seedColor: p.green, brightness: brightness).copyWith(
      primary: p.green,
      onPrimary: p.onGreen,
      secondary: p.gold,
      surface: p.background,
      onSurface: p.ink,
      outline: p.borderStrong,
      error: p.wrong,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme).apply(bodyColor: p.ink, displayColor: p.ink),
    appBarTheme: AppBarTheme(
      backgroundColor: p.background,
      foregroundColor: p.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: p.muted),
      actionsIconTheme: IconThemeData(color: p.muted),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.green),
    dividerColor: p.border,
    splashColor: p.gold.withValues(alpha: 0.08),
    highlightColor: p.gold.withValues(alpha: 0.06),
    extensions: [p],
  );
}

/// Titles: Amiri, a book face, for Latin and Arabic alike.
TextStyle displayStyle(double size, {Color? color, FontWeight weight = FontWeight.w700, double? height}) =>
    GoogleFonts.amiri(fontSize: size, color: color, fontWeight: weight, height: height);

/// A panel on the page.
BoxDecoration panel(BuildContext context, {double radius = 18, Color? border}) {
  final p = context.palette;
  return BoxDecoration(
    color: p.card,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: border ?? p.border),
    boxShadow: [
      BoxShadow(color: const Color(0xFF5A4A2A).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2)),
    ],
  );
}

/// A thin gold rule with a small star in the middle.
class Ornament extends StatelessWidget {
  final double width;
  const Ornament({super.key, this.width = 160});

  @override
  Widget build(BuildContext context) {
    final gold = context.palette.gold;
    Widget rule(Alignment from) => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: from,
                end: -from,
                colors: [gold.withValues(alpha: 0), gold.withValues(alpha: 0.7)],
              ),
            ),
          ),
        );
    return SizedBox(
      width: width,
      child: Row(children: [
        rule(Alignment.centerLeft),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CustomPaint(size: const Size.square(12), painter: StarPainter(gold)),
        ),
        rule(Alignment.centerRight),
      ]),
    );
  }
}

/// An eight-pointed star (two overlapping squares), the khatam.
class StarPainter extends CustomPainter {
  final Color color;
  final bool outline;
  const StarPainter(this.color, {this.outline = false});

  static Path star(Offset c, double r) {
    final path = Path();
    for (final turn in [0.0, math.pi / 4]) {
      path.addPolygon([
        for (var i = 0; i < 4; i++)
          c + Offset(math.cos(turn + i * math.pi / 2), math.sin(turn + i * math.pi / 2)) * r,
      ], true);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = outline ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 1;
    canvas.drawPath(star(size.center(Offset.zero), size.shortestSide / 2), paint);
  }

  @override
  bool shouldRepaint(StarPainter old) => old.color != color || old.outline != outline;
}

/// A faint lattice of eight-pointed stars, for behind headers.
class PatternPainter extends CustomPainter {
  final Color color;
  final double cell;
  const PatternPainter(this.color, {this.cell = 44});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height + cell; y += cell) {
      for (var x = 0.0; x < size.width + cell; x += cell) {
        final c = Offset(x, y);
        canvas.drawPath(StarPainter.star(c, cell * 0.36), paint);
        canvas.drawCircle(c, cell * 0.12, paint);
        // Small diamonds between the stars tie the lattice together.
        final d = c + Offset(cell / 2, cell / 2);
        canvas.drawPath(
          Path()..addPolygon([d + Offset(0, -cell * 0.1), d + Offset(cell * 0.1, 0), d + Offset(0, cell * 0.1), d + Offset(-cell * 0.1, 0)], true),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(PatternPainter old) => old.color != color || old.cell != cell;
}
