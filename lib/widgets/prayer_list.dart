import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_strings.dart';
import '../models/prayer_data.dart';

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
        return Icons.nights_stay;
      case 'sunrise':
        return Icons.wb_sunny_outlined;
      case 'dhuhr':
        return Icons.wb_sunny;
      case 'asr':
        return Icons.wb_twilight;
      case 'maghrib':
        return Icons.bedtime_outlined;
      case 'isha':
        return Icons.dark_mode;
      default:
        return Icons.access_time;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPrayerKey = schedule.currentPrayerKey;
    final nextPrayerKey = schedule.nextPrayerKey;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppStrings.get('next_prayer', language),
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Text(
                AppStrings.get(nextPrayerKey, language),
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        ...schedule.list.map((prayer) {
          final isCurrent = prayer.key == currentPrayerKey;
          final isNext = prayer.key == nextPrayerKey;

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: isCurrent
                  ? const Color(0xFF0F766E).withOpacity(0.35)
                  : const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF14B8A6)
                    : (isNext ? const Color(0xFF38BDF8).withOpacity(0.4) : const Color(0xFF334155)),
                width: isCurrent ? 1.5 : 1.0,
              ),
            ),
            child: ListTile(
              leading: Icon(
                _getIconForPrayer(prayer.key),
                color: isCurrent ? const Color(0xFF2DD4BF) : Colors.white70,
              ),
              title: Text(
                AppStrings.get(prayer.key, language),
                style: TextStyle(
                  color: isCurrent ? const Color(0xFF2DD4BF) : Colors.white,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              trailing: Text(
                DateFormat('hh:mm a').format(prayer.time),
                style: TextStyle(
                  color: isCurrent ? const Color(0xFF2DD4BF) : Colors.white,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}