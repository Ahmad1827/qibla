import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'speech.dart';

// Colours shared with the rest of the app.
class LearnColors {
  static const background = Color(0xFF0B0F19);
  static const card = Color(0xFF131B2E);
  static const border = Color(0xFF1E293B);
  static const borderStrong = Color(0xFF334155);
  static const gold = Color(0xFFE2B970);
  static const blue = Color(0xFF38BDF8);
  static const muted = Color(0xFF94A3B8);
  static const faint = Color(0xFF64748B);
  static const right = Color(0xFF2DD4BF);
  static const wrong = Color(0xFFF43F5E);
}

TextStyle arabicStyle(double size, {Color color = Colors.white, double height = 1.6}) =>
    GoogleFonts.notoNaskhArabic(fontSize: size, color: color, height: height);

TextStyle uiStyle(double size, {Color color = Colors.white, FontWeight weight = FontWeight.w400, double? height}) =>
    GoogleFonts.plusJakartaSans(fontSize: size, color: color, fontWeight: weight, height: height);

final _random = math.Random();
List<T> shuffled<T>(Iterable<T> items) => items.toList()..shuffle(_random);
T pick<T>(List<T> items) => items[_random.nextInt(items.length)];
double randomUnit() => _random.nextDouble();

/// Picks one entry, each as likely as its weight.
T weightedPick<T>(List<(T, num)> candidates) {
  var roll = randomUnit() * candidates.fold<num>(0, (sum, c) => sum + c.$2);
  for (final (item, weight) in candidates) {
    roll -= weight;
    if (roll < 0) return item;
  }
  return candidates.first.$1;
}

const _praise = ['Correct.', 'Yes.', "That's it.", 'Right.'];

String resultTitle(int right, int wrong) {
  final accuracy = right / math.max(1, right + wrong);
  if (accuracy == 1) return 'A perfect round';
  if (accuracy >= 0.8) return 'Well done';
  if (accuracy >= 0.5) return 'Good practice';
  return 'Keep going';
}

/// What a question can do to the round it is in.
abstract class RoundControl {
  /// The question was answered: count it, show [reveal] and move on (by
  /// itself after a moment when the answer was right).
  void conclude(bool correct, {required Widget reveal, Duration wait = const Duration(milliseconds: 1300)});

  /// Swap the current card for another without counting anything (used by
  /// the "new letter" cards, which go straight on to a first question).
  void replace(Widget Function(RoundControl) card);

  /// One pair on a matching board: counted, but the board stays up.
  void score(bool correct);

  /// Move on to the next question.
  void next();
}

/// The questions of one round, chosen one at a time.
abstract class RoundPlan {
  String get title;
  int get total;
  int get asked;
  bool get finished => asked >= total;

  Widget Function(RoundControl) nextCard();

  /// Lines shown under the result title when the round is over.
  List<Widget> summary(int right, int wrong);
}

class RoundScreen extends StatefulWidget {
  final RoundPlan Function() makePlan;
  const RoundScreen({super.key, required this.makePlan});

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _RoundScreenState extends State<RoundScreen> implements RoundControl {
  late RoundPlan _plan;
  // Each card is built once, so its shuffled options and sounds stay put.
  late Widget _card;
  int _cardNumber = 0;
  int _right = 0;
  int _wrong = 0;
  int _run = 0;
  bool _done = false;
  Widget? _feedback;
  bool? _lastCorrect;
  Timer? _autoNext;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    _plan = widget.makePlan();
    _right = _wrong = _run = 0;
    _done = false;
    _feedback = null;
    _card = _plan.nextCard()(this);
    _cardNumber++;
  }

  @override
  void dispose() {
    _autoNext?.cancel();
    Speech.instance.stop();
    super.dispose();
  }

  @override
  void score(bool correct) {
    setState(() {
      if (correct) {
        _right++;
        _run++;
      } else {
        _wrong++;
        _run = 0;
      }
    });
    correct ? HapticFeedback.lightImpact() : HapticFeedback.heavyImpact();
  }

  @override
  void conclude(bool correct, {required Widget reveal, Duration wait = const Duration(milliseconds: 1300)}) {
    score(correct);
    setState(() {
      _lastCorrect = correct;
      _feedback = reveal;
    });
    if (correct) _autoNext = Timer(wait, next);
  }

