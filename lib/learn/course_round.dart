import 'package:flutter/material.dart';
import 'alphabet_round.dart' show roundLength;
import 'letters.dart';
import 'lessons.dart';
import 'progress_store.dart';
import 'round.dart';
import 'speech.dart';

const _shortVowels = 'aiu';
const _longVowels = 'āīū';

/// Wrong ways to read a word: the same consonants with one vowel changed, or
/// made long or short. Only the vowel marks tell them apart from the right one.
List<String> misreadings(String translit, [int count = 3]) {
  final chars = translit.runes.map(String.fromCharCode).toList();
  final variants = <String>{};
  for (var at = 0; at < chars.length; at++) {
    final short = _shortVowels.indexOf(chars[at]);
    final long = _longVowels.indexOf(chars[at]);
    if (short == -1 && long == -1) continue;
    String swapped(String vowel) => [...chars.sublist(0, at), vowel, ...chars.sublist(at + 1)].join();
    for (final vowel in (short == -1 ? _longVowels : _shortVowels).split('')) {
      variants.add(swapped(vowel));
    }
    variants.add(swapped(short == -1 ? _shortVowels[long] : _longVowels[short]));
  }
  variants.remove(translit);
  return shuffled(variants).take(count).toList();
}

/// One round over a unit of a course, or (unit null) over everything met so far.
class CoursePlan extends RoundPlan {
  final ProgressStore store;
  final Course course;
  final Unit? unit;
  final Map<String, int> strengths;
  final Map<LessonItem, Unit> _homeOf = {};
  late final List<LessonItem> items;
  final Set<LessonItem> introduced = {};
  final Set<LessonItem> missed = {};
  int _asked = 0;
  LessonItem? _lastItem;
  Object? _lastKind;
  // A mark is shown on a different consonant in every question.
  (String, String) _carrier = markCarriers.first;

  CoursePlan(this.store, this.course, this.unit) : strengths = store.course(course.id) {
    for (final u in course.units) {
      for (final item in u.items) {
        _homeOf[item] = u;
      }
    }
    final met = _homeOf.keys.where((item) => strengths.containsKey(item.id)).toList();
    items = unit?.items ?? (met.isNotEmpty ? met : course.units.first.items);
    introduced.addAll(met);
  }

  bool get _isMark => course.kind == CourseKind.mark;
  bool get _isPhrase => course.kind == CourseKind.phrase;

  @override
  String get title => unit?.title ?? course.title;
  @override
  int get total => roundLength;
  @override
  int get asked => _asked;

  int _strengthOf(LessonItem item) => strengths[item.id] ?? 0;
  String _arabicOf(LessonItem item) => item is MarkItem ? item.write(_carrier.$1) : item.ar;
  String _readingOf(LessonItem item) => item is MarkItem ? item.read(_carrier.$2) : item.translit;
  String _meaningOf(LessonItem item) => item is MarkItem ? '${item.name}: ${item.about}' : item.meaning;
  List<String> _wordsIn(LessonItem item) => item.ar.replaceAll(RegExp('[؟.!،]'), '').split(' ');
  void _say(LessonItem item) {
    if (!_isMark) Speech.instance.say(item.ar);
  }

  Widget _arabic(LessonItem item, {double? size}) => Text(
        _arabicOf(item),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.center,
        style: arabicStyle(size ?? (_isPhrase ? 20 : 28), height: 1.5),
      );

  void _record(LessonItem item, bool correct) {
    if (!correct) missed.add(item);
    final current = _strengthOf(item);
    strengths[item.id] = correct ? (current + 1).clamp(0, ProgressStore.maxStrength) : current ~/ 2;
    store.answerItem(course.id, item.id, correct);
  }

