import 'package:flutter/material.dart';
import 'alphabet_round.dart';
import 'course_round.dart';
import 'lessons.dart';
import 'letters.dart';
import 'progress_store.dart';
import 'round.dart';
import 'speech.dart';

/// The home of the Arabic practice: the alphabet trainer and the courses
/// (vowel marks, words, phrases), with how far each has got.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  ProgressStore? _store;

  @override
  void initState() {
    super.initState();
    Future.wait([ProgressStore.open(), Speech.instance.init()]).then((results) {
      if (mounted) setState(() => _store = results[0] as ProgressStore);
    });
  }

  Future<void> _play(RoundPlan Function() makePlan) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => RoundScreen(makePlan: makePlan)));
    if (mounted) setState(() {}); // progress changed
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: LearnColors.background,
        appBar: AppBar(
          backgroundColor: LearnColors.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('Learn Arabic', style: uiStyle(18, weight: FontWeight.bold)),
        ),
        body: store == null
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: LearnColors.gold))
            : _body(store),
      ),
    );
  }

  Widget _body(ProgressStore store) {
    final letters = store.letters();
    final knownLetters = trainerLetters.where((l) => (letters[l] ?? 0) >= ProgressStore.knownAt).length;
    final open = unlockedGroups(letters);
    final streak = store.streak();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(children: [
          _Stat(
            icon: Icons.local_fire_department_rounded,
            color: store.practisedToday() ? const Color(0xFFFB923C) : LearnColors.faint,
            value: '$streak',
            label: streak == 1 ? 'day streak' : 'days streak',
          ),
          const SizedBox(width: 10),
          _Stat(
            icon: Icons.abc_rounded,
            color: LearnColors.blue,
            value: '$knownLetters/${trainerLetters.length}',
            label: 'letters known',
          ),
        ]),
        if (!Speech.instance.canSpeak) ...[
          const SizedBox(height: 12),
          Text(
            'No Arabic voice found on this phone, so listening questions about words are skipped. '
            'You can add one in the phone\'s text-to-speech settings (Google: install voice data → Arabic).',
            style: uiStyle(12, color: LearnColors.faint, height: 1.4),
          ),
        ],
        const SizedBox(height: 22),
        _SectionTitle('Alphabet', 'Learn the letters a few at a time, grouped by shape.'),
        _Panel(children: [
          for (var i = 0; i < alphabetGroups.length; i++)
            _GroupRow(group: alphabetGroups[i], strengths: letters, locked: i >= open),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: PrimaryButton(label: 'Practise letters', onPressed: () => _play(() => AlphabetPlan(store))),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              tooltip: 'All letters',
              style: IconButton.styleFrom(side: const BorderSide(color: LearnColors.borderStrong)),
              icon: const Icon(Icons.grid_view_rounded, color: Colors.white70),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LettersScreen())),
            ),
          ]),
        ]),
        for (final course in courses) ...[
          const SizedBox(height: 26),
          _SectionTitle(course.title, course.blurb),
          _CoursePanel(course: course, store: store, onPlay: _play),
        ],
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: LearnColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: LearnColors.border),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: uiStyle(18, weight: FontWeight.w700)),
                Text(label, style: uiStyle(11.5, color: LearnColors.muted)),
              ]),
            ),
          ]),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String blurb;
  const _SectionTitle(this.title, this.blurb);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, left: 4, right: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: uiStyle(19, weight: FontWeight.w700, color: LearnColors.gold)),
          const SizedBox(height: 4),
          Text(blurb, style: uiStyle(13, color: LearnColors.muted, height: 1.4)),
        ]),
      );
}

class _Panel extends StatelessWidget {
  final List<Widget> children;
  const _Panel({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: LearnColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: LearnColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );
}

class _GroupRow extends StatelessWidget {
  final LetterGroup group;
  final Map<String, int> strengths;
  final bool locked;
  const _GroupRow({required this.group, required this.strengths, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(locked ? Icons.lock_outline_rounded : Icons.circle, size: locked ? 14 : 8, color: LearnColors.faint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(group.title, style: uiStyle(13, color: locked ? LearnColors.faint : Colors.white70)),
        ),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Row(children: [
            for (final l in group.letters)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  l,
                  style: arabicStyle(20,
                      height: 1.3,
                      color: locked
                          ? LearnColors.borderStrong
                          : Color.lerp(LearnColors.faint, LearnColors.right, (strengths[l] ?? 0) / ProgressStore.maxStrength)!),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

class _CoursePanel extends StatelessWidget {
  final Course course;
  final ProgressStore store;
  final Future<void> Function(RoundPlan Function()) onPlay;
  const _CoursePanel({required this.course, required this.store, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final strengths = store.course(course.id);
    final anyMet = course.units.any((u) => u.items.any((i) => strengths.containsKey(i.id)));
    return _Panel(children: [
      for (final unit in course.units) _unitRow(unit, strengths),
      if (anyMet) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: LearnColors.borderStrong),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => onPlay(() => CoursePlan(store, course, null)),
          icon: const Icon(Icons.shuffle_rounded, size: 18, color: LearnColors.blue),
          label: Text('Mixed review of everything met', style: uiStyle(14, color: LearnColors.blue)),
        ),
      ],
    ]);
  }

  Widget _unitRow(Unit unit, Map<String, int> strengths) {
    final learned = unit.items.where((i) => (strengths[i.id] ?? 0) >= ProgressStore.knownAt).length;
    final started = unit.items.any((i) => strengths.containsKey(i.id));
    final done = learned == unit.items.length;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onPlay(() => CoursePlan(store, course, unit)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(children: [
          SizedBox(
            width: 34,
            height: 34,
            child: Stack(alignment: Alignment.center, children: [
              CircularProgressIndicator(
                value: learned / unit.items.length,
                strokeWidth: 3,
                backgroundColor: LearnColors.border,
                color: done ? LearnColors.right : LearnColors.gold,
              ),
              Icon(
                done ? Icons.check_rounded : (started ? Icons.play_arrow_rounded : Icons.play_arrow_outlined),
                size: 16,
                color: done ? LearnColors.right : Colors.white70,
              ),
            ]),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(unit.title, style: uiStyle(15, weight: FontWeight.w600)),
              Text(
                unit.blurb.isNotEmpty ? unit.blurb : '$learned of ${unit.items.length} learned',
                style: uiStyle(12, color: LearnColors.faint),
              ),
            ]),
          ),
          const Icon(Icons.chevron_right_rounded, color: LearnColors.faint),
        ]),
      ),
    );
  }
}

/// Every letter with its name, sound and shapes. Tap one to hear it.
class LettersScreen extends StatelessWidget {
  const LettersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: LearnColors.background,
        appBar: AppBar(
          backgroundColor: LearnColors.background,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text('The alphabet', style: uiStyle(18, weight: FontWeight.bold)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            for (final letter in trainerLetters)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: LearnColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LearnColors.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => Speech.instance.letter(letter),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Row(children: [
                      SizedBox(width: 52, child: Text(letter, textAlign: TextAlign.center, style: arabicStyle(36))),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(letterName(letter), style: uiStyle(15, weight: FontWeight.w700)),
                          Text(letterSound(letter), style: uiStyle(12, color: LearnColors.muted)),
                        ]),
                      ),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Row(children: [
                          for (final form in letterForms(letter).skip(1))
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(form.text, style: arabicStyle(22, color: LearnColors.gold)),
                            ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
