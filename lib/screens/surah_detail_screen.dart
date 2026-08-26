import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/quran_model.dart';
import '../services/quran_service.dart';

class SurahDetailScreen extends StatefulWidget {
  final SurahHeader surah;
  final AppLanguage language;

  const SurahDetailScreen({
    super.key,
    required this.surah,
    required this.language,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late Future<SurahDetail> _surahFuture;

  @override
  void initState() {
    super.initState();
    _surahFuture = QuranService.fetchSurahDetail(widget.surah.number);
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
        title: Column(
          children: [
            Text(
              widget.surah.nameArabic,
              style: GoogleFonts.amiri(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE2B970),
              ),
            ),
            Text(
              '${widget.surah.englishName} • ${widget.surah.englishNameTranslation}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<SurahDetail>(
        future: _surahFuture,
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

          final surah = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            itemCount: surah.ayahs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (widget.surah.number == 1 || widget.surah.number == 9) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131B2E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: Center(
                    child: Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: GoogleFonts.amiri(
                        fontSize: 24,
                        color: const Color(0xFFE2B970),
                      ),
                    ),
                  ),
                );
              }

              final ayah = surah.ayahs[index - 1];

              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0B0F19),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${ayah.numberInSurah}',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFE2B970),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.share_outlined,
                          size: 16,
                          color: Color(0xFF475569),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        ayah.textArabic,
                        style: GoogleFonts.amiri(
                          color: const Color(0xFFF8FAFC),
                          fontSize: 22,
                          height: 2.1,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      height: 1,
                      color: const Color(0xFF1E293B),
                    ),
                    const SizedBox(height: 14),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        ayah.textEnglish,
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF94A3B8),
                          fontSize: 14,
                          height: 1.6,
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}