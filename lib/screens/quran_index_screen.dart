import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/quran_model.dart';
import '../services/quran_service.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F19),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.get('quran', widget.language),
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
      ),
      body: FutureBuilder<List<SurahHeader>>(
        future: _surahListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFE2B970),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                AppStrings.get('error_quran', widget.language),
                style: GoogleFonts.plusJakartaSans(color: Colors.white60),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterSurahs,
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search Surah...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF475569), fontSize: 14),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF475569)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  itemCount: _filteredSurahs.length,
                  itemBuilder: (context, index) {
                    final surah = _filteredSurahs[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF131B2E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0B0F19),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFF334155)),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${surah.number}',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFE2B970),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      surah.englishName,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${surah.englishNameTranslation} • ${surah.numberOfAyahs} ayahs',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF64748B),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                surah.nameArabic,
                                style: GoogleFonts.amiri(
                                  color: const Color(0xFFE2B970),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}