import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qibla/learn/learn_screen.dart';
import 'package:qibla/learn/lessons.dart';
import 'package:qibla/learn/letters.dart';
import 'package:qibla/learn/progress_store.dart';
import 'package:qibla/learn/round.dart';

// Plays whole rounds of every course on a phone-sized screen by tapping
// whatever the current card offers, to catch crashes and layout overflows.
void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Lets answer timers run and page transitions finish.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  // Scrolls the page until [finder] is on screen, then taps it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.pump();
    await tester.scrollUntilVisible(finder, 200, scrollable: find.byType(Scrollable).last);
    await tester.pump();
    await tester.tap(finder);
    await settle(tester);
  }

  final seenPrompts = <String>{};

  Future<void> playRound(WidgetTester tester, Random random) async {
    for (var step = 0; step < 200; step++) {
      for (final e in find.byType(Eyebrow).evaluate()) {
        final text = (e.widget as Eyebrow).text;
        seenPrompts.add(text.startsWith('Tap the letter') ? 'Tap the letter' : text.split(' (').first);
      }
      if (find.text('Another round').evaluate().isNotEmpty) {
        await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Done'));
        expect(find.byType(RoundScreen), findsNothing);
        return;
      }
      final button = ['Got it', 'Continue'].map(find.text).where((f) => f.evaluate().isNotEmpty).firstOrNull;
      if (button != null) {
        await tapVisible(tester, button);
        continue;
      }
      final card = find.byWidgetPredicate((w) => w is KeyedSubtree && w.key is ValueKey<(String, int)>);
      final targets = [
        ...find.descendant(of: card, matching: find.byType(InkWell)).evaluate(),
        ...find.descendant(of: card, matching: find.byType(GestureDetector)).evaluate(),
      ];
      if (targets.isEmpty) {
        await settle(tester);
        continue;
      }
      await tapVisible(tester, find.byWidget(targets[random.nextInt(targets.length)].widget));
    }
    fail('round did not finish');
  }

  Future<void> openLearn(WidgetTester tester, Map<String, Object> saved) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(saved);
    // Pretend the phone has an Arabic voice, so listening questions come up too.
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(const MethodChannel('flutter_tts'), (call) async => 1);
    messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers'), (call) async => null);
    messenger.setMockMethodCallHandler(const MethodChannel('xyz.luan/audioplayers.global'), (call) async => null);
    await tester.pumpWidget(const MaterialApp(home: LearnScreen()));
    await settle(tester);
    await settle(tester);
  }

  testWidgets('rounds of every course can be played to the end', (tester) async {
    await openLearn(tester, {});
    final random = Random(7);

    // A few alphabet rounds, so later letter groups and question kinds appear.
    for (var i = 0; i < 6; i++) {
      await tapVisible(tester, find.text('Practise letters'));
      await playRound(tester, random);
    }

    for (final unit in ['Short vowels', 'Greetings and basics', 'Meeting people', 'Saying what you do']) {
      for (var i = 0; i < 3; i++) {
        await tapVisible(tester, find.text(unit));
        await playRound(tester, random);
      }
    }

    final store = await ProgressStore.open();
    expect(store.letters(), isNotEmpty);
    expect(store.course('phrases'), isNotEmpty);
    expect(store.streak(), 1);
  });

  testWidgets('every kind of question comes up once things are partly learned', (tester) async {
    String some(Iterable<String> ids) => json.encode({for (final id in ids) id: 3});
    await openLearn(tester, {
      'flutter.learn.letters': some(trainerLetters),
      for (final course in courses)
        'flutter.learn.course.${course.id}': some([for (final u in course.units) for (final i in u.items) i.id]),
    });
    final random = Random(3);
    for (final unit in ['', 'Short vowels', 'Greetings and basics', 'Meeting people', 'Saying what you do']) {
      for (var i = 0; i < 4; i++) {
        await tapVisible(tester, find.text(unit.isEmpty ? 'Practise letters' : unit));
        await playRound(tester, random);
      }
    }
    expect(
      seenPrompts,
      containsAll([
        'Which sound does this letter make?',
        'Which letter is this?',
        'Listen. Which letter did you hear?',
        'Letters change shape inside a word. Which of these is the same letter?',
        'Tap the letter',
        'Match each letter to its name',
        'How is this read?',
        'Which one is read like this?',
        'Match each one to how it is read',
        'What does this word mean?',
        'Which word means this?',
        'How is this read? Look at the vowel marks.',
        'Which word is read like this?',
        'Build the word, first letter first',
        'Match each word to its meaning',
        'What does this mean?',
        'How do you say this?',
        'Put the words in order',
        'Which word is missing?',
        'Listen. What does it mean?',
        'Match each phrase to its meaning',
      ]),
    );
  });
}
