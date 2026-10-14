import 'package:flutter_test/flutter_test.dart';
import 'package:qibla/learn/alphabet_round.dart';
import 'package:qibla/learn/course_round.dart';
import 'package:qibla/learn/lessons.dart';
import 'package:qibla/learn/letters.dart';

void main() {
  test('every trainer letter has a name, a sound and a word to find it in', () {
    for (final letter in trainerLetters) {
      expect(letterInfo.containsKey(letter), isTrue, reason: letter);
      expect(wordsWith(letter), isNotEmpty, reason: letter);
    }
  });

  test('letters without a recording are spoken instead', () {
    for (final letter in trainerLetters) {
      expect(letterAudio.containsKey(letter) || letterSpoken.containsKey(letter), isTrue, reason: letter);
    }
  });

  test('the next letter group opens once the earlier ones are answered twice', () {
    expect(unlockedGroups({}), 1);
    final first = {for (final l in alphabetGroups[0].letters) l: unlockAt};
    expect(unlockedGroups(first), 2);
    expect(unlockedGroups({...first, alphabetGroups[0].letters.first: 1}), 1);
  });

  test('letters inside a word keep their joins', () {
    expect(joinedGlyphs('باب'), ['ب$joiner', '$joinerا', 'ب']);
    expect(joinedGlyphs('ماء'), ['م$joiner', '$joinerا', 'ء']);
    expect(joinedGlyphs('باب').map((g) => g.replaceAll(joiner, '')).join(), 'باب');
  });

  test('misreadings change only the vowels', () {
    final wrong = misreadings('kitāb');
    expect(wrong, hasLength(3));
    expect(wrong, isNot(contains('kitāb')));
    for (final w in wrong) {
      expect(w.replaceAll(RegExp('[aiuāīū]'), ''), 'ktb');
    }
  });

  test('marks are written on the consonant they are shown with', () {
    final fatha = courses.first.units.first.items.first as MarkItem;
    expect(fatha.write('ب'), 'بَ');
    expect(fatha.read('b'), 'ba');
    expect(stripMarks(fatha.write('ب')), 'ب');
  });

  test('item ids are unique within each course', () {
    for (final course in courses) {
      final ids = [for (final u in course.units) for (final i in u.items) i.id];
      expect(ids.toSet().length, ids.length, reason: course.id);
    }
  });
}
