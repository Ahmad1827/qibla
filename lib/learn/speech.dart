import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'letters.dart';

/// Reads Arabic aloud: real recordings for letter names, and the phone's own
/// Arabic text-to-speech voice for words and phrases.
class Speech {
  Speech._();
  static final Speech instance = Speech._();

  late final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool? _canSpeak;

  /// Whether the phone has an Arabic voice. Listening questions about words
  /// are only asked when it does.
  bool get canSpeak => _canSpeak ?? false;

  Future<void> init() async {
    if (_canSpeak != null) return;
    try {
      final available = await _tts.isLanguageAvailable('ar');
      _canSpeak = available == true || available == 1;
      if (canSpeak) {
        await _tts.setLanguage('ar');
        await _tts.setSpeechRate(0.4);
      }
    } catch (_) {
      _canSpeak = false;
    }
  }

  bool hasLetterSound(String letter) => letterAudio.containsKey(letter) || (canSpeak && letterSpoken.containsKey(letter));

  Future<void> letter(String letter) => _quietly(() async {
        final file = letterAudio[letter];
        if (file != null) {
          await _tts.stop();
          await _player.stop();
          await _player.play(AssetSource('audio/letters/$file.mp3'));
        } else if (letterSpoken[letter] != null) {
          await say(letterSpoken[letter]!);
        }
      });

  Future<void> say(String text) => _quietly(() async {
        if (!canSpeak) return;
        await _player.stop();
        await _tts.stop();
        await _tts.speak(text.replaceAll(RegExp('[؟.!،]'), ''));
      });

  Future<void> stop() => _quietly(() async {
        await _player.stop();
        await _tts.stop();
      });

  // A sound that cannot play is not worth interrupting practice for.
  Future<void> _quietly(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }
}
