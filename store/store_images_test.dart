// Draws the Google Play images (phone screenshots and the feature graphic)
// from the real app screens. Needs internet for the Quran text, and the
// google_fonts .ttf files in a folder named Family_weight.ttf (for example
// PlusJakartaSans_700.ttf, from https://fonts.gstatic.com/s/a/<hash>.ttf with
// the hashes in the google_fonts package):
//
//   STORE_FONTS=/path/to/fonts flutter test --update-goldens store/store_images_test.dart
//
// The images are written to store/play/.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qibla/l10n/app_strings.dart';
import 'package:qibla/learn/alphabet_round.dart';
import 'package:qibla/learn/course_round.dart';
import 'package:qibla/learn/learn_screen.dart';
import 'package:qibla/learn/lessons.dart';
import 'package:qibla/learn/letters.dart';
import 'package:qibla/learn/progress_store.dart';
import 'package:qibla/learn/round.dart';
import 'package:qibla/main.dart';
import 'package:qibla/models/quran_model.dart';
import 'package:qibla/screens/surah_detail_screen.dart';
import 'package:qibla/theme/app_theme.dart';

const _p = Palette.light;

Widget _app(Widget home) => MaterialApp(debugShowCheckedModeBanner: false, theme: appTheme(Brightness.light), home: home);

