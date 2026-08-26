import 'package:adhan/adhan.dart';

class PrayerItem {
  final String key;
  final DateTime time;

  PrayerItem({required this.key, required this.time});
}

class PrayerSchedule {
  final PrayerTimes prayerTimes;
  final double qiblaAngle;
  final double distanceToMakkahKm;

  PrayerSchedule({
    required this.prayerTimes,
    required this.qiblaAngle,
    required this.distanceToMakkahKm,
  });

  List<PrayerItem> get list => [
        PrayerItem(key: 'fajr', time: prayerTimes.fajr),
        PrayerItem(key: 'sunrise', time: prayerTimes.sunrise),
        PrayerItem(key: 'dhuhr', time: prayerTimes.dhuhr),
        PrayerItem(key: 'asr', time: prayerTimes.asr),
        PrayerItem(key: 'maghrib', time: prayerTimes.maghrib),
        PrayerItem(key: 'isha', time: prayerTimes.isha),
      ];

  String get nextPrayerKey {
    switch (prayerTimes.nextPrayer()) {
      case Prayer.fajr:
        return 'fajr';
      case Prayer.sunrise:
        return 'sunrise';
      case Prayer.dhuhr:
        return 'dhuhr';
      case Prayer.asr:
        return 'asr';
      case Prayer.maghrib:
        return 'maghrib';
      case Prayer.isha:
        return 'isha';
      default:
        return 'fajr';
    }
  }

  String get currentPrayerKey {
    switch (prayerTimes.currentPrayer()) {
      case Prayer.fajr:
        return 'fajr';
      case Prayer.sunrise:
        return 'sunrise';
      case Prayer.dhuhr:
        return 'dhuhr';
      case Prayer.asr:
        return 'asr';
      case Prayer.maghrib:
        return 'maghrib';
      case Prayer.isha:
        return 'isha';
      default:
        return '';
    }
  }
}