  @override
  void replace(Widget Function(RoundControl) card) {
    setState(() {
      _card = card(this);
      _cardNumber++;
      _feedback = null;
    });
  }

  @override
  void next() {
    _autoNext?.cancel();
    if (!mounted || (_feedback == null && _done)) return;
    setState(() {
      _feedback = null;
      if (_plan.finished) {
        _done = true;
        Speech.instance.stop();
      } else {
        _card = _plan.nextCard()(this);
        _cardNumber++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: LearnColors.background,
        appBar: AppBar(
          backgroundColor: LearnColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: _done
              ? null
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _plan.asked / _plan.total,
                    minHeight: 8,
                    backgroundColor: LearnColors.border,
                    color: LearnColors.gold,
                  ),
                ),
          actions: [
            if (!_done)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 18,
                      color: _run >= 3 ? const Color(0xFFFB923C) : LearnColors.faint,
                    ),
                    const SizedBox(width: 2),
                    Text('$_run', style: uiStyle(14, weight: FontWeight.w600)),
                  ],
                ),
              ),
          ],
        ),
        body: SafeArea(child: _done ? _results() : _question()),
      ),
    );
  }

  Widget _question() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: LearnColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: LearnColors.border),
          ),
          child: KeyedSubtree(key: ValueKey(('card', _cardNumber)), child: _card),
        ),
        if (_feedback != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (_lastCorrect! ? LearnColors.right : LearnColors.wrong).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: (_lastCorrect! ? LearnColors.right : LearnColors.wrong).withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _lastCorrect! ? pick(_praise) : 'Not quite. Here it is:',
                  style: uiStyle(
                    16,
                    weight: FontWeight.w700,
                    color: _lastCorrect! ? LearnColors.right : LearnColors.wrong,
                  ),
                ),
                const SizedBox(height: 8),
                _feedback!,
                const SizedBox(height: 14),
                PrimaryButton(label: 'Continue', onPressed: next),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _results() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(_wrong == 0 ? Icons.emoji_events_rounded : Icons.check_circle_rounded, size: 64, color: LearnColors.gold),
        const SizedBox(height: 16),
        Text(
          resultTitle(_right, _wrong),
          textAlign: TextAlign.center,
          style: uiStyle(26, weight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          '$_right right · $_wrong wrong',
          textAlign: TextAlign.center,
          style: uiStyle(14, color: LearnColors.muted),
        ),
        const SizedBox(height: 24),
        ..._plan.summary(_right, _wrong),
        const SizedBox(height: 24),
        PrimaryButton(label: 'Another round', onPressed: () => setState(_start)),
        const SizedBox(height: 10),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: LearnColors.borderStrong),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text('Done', style: uiStyle(15, color: Colors.white70)),
        ),
      ],
    );
  }
}

// ---- Building blocks for questions ---------------------------------------------

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const PrimaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: LearnColors.gold,
        foregroundColor: LearnColors.background,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: uiStyle(15, weight: FontWeight.w700, color: LearnColors.background),
      ),
    );
  }
}

class Eyebrow extends StatelessWidget {
  final String text;
  const Eyebrow(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      text,
      style: uiStyle(13, color: LearnColors.muted, weight: FontWeight.w600),
    ),
  );
}

class ListenButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;
  const ListenButton({super.key, required this.onPressed, this.size = 28});

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    style: IconButton.styleFrom(backgroundColor: LearnColors.blue.withValues(alpha: 0.15)),
    iconSize: size,
    icon: const Icon(Icons.volume_up_rounded, color: LearnColors.blue),
    onPressed: onPressed,
  );
}

/// Big Arabic text in the middle of a card.
class BigArabic extends StatelessWidget {
  final String text;
  final double size;
  const BigArabic(this.text, {super.key, this.size = 64});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(text, textDirection: TextDirection.rtl, textAlign: TextAlign.center, style: arabicStyle(size)),
  );
}

/// Up to four options to choose from. Once one is chosen the right one turns
/// green, and a wrong choice red.
class Choices<T> extends StatefulWidget {
  final List<T> options;
  final T correct;
  final Widget Function(T option) label;
  final void Function(bool correct) onPick;
  final bool wide;
  const Choices({
    super.key,
    required this.options,
    required this.correct,
    required this.label,
    required this.onPick,
    this.wide = false,
  });