/// A caption over a phone showing the app, running off the bottom edge.
class StoreFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget app;
  const StoreFrame({super.key, required this.title, required this.subtitle, required this.app});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 360,
        height: 640,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFFEFE5D0), _p.background],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: PatternPainter(_p.gold.withValues(alpha: 0.10), cell: 40))),
          Positioned(
            top: 30,
            left: 24,
            right: 24,
            child: Column(children: [
              Text(title, textAlign: TextAlign.center, style: displayStyle(31, color: _p.green, height: 1.15)),
              const SizedBox(height: 4),
              const Ornament(width: 120),
              const SizedBox(height: 6),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: _p.muted, height: 1.4)),
            ]),
          ),
          Positioned(
            top: 152,
            left: 42,
            right: 42,
            child: Container(
              height: 600,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2B25),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: const Color(0xFF3A4640), width: 1.5),
                boxShadow: [BoxShadow(color: const Color(0xFF5A4A2A).withValues(alpha: 0.30), blurRadius: 30, offset: const Offset(0, 14))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(29),
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  child: SizedBox(width: 360, height: 800, child: app),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

int _today() {
  final now = DateTime.now();
  return DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/ 86400000;
}

String _strengths(Iterable<String> ids, int strength) => '{${ids.map((id) => '"$id":$strength').join(',')}}';

void main() {
  setUpAll(() async {
    HttpOverrides.global = null; // real network, for the Quran text
    GoogleFonts.config.allowRuntimeFetching = false;
    final flutterRoot = Platform.environment['FLUTTER_ROOT'] ?? '/home/ahmad/development/flutter';
    final fonts = '$flutterRoot/bin/cache/artifacts/material_fonts';
    Future<void> load(String family, List<String> files) async {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(File('$fonts/$f').readAsBytes().then((b) => ByteData.sublistView(b)));
      }
      await loader.load();
    }

    await load('Roboto', ['Roboto-Regular.ttf', 'Roboto-Medium.ttf', 'Roboto-Bold.ttf']);
    await load('MaterialIcons', ['MaterialIcons-Regular.otf']);
    // The fonts the app gets from Google Fonts, under the names google_fonts gives them.
    for (final file in Directory(Platform.environment['STORE_FONTS']!).listSync().whereType<File>()) {
      final loader = FontLoader(file.uri.pathSegments.last.replaceAll('.ttf', ''))
        ..addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
      await loader.load();
    }
  });

  Future<void> setUp(WidgetTester tester, {Size logical = const Size(360, 640), double ratio = 3}) async {
    tester.view.devicePixelRatio = ratio;
    tester.view.physicalSize = logical * ratio;
    addTearDown(tester.view.reset);
    // Sounds have no player here; that is fine for pictures.
    final reportError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exception is! MissingPluginException) reportError?.call(details);
    };
    addTearDown(() => FlutterError.onError = reportError);

    // Someone a week into learning: the first letter groups known, a few
    // words and phrases met.
    final words = courses[1].units;
    final phrases = courses[2].units;
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'flutter.learn.letters': _strengths([for (final g in alphabetGroups.take(3)) ...g.letters], 4),
      'flutter.learn.course.marks': _strengths([for (final i in courses[0].units.first.items) i.id], 4),
      'flutter.learn.course.words': _strengths([...words[0].items.map((i) => i.id), ...words[1].items.take(6).map((i) => i.id)], 2),
      'flutter.learn.course.phrases': _strengths(phrases[0].items.map((i) => i.id), 2),
      'flutter.learn.days': [for (var d = 0; d < 7; d++) '${_today() - d}'],
    });

    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    // Bucharest, with the phone held towards Makkah.
    messenger.setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/geolocator'), (call) async {
      switch (call.method) {
        case 'isLocationServiceEnabled':
          return true;
        case 'checkPermission':
          return 3;
        case 'getCurrentPosition':
          return {
            'latitude': 44.4268,
            'longitude': 26.1025,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'accuracy': 5.0,
            'altitude': 70.0,
            'altitude_accuracy': 1.0,
            'heading': 0.0,
            'heading_accuracy': 1.0,
            'speed': 0.0,
            'speed_accuracy': 0.0,
            'is_mocked': false,
          };
      }
      return null;
    });
    messenger.setMockStreamHandler(
      const EventChannel('hemanthraj/flutter_compass'),
      MockStreamHandler.inline(onListen: (args, sink) => sink.success(<double>[149.0, 149.0, 0.0])),
    );
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async => 1);
    messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => null);
  }

  /// Lets fonts and network requests finish for real, then draws.
  Future<void> waitForReal(WidgetTester tester, [Duration extra = const Duration(seconds: 2)]) async {
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(extra));
      await tester.pump(const Duration(seconds: 1));
    }
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  Future<void> shoot(String name) =>
      expectLater(find.byType(StoreFrame), matchesGoldenFile('play/$name.png'));

  /// Opens fresh rounds until one starts with the wanted question.
  Future<void> roundShowing(WidgetTester tester, String title, String subtitle, RoundPlan Function(ProgressStore) plan,
      String prompt) async {
    final store = await tester.runAsync(ProgressStore.open);
    for (var attempt = 0; attempt < 200; attempt++) {
      await tester.pumpWidget(StoreFrame(
        title: title,
        subtitle: subtitle,
        app: _app(RoundScreen(key: ValueKey(attempt), makePlan: () => plan(store!))),
      ));
      await tester.pump();
      if (find.textContaining(prompt).evaluate().isNotEmpty) return;
    }
    fail('never got "$prompt"');
  }

  testWidgets('1 prayer times and qibla', (tester) async {
    await setUp(tester);
    await tester.pumpWidget(const StoreFrame(
      title: 'Prayer times & Qibla',
      subtitle: 'Accurate times for where you are, and a compass that points to Makkah',
      app: QiblaApp(),
    ));
    await waitForReal(tester);
    tester.widget<HomeScreen>(find.byType(HomeScreen)).onToggleLanguage(); // to English
    await waitForReal(tester);
    await shoot('screenshot-1-prayer-qibla');
  });

  testWidgets('2 learn home', (tester) async {
    await setUp(tester);
    await tester.pumpWidget(const StoreFrame(
      title: 'Learn Arabic every day',
      subtitle: 'Short lessons that work offline, with a daily streak and your progress',
      app: LearnScreenApp(),
    ));
    await waitForReal(tester);
    await shoot('screenshot-2-learn');
  });

  testWidgets('3 alphabet', (tester) async {
    await setUp(tester);
    await roundShowing(tester, 'Master the alphabet', 'Letters taught a few at a time, with real recordings of each one',
        AlphabetPlan.new, 'New letter');
    await waitForReal(tester);
    await shoot('screenshot-3-alphabet');
  });

  testWidgets('4 words', (tester) async {
    await setUp(tester);
    await roundShowing(
      tester,
      'Build your vocabulary',
      'Everyday and Quranic words: what they mean, how they are read and how they sound',
      (store) => CoursePlan(store, courses[1], courses[1].units[0]),
      'What does this word mean?',
    );
    await waitForReal(tester);
    await shoot('screenshot-4-words');
  });

  testWidgets('5 phrases', (tester) async {
    await setUp(tester);
    await roundShowing(
      tester,
      'Speak in sentences',
      'Put real phrases together word by word',
      (store) => CoursePlan(store, courses[2], courses[2].units[0]),
      'Put the words in order',
    );
    // Start the sentence: tap its first two words.
    final item = courses[2].units[0].items.firstWhere((i) => find.text(i.meaning).evaluate().isNotEmpty);
    final words = item.ar.replaceAll(RegExp('[؟.!،]'), '').split(' ');
    for (final word in words.take(words.length > 2 ? 2 : 1)) {
      await tester.tap(find.descendant(of: find.byType(TileBuilder), matching: find.text(word)).first);
      await tester.pump();
    }
    await waitForReal(tester);
    await shoot('screenshot-5-phrases');
  });

  testWidgets('6 quran', (tester) async {
    await setUp(tester);
    const url = 'https://api.alquran.cloud/v1/surah/1/editions/quran-uthmani,en.sahih';
    final body = await tester.runAsync(() async {
      final client = HttpClient();
      final response = await (await client.getUrl(Uri.parse(url))).close();
      return response.transform(utf8.decoder).join();
    });
    final quran = MockClient((request) async => http.Response(body!, 200, headers: {'content-type': 'application/json; charset=utf-8'}));
    await http.runWithClient(() => tester.pumpWidget(StoreFrame(
      title: 'Read the Holy Quran',
      subtitle: 'The Arabic text with an English translation, surah by surah',
      app: _app(SurahDetailScreen(
        language: AppLanguage.english,
        surah: SurahHeader(
          number: 1,
          nameArabic: 'سُورَةُ ٱلْفَاتِحَةِ',
          englishName: 'Al-Faatiha',
          englishNameTranslation: 'The Opening',
          numberOfAyahs: 7,
          revelationType: 'Meccan',
        ),
      )),
    )), () => quran);
    await waitForReal(tester);
    await shoot('screenshot-6-quran');
  });

  testWidgets('feature graphic', (tester) async {
    await setUp(tester, logical: const Size(512, 250), ratio: 2);
    final icon = await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(File('assets/icon/qiblaicon.png').readAsBytesSync());
      return (await codec.getNextFrame()).image;
    });
    await tester.pumpWidget(FeatureGraphic(icon: icon!));
    await waitForReal(tester);
    await expectLater(find.byType(FeatureGraphic), matchesGoldenFile('play/feature-graphic-1024x500.png'));
  });
}

