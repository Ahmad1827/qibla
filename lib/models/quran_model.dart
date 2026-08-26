class SurahHeader {
  final int number;
  final String nameArabic;
  final String englishName;
  final String englishNameTranslation;
  final int numberOfAyahs;
  final String revelationType;

  SurahHeader({
    required this.number,
    required this.nameArabic,
    required this.englishName,
    required this.englishNameTranslation,
    required this.numberOfAyahs,
    required this.revelationType,
  });

  factory SurahHeader.fromJson(Map<String, dynamic> json) {
    return SurahHeader(
      number: json['number'] as int,
      nameArabic: json['name'] as String,
      englishName: json['englishName'] as String,
      englishNameTranslation: json['englishNameTranslation'] as String,
      numberOfAyahs: json['numberOfAyahs'] as int,
      revelationType: json['revelationType'] as String? ?? '',
    );
  }
}

class AyahDual {
  final int numberInSurah;
  final String textArabic;
  final String textEnglish;

  AyahDual({
    required this.numberInSurah,
    required this.textArabic,
    required this.textEnglish,
  });
}

class SurahDetail {
  final int number;
  final String nameArabic;
  final String englishName;
  final String englishNameTranslation;
  final List<AyahDual> ayahs;

  SurahDetail({
    required this.number,
    required this.nameArabic,
    required this.englishName,
    required this.englishNameTranslation,
    required this.ayahs,
  });

  factory SurahDetail.fromEditionsJson(List<dynamic> dataList) {
    final arabicData = dataList[0];
    final englishData = dataList[1];

    final arabicAyahs = arabicData['ayahs'] as List;
    final englishAyahs = englishData['ayahs'] as List;

    List<AyahDual> dualAyahs = [];
    for (int i = 0; i < arabicAyahs.length; i++) {
      dualAyahs.add(
        AyahDual(
          numberInSurah: arabicAyahs[i]['numberInSurah'] as int,
          textArabic: arabicAyahs[i]['text'] as String,
          textEnglish: i < englishAyahs.length ? englishAyahs[i]['text'] as String : '',
        ),
      );
    }

    return SurahDetail(
      number: arabicData['number'] as int,
      nameArabic: arabicData['name'] as String,
      englishName: arabicData['englishName'] as String,
      englishNameTranslation: arabicData['englishNameTranslation'] as String,
      ayahs: dualAyahs,
    );
  }
}