import 'package:flutter/material.dart';
import 'letters.dart';
import 'progress_store.dart';
import 'round.dart';
import 'speech.dart';

const int unlockAt = 2; // strength every letter needs before the next group opens
const int roundLength = 10;

/// How many letter groups are open: the first, plus each next one once all
/// letters before it have been answered correctly a couple of times.
int unlockedGroups(Map<String, int> strengths) {
  var open = 1;
  while (open < alphabetGroups.length &&
      alphabetGroups.take(open).every((g) => g.letters.every((l) => (strengths[l] ?? 0) >= unlockAt))) {
    open++;
  }
  return open;
}

/// The four shapes of a letter side by side.
class FormsRow extends StatelessWidget {
  final String letter;
  const FormsRow(this.letter, {super.key});

  @override
  Widget build(BuildContext context) => Wrap(
        alignment: WrapAlignment.center,
        spacing: 18,
        runSpacing: 8,
        textDirection: TextDirection.rtl,
        children: [
          for (final form in letterForms(letter))
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text(form.text, style: arabicStyle(34)),
              Text(form.where, style: uiStyle(11, color: LearnColors.faint)),
            ]),
        ],
      );
}

class AlphabetPlan extends RoundPlan {
  final ProgressStore store;
  final Map<String, int> strengths;
  final Set<String> introduced;
  final int openAtStart;
  final Set<String> missed = {};
  int _asked = 0;
  String? _lastLetter;

  AlphabetPlan(this.store)
      : strengths = store.letters(),
        introduced = store.letters().keys.toSet(),
        openAtStart = unlockedGroups(store.letters());

  @override
  String get title => 'Alphabet';
  @override
  int get total => roundLength;
  @override
  int get asked => _asked;

  List<String> get _unlocked => [for (final g in alphabetGroups.take(unlockedGroups(strengths))) ...g.letters];

  // Wrong options: look-alikes from the same group first, then other letters.
  List<String> _rivals(String letter, [int count = 3]) {
    final group = alphabetGroups.firstWhere((g) => g.letters.contains(letter)).letters;
    return {...shuffled(group), ...shuffled(_unlocked), ...shuffled(trainerLetters)}
        .where((l) => l != letter)
        .take(count)
        .toList();
  }

  void _record(String letter, bool correct) {
    if (!correct) missed.add(letter);
    strengths[letter] = correct ? ((strengths[letter] ?? 0) + 1).clamp(0, 5) : (strengths[letter] ?? 0) ~/ 2;
    store.answerLetter(letter, correct);
  }

  void _conclude(RoundControl c, String letter, bool correct) {
    _record(letter, correct);
    Speech.instance.letter(letter);
    c.conclude(
      correct,
      wait: const Duration(milliseconds: 1100),
      reveal: Column(children: [
        Text('${letterName(letter)} · sounds like ${letterSound(letter)}',
            textAlign: TextAlign.center, style: uiStyle(14, color: Colors.white70)),
        if (!correct) ...[const SizedBox(height: 10), FormsRow(letter)],
      ]),
    );
  }

