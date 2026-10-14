import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/prayer_data.dart';
import '../theme/app_theme.dart';

class PrayerList extends StatelessWidget {
  final PrayerSchedule schedule;
  final AppLanguage language;

  const PrayerList({
    super.key,
    required this.schedule,
    required this.language,
  });

  IconData _getIconForPrayer(String key) {
    switch (key) {
      case 'fajr':
        return Icons.nights_stay_outlined;
      case 'sunrise':
        return Icons.wb_twilight_rounded;
      case 'dhuhr':
        return Icons.wb_sunny_outlined;
      case 'asr':
        return Icons.sunny_snowing;
      case 'maghrib':
        return Icons.bedtime_outlined;
      case 'isha':
        return Icons.dark_mode_outlined;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final currentPrayerKey = schedule.currentPrayerKey;
    final nextPrayerKey = schedule.nextPrayerKey;
    final prayers = schedule.list;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: panel(context, radius: 22),
      child: Column(
        children: [
          for (var i = 0; i < prayers.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 20, endIndent: 20, color: p.border),
            _row(context, prayers[i], prayers[i].key == currentPrayerKey, prayers[i].key == nextPrayerKey),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, PrayerItem prayer, bool isCurrent, bool isNext) {
    final p = context.palette;
    final color = isCurrent ? p.green : p.ink;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrent ? p.green.withValues(alpha: 0.09) : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(_getIconForPrayer(prayer.key), size: 21, color: isCurrent ? p.green : p.gold),
          const SizedBox(width: 14),
          Text(
            AppStrings.get(prayer.key, language),
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15.5,
            ),
          ),
          const SizedBox(width: 8),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: p.green, borderRadius: BorderRadius.circular(10)),
              child: Text(
                AppStrings.get('now', language),
                style: GoogleFonts.plusJakartaSans(color: p.onGreen, fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            )
          else if (isNext)
            Icon(Icons.circle, size: 7, color: p.gold),
          const Spacer(),
          Text(
            DateFormat('hh:mm a').format(prayer.time),
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              fontSize: 15.5,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
