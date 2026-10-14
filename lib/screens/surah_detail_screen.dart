import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../l10n/app_strings.dart';
import '../models/quran_model.dart';
import '../services/quran_service.dart';
import '../theme/app_theme.dart';
import 'quran_index_screen.dart';

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
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 74,
        title: Column(
          children: [
            Text(
              widget.surah.nameArabic,
              style: GoogleFonts.amiri(fontSize: 24, fontWeight: FontWeight.bold, color: p.green, height: 1.3),
            ),
            Text(
              '${widget.surah.englishName} · ${widget.surah.englishNameTranslation}',
              style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: p.muted, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
      body: FutureBuilder<SurahDetail>(
        future: _surahFuture,
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

          final surah = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: surah.ayahs.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (widget.surah.number == 1 || widget.surah.number == 9) {
                  return const SizedBox(height: 8);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 22),
                  child: Column(
                    children: [
                      const Ornament(width: 200),
                      const SizedBox(height: 10),
                      Text(
                        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                        textDirection: TextDirection.rtl,
                        style: GoogleFonts.amiri(fontSize: 27, color: p.green, height: 1.8),
                      ),
                      const SizedBox(height: 6),
                      const Ornament(width: 200),
                    ],
                  ),
                );
              }

              final ayah = surah.ayahs[index - 1];

              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: panel(context, radius: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: StarNumber(ayah.numberInSurah, size: 34),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ayah.textArabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.amiri(color: p.ink, fontSize: 24, height: 2.1),
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: p.border),
                    const SizedBox(height: 12),
                    Text(
                      ayah.textEnglish,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: GoogleFonts.plusJakartaSans(color: p.muted, fontSize: 14, height: 1.6),
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