  @override
  State<Choices<T>> createState() => _ChoicesState<T>();
}

class _ChoicesState<T> extends State<Choices<T>> {
  T? _chosen;
  bool _picked = false;

  void _choose(T option) {
    if (_picked) return;
    setState(() {
      _picked = true;
      _chosen = option;
    });
    widget.onPick(option == widget.correct);
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      for (final option in widget.options)
        _OptionButton(
          state: !_picked
              ? null
              : option == widget.correct
              ? true
              : option == _chosen
              ? false
              : null,
          faded: _picked && option != widget.correct && option != _chosen,
          onTap: () => _choose(option),
          child: widget.label(option),
        ),
    ];
    if (widget.wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final b in buttons) Padding(padding: const EdgeInsets.only(bottom: 10), child: b)],
      );
    }
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.6,
      children: buttons,
    );
  }
}

class _OptionButton extends StatelessWidget {
  final bool? state; // true right, false wrong, null neither
  final bool faded;
  final VoidCallback onTap;
  final Widget child;
  const _OptionButton({required this.state, required this.faded, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final color = state == true
        ? LearnColors.right
        : state == false
        ? LearnColors.wrong
        : LearnColors.borderStrong;
    return Opacity(
      opacity: faded ? 0.45 : 1,
      child: Material(
        color: state == null ? LearnColors.background : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color, width: state == null ? 1 : 2),
            ),
            alignment: Alignment.center,
            child: DefaultTextStyle.merge(textAlign: TextAlign.center, child: child),
          ),
        ),
      ),
    );
  }
}

/// A label with a bold first line and a small second one.
class TwoLine extends StatelessWidget {
  final String title;
  final String? subtitle;
  const TwoLine(this.title, [this.subtitle, Key? key]) : super(key: key);

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        textAlign: TextAlign.center,
        style: uiStyle(15, weight: FontWeight.w700),
      ),
      if (subtitle != null)
        Text(
          subtitle!,
          textAlign: TextAlign.center,
          style: uiStyle(11.5, color: LearnColors.muted),
        ),
    ],
  );
}

/// Build a word from its letters (or a sentence from its words) by tapping
/// tiles in order. It is checked once enough tiles are placed.
class TileBuilder extends StatefulWidget {
  final List<String> target;
  final List<String> extra;
  final String joinWith;
  final void Function(bool correct) onDone;
  const TileBuilder({super.key, required this.target, this.extra = const [], this.joinWith = '', required this.onDone});

  @override
  State<TileBuilder> createState() => _TileBuilderState();
}

class _TileBuilderState extends State<TileBuilder> {
  late final List<String> _tiles;
  final List<int> _placed = [];
  bool? _result;

  @override
  void initState() {
    super.initState();
    _tiles = shuffled([...widget.target, ...widget.extra]);
    if (_tiles.join(widget.joinWith) == widget.target.join(widget.joinWith)) {
      _tiles.setAll(0, _tiles.reversed.toList());
    }
  }

  void _place(int i) {
    if (_result != null || _placed.contains(i)) return;
    setState(() => _placed.add(i));
    if (_placed.length == widget.target.length) {
      final correct = _placed.map((i) => _tiles[i]).join(widget.joinWith) == widget.target.join(widget.joinWith);
      setState(() => _result = correct);
      widget.onDone(correct);
    }
  }

  @override
  Widget build(BuildContext context) {
    final built = _placed.map((i) => _tiles[i]).join(widget.joinWith);
    final sentence = widget.joinWith.isNotEmpty;
    final frame = _result == null
        ? LearnColors.borderStrong
        : _result!
        ? LearnColors.right
        : LearnColors.wrong;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: sentence ? 64 : 80),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: LearnColors.background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: frame, width: _result == null ? 1 : 2),
                ),
                alignment: Alignment.centerRight,
                // Shown as running text, so letters join up as they are added.
                child: Text(built, textDirection: TextDirection.rtl, style: arabicStyle(sentence ? 24 : 40)),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.backspace_outlined, color: Colors.white70),
              onPressed: _result != null || _placed.isEmpty ? null : () => setState(_placed.removeLast),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < _tiles.length; i++)
                Opacity(
                  opacity: _placed.contains(i) ? 0.25 : 1,
                  child: Material(
                    color: LearnColors.background,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _place(i),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 52, minHeight: 52),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: LearnColors.borderStrong),
                        ),
                        alignment: Alignment.center,
                        child: Text(_tiles[i], style: arabicStyle(sentence ? 22 : 28)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A board of pairs to join up, left column to right column. [onPair] is told
/// each pair found and whether it was found without a slip.
class MatchBoard<T extends Object> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T) left;
  final Widget Function(T) right;
  final void Function(T)? onLeft;
  final void Function(T item, bool firstTry) onPair;
  final VoidCallback onDone;
  const MatchBoard({
    super.key,
    required this.items,
    required this.left,
    required this.right,
    this.onLeft,
    required this.onPair,
    required this.onDone,
  });

  @override
  State<MatchBoard<T>> createState() => _MatchBoardState<T>();
}