class LearnScreenApp extends StatelessWidget {
  const LearnScreenApp({super.key});
  @override
  Widget build(BuildContext context) => _app(const LearnScreen());
}

/// The 1024 x 500 banner Google Play shows above the listing.
class FeatureGraphic extends StatelessWidget {
  final ui.Image icon;
  const FeatureGraphic({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        width: 512,
        height: 250,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF285E48), _p.green],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: PatternPainter(_p.onGreen.withValues(alpha: 0.07), cell: 40))),
          // Large faint calligraphy behind everything.
          Positioned(
            right: -6,
            top: 30,
            child: Text('ٱلْعَرَبِيَّة',
                textDirection: TextDirection.rtl,
                style: GoogleFonts.amiri(fontSize: 110, color: const Color(0xFFD8B56A).withValues(alpha: 0.16), height: 1.4)),
          ),
          Positioned.fill(
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Row(children: [
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _p.card,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFD8B56A), width: 1.5),
                ),
                child: RawImage(image: icon, filterQuality: FilterQuality.high),
              ),
              const SizedBox(width: 28),
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Qibla, Prayer & Arabic', style: displayStyle(36, color: _p.onGreen, height: 1.1)),
                  const SizedBox(height: 10),
                  Text('Prayer times, a Qibla compass, the Quran and daily Arabic lessons in one app.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: _p.onGreen.withValues(alpha: 0.8), height: 1.4)),
                  const SizedBox(height: 14),
                  Row(children: [
                    for (final (icon, label, color) in [
                      (Icons.access_time_rounded, 'Prayer', const Color(0xFFD8B56A)),
                      (Icons.explore_rounded, 'Qibla', const Color(0xFFD8B56A)),
                      (Icons.menu_book_rounded, 'Quran', const Color(0xFFD8B56A)),
                      (Icons.school_rounded, 'Learn', const Color(0xFFD8B56A)),
                    ]) ...[
                      Icon(icon, size: 15, color: color),
                      const SizedBox(width: 4),
                      Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
                      const SizedBox(width: 12),
                    ],
                  ]),
                ]),
              ),
            ]),
            ),
          ),
        ]),
      ),
    );
  }
}
