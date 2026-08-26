import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/quran_model.dart';

class QuranService {
  static const String _baseUrl = 'https://api.alquran.cloud/v1';

  static Future<List<SurahHeader>> fetchSurahList() async {
    final response = await http.get(Uri.parse('$_baseUrl/surah'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List list = data['data'];
      return list.map((item) => SurahHeader.fromJson(item)).toList();
    }
    throw Exception('Failed to load Surahs');
  }

  static Future<SurahDetail> fetchSurahDetail(int surahNumber) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/surah/$surahNumber/editions/quran-uthmani,en.sahih'),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return SurahDetail.fromEditionsJson(data['data']);
    }
    throw Exception('Failed to load Surah verses');
  }
}