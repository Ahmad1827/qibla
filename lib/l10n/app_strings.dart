enum AppLanguage { arabic, english }

class AppStrings {
  static const Map<AppLanguage, Map<String, String>> _strings = {
    AppLanguage.arabic: {
      'app_title': 'القبلة ومواقيت الصلاة',
      'quran': 'القرآن الكريم',
      'surahs': 'السور',
      'verses': 'آيات',
      'fajr': 'الفجر',
      'sunrise': 'الشروق',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
      'next_prayer': 'الصلاة القادمة',
      'qibla_direction': 'اتجاه القبلة',
      'distance_to_makkah': 'المسافة إلى مكة',
      'km': 'كم',
      'locating': 'جاري تحديد الموقع...',
      'error_location': 'تعذر الحصول على الموقع',
      'error_quran': 'تعذر تحميل القرآن الكريم',
      'retry': 'إعادة المحاولة',
      'aligned': 'أنت باتجاه القبلة',
      'bismillah': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    },
    AppLanguage.english: {
      'app_title': 'Qibla & Prayer Times',
      'quran': 'Holy Quran',
      'surahs': 'Surahs',
      'verses': 'Verses',
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
      'next_prayer': 'Next Prayer',
      'qibla_direction': 'Qibla Direction',
      'distance_to_makkah': 'Distance to Makkah',
      'km': 'km',
      'locating': 'Acquiring location...',
      'error_location': 'Unable to acquire location',
      'error_quran': 'Failed to load Quran data',
      'retry': 'Retry',
      'aligned': 'Facing Qibla',
      'bismillah': 'In the name of Allah, Most Gracious, Most Merciful',
    },
  };

  static String get(String key, AppLanguage lang) {
    return _strings[lang]?[key] ?? key;
  }
}