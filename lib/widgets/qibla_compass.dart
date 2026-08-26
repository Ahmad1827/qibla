import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../l10n/app_strings.dart';
import '../models/prayer_data.dart';

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
    return StreamBuilder<CompassEvent>(
      stream: FlutterCompass.events,
      builder: (context, snapshot) {
        final heading = snapshot.data?.heading ?? 0.0;
        final difference = (schedule.qiblaAngle - heading + 360) % 360;
        final isAligned = difference < 3 || difference > 357;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: (-heading * (math.pi / 180)),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1E293B),
                      border: Border.all(
                        color: isAligned ? Colors.greenAccent : const Color(0xFF334155),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isAligned
                              ? Colors.greenAccent.withOpacity(0.3)
                              : Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: const [
                        Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Text(
                              'N',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Text(
                              'E',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Text(
                              'S',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.all(6.0),
                            child: Text(
                              'W',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: ((schedule.qiblaAngle - heading) * (math.pi / 180)),
                  child: SizedBox(
                    width: 170,
                    height: 170,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          size: 46,
                          color: isAligned ? Colors.greenAccent : const Color(0xFFFBBF24),
                        ),
                        const Spacer(),
                        Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBBF24),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF475569), width: 2),
                  ),
                  child: const Icon(
                    Icons.mosque,
                    color: Color(0xFF38BDF8),
                    size: 26,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isAligned
                  ? AppStrings.get('aligned', language)
                  : '${AppStrings.get('qibla_direction', language)}: ${schedule.qiblaAngle.toStringAsFixed(1)}°',
              style: TextStyle(
                color: isAligned ? Colors.greenAccent : Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${AppStrings.get('distance_to_makkah', language)}: ${schedule.distanceToMakkahKm.toStringAsFixed(0)} ${AppStrings.get('km', language)}',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
    );
  }
}