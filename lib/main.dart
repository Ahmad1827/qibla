import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/app_strings.dart';
import 'models/prayer_data.dart';
import 'screens/quran_index_screen.dart';
import 'services/location_service.dart';
import 'widgets/prayer_list.dart';
import 'widgets/qibla_compass.dart';

void main() {
  runApp(const QiblaApp());
}

class QiblaApp extends StatefulWidget {
  const QiblaApp({super.key});

  @override
  State<QiblaApp> createState() => _QiblaAppState();
}

class _QiblaAppState extends State<QiblaApp> {
  AppLanguage _currentLanguage = AppLanguage.arabic;

  void _toggleLanguage() {
    setState(() {
      _currentLanguage = _currentLanguage == AppLanguage.arabic
          ? AppLanguage.english
          : AppLanguage.arabic;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _currentLanguage == AppLanguage.arabic;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0F19),
          elevation: 0,
        ),
      ),
      home: Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: HomeScreen(
          language: _currentLanguage,
          onToggleLanguage: _toggleLanguage,
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final AppLanguage language;
  final VoidCallback onToggleLanguage;

  const HomeScreen({
    super.key,
    required this.language,
    required this.onToggleLanguage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PrayerSchedule? _schedule;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final schedule = await LocationService.fetchPrayerSchedule();
      setState(() {
        _schedule = schedule;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.language == AppLanguage.arabic;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        title: Text(
          AppStrings.get('app_title', widget.language),
          style: isArabic
              ? GoogleFonts.amiri(fontWeight: FontWeight.bold, fontSize: 20)
              : GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF94A3B8)),
            onPressed: _loadData,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFF131B2E).withOpacity(0.85),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF1E293B)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuranIndexScreen(
                          language: widget.language,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.menu_book_rounded, size: 18, color: Color(0xFFE2B970)),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.get('quran', widget.language),
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFE2B970),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: const Color(0xFF1E293B),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: widget.onToggleLanguage,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.translate_rounded, size: 18, color: Color(0xFF38BDF8)),
                        const SizedBox(width: 8),
                        Text(
                          widget.language == AppLanguage.arabic ? 'English' : 'عربي',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF38BDF8),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFFE2B970),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, size: 48, color: Color(0xFFF43F5E)),
              const SizedBox(height: 12),
              Text(
                AppStrings.get('error_location', widget.language),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderParity(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadData,
                child: Text(
                  AppStrings.get('retry', widget.language),
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFFE2B970)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 16.0, bottom: 20.0),
      children: [
        QiblaCompass(
          schedule: _schedule!,
          language: widget.language,
        ),
        const SizedBox(height: 20),
        PrayerList(
          schedule: _schedule!,
          language: widget.language,
        ),
      ],
    );
  }
}

class BorderParity extends BorderSide {
  const BorderParity() : super(color: const Color(0xFFE2B970), width: 1);
}