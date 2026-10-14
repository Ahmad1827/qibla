import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'l10n/app_strings.dart';
import 'learn/learn_screen.dart';
import 'models/prayer_data.dart';
import 'screens/quran_index_screen.dart';
import 'services/location_service.dart';
import 'theme/app_theme.dart';
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
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
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
    final p = context.palette;
    final isArabic = widget.language == AppLanguage.arabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.get('app_title', widget.language),
          style: displayStyle(isArabic ? 22 : 21, color: p.green),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _loadData,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          height: 60,
          decoration: panel(context, radius: 30),
          // Shrinks to fit narrow phones (the Arabic labels are long).
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _NavItem(
                  icon: Icons.menu_book_rounded,
                  label: AppStrings.get('quran', widget.language),
                  color: p.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => QuranIndexScreen(language: widget.language)),
                  ),
                ),
                _divider(p),
                _NavItem(
                  icon: Icons.school_rounded,
                  label: AppStrings.get('learn', widget.language),
                  color: p.gold,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LearnScreen()),
                  ),
                ),
                _divider(p),
                _NavItem(
                  icon: Icons.translate_rounded,
                  label: isArabic ? 'English' : 'عربي',
                  color: p.blue,
                  onTap: widget.onToggleLanguage,
                ),
              ],
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _divider(Palette p) => Container(width: 1, height: 24, color: p.border);

  Widget _buildBody() {
    final p = context.palette;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off_outlined, size: 48, color: p.wrong),
              const SizedBox(height: 12),
              Text(
                AppStrings.get('error_location', widget.language),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(color: p.muted, fontSize: 14),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _loadData,
                child: Text(
                  AppStrings.get('retry', widget.language),
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(top: 4.0, bottom: 20.0),
      children: [
        _NextPrayerCard(schedule: _schedule!, language: widget.language),
        const SizedBox(height: 16),
        QiblaCompass(
          schedule: _schedule!,
          language: widget.language,
        ),
        const SizedBox(height: 16),
        PrayerList(
          schedule: _schedule!,
          language: widget.language,
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(color: color, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}

/// The prayer coming up, its time and how long until it, on a green panel.
class _NextPrayerCard extends StatelessWidget {
  final PrayerSchedule schedule;
  final AppLanguage language;
  const _NextPrayerCard({required this.schedule, required this.language});

  @override
  Widget build(BuildContext context) {
    // Deep green with cream lettering in light and dark mode alike.
    const p = Palette.light;
    final key = schedule.nextPrayerKey;
    var time = schedule.list.firstWhere((prayer) => prayer.key == key).time;
    final now = DateTime.now();
    // After isha the next prayer is tomorrow's fajr; today's is close enough.
    if (time.isBefore(now)) time = time.add(const Duration(days: 1));
    final left = time.difference(now);
    final hours = left.inHours;
    final minutes = left.inMinutes % 60;
    final countdown = [
      AppStrings.get('in', language),
      if (hours > 0) '$hours ${AppStrings.get('hours_short', language)}',
      '$minutes ${AppStrings.get('minutes_short', language)}',
    ].join(' ');
    final isArabic = language == AppLanguage.arabic;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: p.green,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: p.green.withValues(alpha: 0.18), blurRadius: 14, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: PatternPainter(p.onGreen.withValues(alpha: 0.07))),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get('next_prayer', language).toUpperCase(),
                          style: GoogleFonts.plusJakartaSans(
                            color: p.onGreen.withValues(alpha: 0.75),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: isArabic ? 0 : 1.4,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.get(key, language),
                          style: displayStyle(34, color: p.onGreen, height: 1.3),
                        ),
                        Text(
                          countdown,
                          style: GoogleFonts.plusJakartaSans(color: p.onGreen.withValues(alpha: 0.8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    DateFormat('hh:mm a').format(time),
                    style: GoogleFonts.plusJakartaSans(
                      color: p.onGreen,
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
