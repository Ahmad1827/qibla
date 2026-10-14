import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/prayer_data.dart';
import '../theme/app_theme.dart';

class QiblaCompass extends StatelessWidget {
  final PrayerSchedule schedule;
  final AppLanguage language;

  const QiblaCompass({
    super.key,
    required this.schedule,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        final heading = snapshot.data?.heading ?? 0.0;
        final difference = (schedule.qiblaAngle - heading + 360) % 360;
        final isAligned = difference < 3 || difference > 357;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
          decoration: panel(context, radius: 22, border: isAligned ? p.right : null),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 236,
                height: 236,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // The dial turns with the phone, so north and the Kaaba
                    // stay where they really are.
                    Transform.rotate(
                      angle: -heading * math.pi / 180,
                      child: CustomPaint(
                        size: const Size.square(224),
                        painter: _DialPainter(
                          palette: p,
                          qiblaAngle: schedule.qiblaAngle,
                          aligned: isAligned,
                          letters: Directionality.of(context) == TextDirection.rtl
                              ? const ['ش', 'ق', 'ج', 'غ']
                              : const ['N', 'E', 'S', 'W'],
                        ),
                      ),
                    ),
                    // Where the phone points.
                    Align(
                      alignment: Alignment.topCenter,
                      child: CustomPaint(
                        size: const Size(18, 12),
                        painter: _PointerPainter(isAligned ? p.right : p.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  isAligned
                      ? AppStrings.get('aligned', language)
                      : '${AppStrings.get('qibla_direction', language)}  ${schedule.qiblaAngle.toStringAsFixed(1)}°',
                  key: ValueKey(isAligned),
                  style: GoogleFonts.plusJakartaSans(
                    color: isAligned ? p.right : p.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${AppStrings.get('distance_to_makkah', language)}  ${schedule.distanceToMakkahKm.toStringAsFixed(0)} ${AppStrings.get('km', language)}',
                style: GoogleFonts.plusJakartaSans(color: p.muted, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DialPainter extends CustomPainter {
  final Palette palette;
  final double qiblaAngle;
  final bool aligned;
  final List<String> letters;
  _DialPainter({required this.palette, required this.qiblaAngle, required this.aligned, required this.letters});

  Offset _at(Offset c, double degrees, double r) {
    final a = (degrees - 90) * math.pi / 180;
    return c + Offset(math.cos(a), math.sin(a)) * r;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final p = palette;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // The face.
    canvas.drawCircle(c, r, Paint()..color = p.sunk);
    canvas.drawCircle(
      c,
      r - 0.75,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = aligned ? p.right : p.borderStrong,
    );
    canvas.drawCircle(
      c,
      r - 30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = p.border,
    );

    // Ticks every 5°, longer every 30°.
    for (var d = 0; d < 360; d += 5) {
      final major = d % 30 == 0;
      canvas.drawLine(
        _at(c, d.toDouble(), r - 6),
        _at(c, d.toDouble(), r - (major ? 16 : 11)),
        Paint()
          ..strokeWidth = major ? 1.6 : 1
          ..strokeCap = StrokeCap.round
          ..color = major ? p.muted : p.borderStrong,
      );
    }

    // North, east, south and west, written upright on the dial.
    for (var i = 0; i < 4; i++) {
      final text = TextPainter(
        text: TextSpan(
          text: letters[i],
          style: GoogleFonts.plusJakartaSans(
            fontSize: i == 0 ? 15 : 13,
            fontWeight: FontWeight.w800,
            color: i == 0 ? p.wrong : p.muted,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = _at(c, i * 90.0, r - 25);
      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.rotate(i * math.pi / 2);
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
    }

    // The needle towards Makkah: a slim gold diamond with the Kaaba at its tip.
    final tip = _at(c, qiblaAngle, r - 44);
    final tail = _at(c, qiblaAngle + 180, 18);
    final side1 = _at(c, qiblaAngle + 90, 7);
    final side2 = _at(c, qiblaAngle - 90, 7);
    final needle = Path()..addPolygon([tip, side1, tail, side2], true);
    canvas.drawPath(needle, Paint()..color = aligned ? p.right : p.gold);

    canvas.save();
    final kaaba = _at(c, qiblaAngle, r - 44);
    canvas.translate(kaaba.dx, kaaba.dy);
    canvas.rotate(qiblaAngle * math.pi / 180);
    final block = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 20, height: 20), const Radius.circular(3));
    canvas.drawRRect(block, Paint()..color = const Color(0xFF1B1B1B));
    canvas.drawRect(const Rect.fromLTWH(-10, -5, 20, 3.2), Paint()..color = const Color(0xFFD8B56A));
    canvas.drawRRect(
      block,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = p.card,
    );
    canvas.restore();

    // The hub: an eight-pointed star.
    canvas.drawPath(StarPainter.star(c, 13), Paint()..color = p.card);
    canvas.drawPath(
      StarPainter.star(c, 13),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = p.gold,
    );
    canvas.drawCircle(c, 3.5, Paint()..color = p.gold);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.qiblaAngle != qiblaAngle || old.aligned != aligned || old.palette != palette || old.letters != letters;
}

class _PointerPainter extends CustomPainter {
  final Color color;
  const _PointerPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()..addPolygon([Offset(0, 0), Offset(size.width, 0), Offset(size.width / 2, size.height)], true),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}