  Widget Function(RoundControl) _intro(String letter) => (c) {
        Speech.instance.letter(letter);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Eyebrow('New letter'),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(letter, style: arabicStyle(96)),
            const SizedBox(width: 12),
            ListenButton(onPressed: () => Speech.instance.letter(letter)),
          ]),
          Text(letterName(letter), textAlign: TextAlign.center, style: uiStyle(22, weight: FontWeight.w700)),
          Text('sounds like: ${letterSound(letter)}',
              textAlign: TextAlign.center, style: uiStyle(14, color: LearnColors.muted)),
          const SizedBox(height: 16),
          FormsRow(letter),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Got it',
            onPressed: () {
              introduced.add(letter);
              _asked++;
              c.replace(_sound(letter, letterForms(letter).first));
            },
          ),
        ]);
      };

  // "Which sound does this letter make?"
  Widget Function(RoundControl) _sound(String letter, LetterForm form) => (c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Eyebrow(form.where == 'alone'
              ? 'Which sound does this letter make?'
              : 'Which letter is this? It is drawn as it looks at the ${form.where} of a word.'),
          BigArabic(form.text, size: 96),
          const SizedBox(height: 16),
          Choices<String>(
            options: shuffled([letter, ..._rivals(letter)]),
            correct: letter,
            label: (o) => TwoLine(letterSound(o), letterName(o)),
            onPick: (ok) => _conclude(c, letter, ok),
          ),
        ],
      );

  Widget _letterOption(String o) => Text(o, style: arabicStyle(34));

  // "Which letter is bā?"
  Widget Function(RoundControl) _letterQ(String letter) => (c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('Which letter is this?'),
          Text(letterName(letter), textAlign: TextAlign.center, style: uiStyle(28, weight: FontWeight.w700)),
          Text(letterSound(letter), textAlign: TextAlign.center, style: uiStyle(15, color: LearnColors.muted)),
          const SizedBox(height: 18),
          Choices<String>(
            options: shuffled([letter, ..._rivals(letter)]),
            correct: letter,
            label: _letterOption,
            onPick: (ok) => _conclude(c, letter, ok),
          ),
        ],
      );

  // "Listen: which letter did you hear?"
  Widget Function(RoundControl) _listen(String letter) => (c) {
        Speech.instance.letter(letter);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Eyebrow('Listen. Which letter did you hear?'),
          Center(child: ListenButton(size: 44, onPressed: () => Speech.instance.letter(letter))),
          const SizedBox(height: 18),
          Choices<String>(
            options: shuffled([letter, ..._rivals(letter)]),
            correct: letter,
            label: _letterOption,
            onPick: (ok) => _conclude(c, letter, ok),
          ),
        ]);
      };

  // "Which of these is the same letter, as it looks inside a word?"
  Widget Function(RoundControl) _shape(String letter) => (c) {
        String joined(String l) {
          final forms = letterForms(l);
          return forms.firstWhere((f) => f.where == 'middle', orElse: () => forms.last).text;
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Eyebrow('Letters change shape inside a word. Which of these is the same letter?'),
          BigArabic(letter, size: 96),
          const SizedBox(height: 16),
          Choices<String>(
            options: shuffled([letter, ..._rivals(letter)]),
            correct: letter,
            label: (o) => Text(joined(o), style: arabicStyle(34)),
            onPick: (ok) => _conclude(c, letter, ok),
          ),
        ]);
      };

  // "Tap the letter jīm in this word."
  Widget Function(RoundControl) _find(String letter) => (c) {
        final (word, meaning) = pick(wordsWith(letter));
        final plain = word.runes.map(String.fromCharCode).toList();
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Eyebrow('Tap the letter ${letterName(letter)} (${letterSound(letter)}) in this word'),
          GlyphPicker(
            glyphs: joinedGlyphs(word),
            isAnswer: (i) => isLetter(plain[i], letter),
            onPick: (ok) => _conclude(c, letter, ok),
          ),
          const SizedBox(height: 6),
          Text('“$meaning”', textAlign: TextAlign.center, style: uiStyle(14, color: LearnColors.muted)),
        ]);
      };

  // Match four letters to their names.
  Widget Function(RoundControl) _match(List<String> letters) => (c) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('Match each letter to its name'),
          MatchBoard<String>(
            items: letters,
            left: (l) => Text(l, style: arabicStyle(30)),
            right: (l) => TwoLine(letterName(l), letterSound(l)),
            onLeft: Speech.instance.letter,
            onPair: (l, firstTry) {
              _record(l, firstTry);
              c.score(firstTry);
            },
            onDone: c.next,
          ),
        ],
      );

  // Chooses what to ask next. Weak letters come up more often, new letters
  // are introduced one at a time, and the kind of question keeps changing.
  @override
  Widget Function(RoundControl) nextCard() {
    final open = _unlocked;
    final seen = open.where(introduced.contains).toList();
    final firstNew = open.where((l) => !introduced.contains(l)).firstOrNull;

    // Every few questions, a matching board over the weakest letters.
    if (seen.length >= 4 && _asked % 5 == 3) {
      _asked++;
      _lastLetter = null;
      final weakest = shuffled(seen)..sort((a, b) => (strengths[a] ?? 0).compareTo(strengths[b] ?? 0));
      return _match(weakest.take(4).toList());
    }

    var candidates = [for (final l in seen) (l, 6 - (strengths[l] ?? 0))];
    if (firstNew != null) candidates.add((firstNew, seen.isEmpty ? 1 : 3));
    if (candidates.length > 1) candidates = candidates.where((c) => c.$1 != _lastLetter).toList();
    final letter = weightedPick(candidates);
    _lastLetter = letter;
    if (!introduced.contains(letter)) return _intro(letter);

    _asked++;
    final strength = strengths[letter] ?? 0;
    final forms = letterForms(letter);
    final kinds = [_sound(letter, strength >= unlockAt ? pick(forms) : forms.first)];
    if (strength > 0) {
      kinds.add(_letterQ(letter));
      if (Speech.instance.hasLetterSound(letter)) kinds.addAll([_listen(letter), _listen(letter)]);
      if (wordsWith(letter).isNotEmpty) kinds.add(_find(letter));
      if (forms.length > 2) kinds.add(_shape(letter));
    }
    return pick(kinds);
  }

  @override
  List<Widget> summary(int right, int wrong) {
    final openNow = unlockedGroups(strengths);
    return [
      if (openNow > openAtStart)
        _Note('New letters unlocked: ${alphabetGroups[openNow - 1].letters.join(' ')}', highlight: true),
      if (missed.isNotEmpty) _Note('Worth another look:  ${missed.join('  ')}'),
    ];
  }
}

class _Note extends StatelessWidget {
  final String text;
  final bool highlight;
  const _Note(this.text, {this.highlight = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            textAlign: TextAlign.center,
            style: arabicStyle(16, color: highlight ? LearnColors.gold : LearnColors.muted)),
      );
}