class _MatchBoardState<T extends Object> extends State<MatchBoard<T>> {
  late final List<T> _leftOrder = shuffled(widget.items);
  late final List<T> _rightOrder = shuffled(widget.items);
  final Set<T> _matched = {};
  final Set<T> _slipped = {};
  T? _left;
  T? _right;
  (T, T)? _wrongPair;

  void _choose(bool isLeft, T item) {
    if (_matched.contains(item)) return;
    if (isLeft) widget.onLeft?.call(item);
    setState(() {
      _wrongPair = null;
      if (isLeft) {
        _left = item;
      } else {
        _right = item;
      }
    });
    final l = _left, r = _right;
    if (l == null || r == null) return;
    if (l == r) {
      final firstTry = !_slipped.contains(l);
      setState(() {
        _matched.add(l);
        _left = _right = null;
      });
      widget.onPair(l, firstTry);
      if (_matched.length == widget.items.length) {
        Timer(const Duration(milliseconds: 500), widget.onDone);
      }
    } else {
      _slipped.add(l);
      HapticFeedback.heavyImpact();
      setState(() {
        _wrongPair = (l, r);
        _left = _right = null;
      });
    }
  }

  Widget _cell(bool isLeft, T item) {
    final matched = _matched.contains(item);
    final selected = isLeft ? _left == item : _right == item;
    final wrong = _wrongPair != null && (isLeft ? _wrongPair!.$1 == item : _wrongPair!.$2 == item);
    final color = matched
        ? LearnColors.right
        : wrong
        ? LearnColors.wrong
        : selected
        ? LearnColors.gold
        : LearnColors.borderStrong;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        opacity: matched ? 0.5 : 1,
        child: Material(
          color: matched ? LearnColors.right.withValues(alpha: 0.12) : LearnColors.background,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _choose(isLeft, item),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color, width: selected || wrong ? 2 : 1),
              ),
              alignment: Alignment.center,
              child: isLeft ? widget.left(item) : widget.right(item),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Column(children: [for (final i in _leftOrder) _cell(true, i)])),
      const SizedBox(width: 10),
      Expanded(child: Column(children: [for (final i in _rightOrder) _cell(false, i)])),
    ],
  );
}

/// A word drawn letter by letter (each in its joined shape) where one letter
/// is to be tapped.
class GlyphPicker extends StatefulWidget {
  final List<String> glyphs; // with joiners, for display
  final bool Function(int index) isAnswer;
  final void Function(bool correct) onPick;
  const GlyphPicker({super.key, required this.glyphs, required this.isAnswer, required this.onPick});

  @override
  State<GlyphPicker> createState() => _GlyphPickerState();
}

class _GlyphPickerState extends State<GlyphPicker> {
  int? _tapped;

  @override
  Widget build(BuildContext context) {
    // Long words shrink to fit the screen rather than run off it.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.glyphs.length; i++)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (_tapped != null) return;
                  setState(() => _tapped = i);
                  widget.onPick(widget.isAnswer(i));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 4),
                  decoration: BoxDecoration(
                    color: _tapped == null
                        ? Colors.transparent
                        : widget.isAnswer(i)
                        ? LearnColors.right.withValues(alpha: 0.2)
                        : i == _tapped
                        ? LearnColors.wrong.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.glyphs[i],
                    style: arabicStyle(
                      56,
                      color: _tapped == null || widget.isAnswer(i) || i == _tapped ? Colors.white : Colors.white38,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
