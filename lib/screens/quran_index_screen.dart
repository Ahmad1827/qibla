import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/quran_model.dart';
import '../services/quran_service.dart';
import '../theme/app_theme.dart';
import 'surah_detail_screen.dart';

class QuranIndexScreen extends StatefulWidget {
  final AppLanguage language;

  const QuranIndexScreen({super.key, required this.language});

  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

class _QuranIndexScreenState extends State<QuranIndexScreen> {
  late Future<List<SurahHeader>> _surahListFuture;
  List<SurahHeader> _allSurahs = [];
  List<SurahHeader> _filteredSurahs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _surahListFuture = QuranService.fetchSurahList().then((list) {
      _allSurahs = list;
      _filteredSurahs = list;
      return list;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterSurahs(String query) {
    setState(() {
      _filteredSurahs = _allSurahs.where((s) {
        final q = query.toLowerCase();
        return s.englishName.toLowerCase().contains(q) ||
            s.nameArabic.contains(q) ||
            s.number.toString() == q;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.get('quran', widget.language),
          style: displayStyle(22, color: p.green),
        ),
      ),
      body: FutureBuilder<List<SurahHeader>>(
        future: _surahListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppStrings.get('error_quran', widget.language),
                style: GoogleFonts.plusJakartaSans(color: p.muted),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: p.sunk,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSurahs,
                    cursorColor: p.green,
                    style: GoogleFonts.plusJakartaSans(color: p.ink, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: AppStrings.get('search_surah', widget.language),
                      hintStyle: GoogleFonts.plusJakartaSans(color: p.faint, fontSize: 14),
                      prefixIcon: Icon(Icons.search, size: 19, color: p.faint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: _filteredSurahs.length,
                  itemBuilder: (context, index) => _surahRow(_filteredSurahs[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _surahRow(SurahHeader surah) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: panel(context, radius: 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailScreen(
                surah: surah,
                language: widget.language,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
          child: Row(
            children: [
              StarNumber(surah.number, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.englishName,
                      style: GoogleFonts.plusJakartaSans(color: p.ink, fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${surah.englishNameTranslation} · ${surah.numberOfAyahs} ${AppStrings.get('ayahs', widget.language)}',
                      style: GoogleFonts.plusJakartaSans(color: p.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                surah.nameArabic,
                style: GoogleFonts.amiri(color: p.green, fontWeight: FontWeight.bold, fontSize: 21),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A number inside an eight-pointed star, the way a mushaf marks surahs and verses.
class StarNumber extends StatelessWidget {
  final int number;
  final double size;
  const StarNumber(this.number, {super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: StarPainter(p.gold, outline: true),
        child: Center(
          child: Text(
            '$number',
            style: GoogleFonts.plusJakartaSans(
              color: p.ink,
              fontWeight: FontWeight.w700,
              fontSize: number > 99 ? size * 0.25 : size * 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
