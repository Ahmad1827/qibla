import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// How well each letter and course item is known, from 0 (new) to 5, plus the
/// days something was practised. Kept on the phone with shared_preferences.
class ProgressStore {
  static const int maxStrength = 5;
  static const int knownAt = 4;

  static const String _lettersKey = 'learn.letters';
  static const String _coursePrefix = 'learn.course.';
  static const String _daysKey = 'learn.days';

  final SharedPreferences _prefs;
  ProgressStore._(this._prefs);

  static ProgressStore? _instance;
  static Future<ProgressStore> open() async =>
      _instance ??= ProgressStore._(await SharedPreferences.getInstance());

  Map<String, int> _read(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      return (json.decode(raw) as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  Map<String, int> letters() => _read(_lettersKey);
  Map<String, int> course(String courseId) => _read('$_coursePrefix$courseId');

  /// Saves one answer: right adds one, wrong halves it.
  Future<int> answerLetter(String letter, bool correct) => _answer(_lettersKey, letter, correct);
  Future<int> answerItem(String courseId, String itemId, bool correct) =>
      _answer('$_coursePrefix$courseId', itemId, correct);

  Future<int> _answer(String key, String id, bool correct) async {
    final map = _read(key);
    final current = map[id] ?? 0;
    final strength = correct ? (current + 1).clamp(0, maxStrength) : current ~/ 2;
    map[id] = strength;
    await _prefs.setString(key, json.encode(map));
    await _markToday();
    return strength;
  }

  static int _dayNumber(DateTime t) => DateTime.utc(t.year, t.month, t.day).millisecondsSinceEpoch ~/ 86400000;

  Set<int> _days() => (_prefs.getStringList(_daysKey) ?? const []).map(int.parse).toSet();

  Future<void> _markToday() async {
    final days = _days()..add(_dayNumber(DateTime.now()));
    await _prefs.setStringList(_daysKey, days.map((d) => '$d').toList());
  }

  /// Days in a row with practice. It stays alive through today until
  /// midnight, even before anything is practised today.
  int streak() {
    final days = _days();
    final today = _dayNumber(DateTime.now());
    var day = days.contains(today) ? today : today - 1;
    var streak = 0;
    while (days.contains(day)) {
      streak++;
      day--;
    }
    return streak;
  }

  bool practisedToday() => _days().contains(_dayNumber(DateTime.now()));
}