  // Wrong options: from the same unit first, then earlier units, and later
  // ones only when that leaves too few to choose between.
  List<LessonItem> _rivals(LessonItem item, [int count = 3]) {
    final home = _homeOf[item]!;
    final at = course.units.indexOf(home);
    final near = [...shuffled(home.items), ...shuffled(course.units.take(at).expand((u) => u.items))];
    final far = shuffled(course.units.skip(at + 1).expand((u) => u.items));
    final chosen = <LessonItem>[];
    for (final other in near.length > 2 ? near : [...near, ...far]) {
      if (other != item &&
          _meaningOf(other) != _meaningOf(item) &&
          !chosen.any((c) => _meaningOf(c) == _meaningOf(other))) {
        chosen.add(other);
      }
      if (chosen.length == count) break;
    }
    return chosen;
  }

  // After any answer: show what it was, then move on (at once if it was right).
  void _conclude(RoundControl c, LessonItem item, bool correct) {
    _record(item, correct);
    _say(item);
    c.conclude(
      correct,
      wait: Duration(milliseconds: _isPhrase ? 2200 : 1300),
      reveal: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!correct) _arabic(item, size: _isPhrase ? 24 : 36),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: _readingOf(item), style: uiStyle(14, weight: FontWeight.w700)),
            TextSpan(text: ' · ${_meaningOf(item)}'),
          ]),
          textAlign: TextAlign.center,
          style: uiStyle(14, color: Colors.white70),
        ),
      ]),
    );
  }

  Widget Function(RoundControl) _intro(LessonItem item) => (c) {
        _say(item);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Eyebrow(_isMark ? 'New mark' : _isPhrase ? 'New phrase' : 'New word'),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: _arabic(item, size: _isPhrase ? 30 : 64)),
            if (!_isMark && Speech.instance.canSpeak) ...[
              const SizedBox(width: 8),
              ListenButton(onPressed: () => _say(item)),
            ],
          ]),
          const SizedBox(height: 6),
          Text(_readingOf(item), textAlign: TextAlign.center, style: uiStyle(20, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(_meaningOf(item), textAlign: TextAlign.center, style: uiStyle(15, color: LearnColors.muted)),
          // The same mark on a few other letters.
          if (item is MarkItem) ...[
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 22,
              textDirection: TextDirection.rtl,
              children: [
                for (final (letter, latin) in shuffled(markCarriers.where((m) => m != _carrier)).take(3))
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(item.write(letter), style: arabicStyle(34)),
                    Text(item.read(latin), style: uiStyle(12, color: LearnColors.faint)),
                  ]),
              ],
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Got it',
            onPressed: () {
              introduced.add(item);
              _asked++;
              c.replace(_isMark ? _read(item) : _meaning(item));
            },
          ),
        ]);
      };

  // A question with up to four buttons to choose from.
  Widget Function(RoundControl) _ask<T>(
    LessonItem item, {
    required String title,
    required Widget prompt,
    required List<T> options,
    required T correct,
    required Widget Function(T) label,
    bool wide = false,
    VoidCallback? onShown,
  }) =>
      (c) {
        onShown?.call();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Eyebrow(title),
          prompt,
          const SizedBox(height: 18),
          Choices<T>(
            options: shuffled(options),
            correct: correct,
            label: label,
            wide: wide,
            onPick: (ok) => _conclude(c, item, ok),
          ),
        ]);
      };

  Widget _shown(LessonItem item) => _arabic(item, size: _isPhrase ? 30 : 64);
  Widget _prompt(String text) => Text(text,
      textAlign: TextAlign.center, style: uiStyle(_isPhrase ? 18 : 24, weight: FontWeight.w700));

  // See it written, choose how it is read.
  Widget Function(RoundControl) _read(LessonItem item) => item is MarkItem
      ? _ask<LessonItem>(item,
          title: 'How is this read?',
          prompt: _shown(item),
          options: [item, ..._rivals(item)],
          correct: item,
          label: (o) => TwoLine(_readingOf(o), (o as MarkItem).name))
      : _ask<String>(item,
          title: 'How is this read? Look at the vowel marks.',
          prompt: _shown(item),
          options: [item.translit, ...misreadings(item.translit)],
          correct: item.translit,
          label: (o) => TwoLine(o));

  // See how it is read, choose the one written that way.
  Widget Function(RoundControl) _spelling(LessonItem item) => _ask<LessonItem>(item,
      title: _isMark ? 'Which one is read like this?' : 'Which word is read like this?',
      prompt: _prompt(_readingOf(item)),
      options: [item, ..._rivals(item)],
      correct: item,
      label: _arabic);

  // See the Arabic, choose what it means.
  Widget Function(RoundControl) _meaning(LessonItem item) => _ask<LessonItem>(item,
      title: _isPhrase ? 'What does this mean?' : 'What does this word mean?',
      prompt: _shown(item),
      options: [item, ..._rivals(item)],
      correct: item,
      wide: true,
      label: (o) => Text(o.meaning, style: uiStyle(15)));

  // See the meaning, choose the Arabic.
  Widget Function(RoundControl) _arabicQ(LessonItem item) => _ask<LessonItem>(item,
      title: _isPhrase ? 'How do you say this?' : 'Which word means this?',
      prompt: _prompt(item.meaning),
      options: [item, ..._rivals(item)],
      correct: item,
      wide: _isPhrase,
      label: _arabic);

  // Hear it, choose what it means (or, for a word, which word it was).
  Widget Function(RoundControl) _listen(LessonItem item) {
    final byMeaning = _isPhrase || randomUnit() < 0.5;
    return _ask<LessonItem>(item,
        title: byMeaning ? 'Listen. What does it mean?' : 'Listen. Which word did you hear?',
        prompt: Center(child: ListenButton(size: 44, onPressed: () => _say(item))),
        options: [item, ..._rivals(item)],
        correct: item,
        wide: byMeaning,
        label: (o) => byMeaning ? Text(o.meaning, style: uiStyle(15)) : _arabic(o),
        onShown: () => _say(item));
  }

  // See the meaning, spell the word from its letters.
  Widget Function(RoundControl) _build(LessonItem item) => (c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('Build the word, first letter first (right to left)'),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: _prompt(item.meaning)),
            if (Speech.instance.canSpeak) ListenButton(size: 22, onPressed: () => _say(item)),
          ]),
          const SizedBox(height: 16),
          TileBuilder(
            target: stripMarks(item.ar).runes.map(String.fromCharCode).toList(),
            onDone: (ok) => _conclude(c, item, ok),
          ),
        ],
      );

  // Words of other phrases in the unit that could not be mistaken for one of this phrase's.
  List<String> _strangers(LessonItem item) {
    final own = _wordsIn(item).map(stripMarks).toSet();
    final others = _homeOf[item]!.items.where((o) => o != item).expand(_wordsIn);
    final unique = <String>[];
    for (final word in shuffled(others)) {
      if (!own.contains(stripMarks(word)) && !unique.any((u) => stripMarks(u) == stripMarks(word))) {
        unique.add(word);
      }
    }
    return unique;
  }

  // See the meaning, put the words of the sentence in order.
  Widget Function(RoundControl) _order(LessonItem item) => (c) {
        final count = _wordsIn(item).length;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Eyebrow('Put the words in order ($count words; some tiles do not belong)'),
          _prompt(item.meaning),
          const SizedBox(height: 16),
          TileBuilder(
            target: _wordsIn(item),
            extra: _strangers(item).take(2).toList(),
            joinWith: ' ',
            onDone: (ok) => _conclude(c, item, ok),
          ),
        ]);
      };

  // See the sentence with one word taken out, choose the word that belongs there.
  Widget Function(RoundControl) _gap(LessonItem item) => (c) {
        final parts = _wordsIn(item);
        final at = (randomUnit() * parts.length).floor();
        final shownText = [for (var i = 0; i < parts.length; i++) i == at ? '_____' : parts[i]].join(' ') +
            (item.ar.endsWith('؟') ? '؟' : '');
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Eyebrow('Which word is missing?'),
          Text(shownText, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: arabicStyle(28)),
          const SizedBox(height: 6),
          _prompt(item.meaning),
          const SizedBox(height: 18),
          Choices<String>(
            options: shuffled([parts[at], ..._strangers(item).take(3)]),
            correct: parts[at],
            label: (o) => Text(o, textDirection: TextDirection.rtl, style: arabicStyle(24)),
            onPick: (ok) => _conclude(c, item, ok),
          ),
        ]);
      };

  // Join up a few items with how they are read, or with what they mean.
  Widget Function(RoundControl) _board(List<LessonItem> chosen) => (c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Eyebrow(_isMark
              ? 'Match each one to how it is read'
              : _isPhrase
                  ? 'Match each phrase to its meaning'
                  : 'Match each word to its meaning'),
          MatchBoard<LessonItem>(
            items: chosen,
            left: (item) => _arabic(item, size: _isPhrase ? 15 : 24),
            right: (item) => item is MarkItem
                ? TwoLine(_readingOf(item), item.name)
                : Text(item.meaning, textAlign: TextAlign.center, style: uiStyle(_isPhrase ? 12 : 14)),
            onLeft: _say,
            onPair: (item, firstTry) {
              _record(item, firstTry);
              c.score(firstTry);
            },
            onDone: c.next,
          ),
        ],
      );

  // Chooses what to ask next. Weak items come up more often, new ones are
  // introduced one at a time, and the kind of question keeps changing.
  @override
  Widget Function(RoundControl) nextCard() {
    _carrier = pick(markCarriers);
    final seen = items.where(introduced.contains).toList();
    final firstNew = items.where((i) => !introduced.contains(i)).firstOrNull;

    // Every few questions, a matching board over the weakest items.
    if (seen.length >= 3 && _asked % 5 == 3) {
      _asked++;
      _lastItem = null;
      _lastKind = null;
      final weakest = shuffled(seen)..sort((a, b) => _strengthOf(a).compareTo(_strengthOf(b)));
      return _board(weakest.take(4).toList());
    }

    var candidates = [for (final item in seen) (item, 6 - _strengthOf(item))];
    if (firstNew != null) candidates.add((firstNew, seen.isEmpty ? 1 : 3));
    if (candidates.length > 1) candidates = candidates.where((c) => c.$1 != _lastItem).toList();
    final item = weightedPick(candidates);
    _lastItem = item;
    if (!introduced.contains(item)) return _intro(item);

    _asked++;
    final canSpeak = Speech.instance.canSpeak;
    List<Widget Function(RoundControl) Function(LessonItem)> kinds;
    if (_isMark) {
      kinds = [_read, _spelling];
    } else if (_strengthOf(item) == 0) {
      kinds = [_meaning];
    } else if (_isPhrase) {
      kinds = [_meaning, _arabicQ, _order, _order, _gap];
      if (canSpeak) kinds.add(_listen);
    } else {
      kinds = [_meaning, _arabicQ, _read, _spelling];
      if (canSpeak) kinds.addAll([_listen, _listen]);
      final letters = stripMarks(item.ar).runes.length;
      if (letters >= 2 && letters <= 9) kinds.addAll([_build, _build]);
    }
    // The same kind of question does not come twice running. Method tear-offs
    // of the same method compare equal, so this works across calls.
    if (kinds.length > 1) kinds = kinds.where((k) => k != _lastKind).toList();
    final kind = pick(kinds);
    _lastKind = kind;
    return kind(item);
  }

  @override
  List<Widget> summary(int right, int wrong) {
    final learned = items.where((i) => _strengthOf(i) >= ProgressStore.knownAt).length;
    return [
      Text('$title: $learned of ${items.length} learned.',
          textAlign: TextAlign.center, style: uiStyle(15, color: LearnColors.gold)),
      if (missed.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text('Worth another look:', textAlign: TextAlign.center, style: uiStyle(14, color: LearnColors.muted)),
        const SizedBox(height: 6),
        for (final item in missed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Text.rich(
              TextSpan(children: [
                TextSpan(text: _arabicOf(item), style: arabicStyle(20)),
                TextSpan(text: '  ${_readingOf(item)}${item is MarkItem ? '' : ' · ${item.meaning}'}'),
              ]),
              textAlign: TextAlign.center,
              style: uiStyle(13, color: Colors.white70),
            ),
          ),
      ],
    ];
  }
}
