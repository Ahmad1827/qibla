// Name and sound of each Arabic letter, ported from the Arabic Reader app.
const Map<String, (String, String)> letterInfo = {
  'ء': ('hamza', 'ʾ (catch in the throat)'),
  'ا': ('alif', 'ā'),
  'أ': ('alif + hamza', 'ʾa / ʾu'),
  'إ': ('alif + hamza below', 'ʾi'),
  'آ': ('alif madda', 'ʾā'),
  'ب': ('bā', 'b'),
  'ت': ('tā', 't'),
  'ث': ('thā', 'th (think)'),
  'ج': ('jīm', 'j'),
  'ح': ('ḥā', 'ḥ (breathy h)'),
  'خ': ('khā', 'kh (loch)'),
  'د': ('dāl', 'd'),
  'ذ': ('dhāl', 'dh (this)'),
  'ر': ('rā', 'r (rolled)'),
  'ز': ('zāy', 'z'),
  'س': ('sīn', 's'),
  'ش': ('shīn', 'sh'),
  'ص': ('ṣād', 'ṣ (heavy s)'),
  'ض': ('ḍād', 'ḍ (heavy d)'),
  'ط': ('ṭā', 'ṭ (heavy t)'),
  'ظ': ('ẓā', 'ẓ (heavy dh)'),
  'ع': ('ʿayn', 'ʿ (deep in the throat)'),
  'غ': ('ghayn', 'gh (French r)'),
  'ف': ('fā', 'f'),
  'ق': ('qāf', 'q (deep k)'),
  'ك': ('kāf', 'k'),
  'ل': ('lām', 'l'),
  'م': ('mīm', 'm'),
  'ن': ('nūn', 'n'),
  'ه': ('hā', 'h'),
  'و': ('wāw', 'w / ū'),
  'ي': ('yā', 'y / ī'),
  'ى': ('alif maqṣūra', 'ā (end of word)'),
  'ة': ('tā marbūṭa', 'a / at (end of word)'),
  'ؤ': ('hamza on wāw', 'ʾ'),
  'ئ': ('hamza on yā', 'ʾ'),
};

String letterName(String letter) => letterInfo[letter]?.$1 ?? letter;
String letterSound(String letter) => letterInfo[letter]?.$2 ?? '';

class LetterGroup {
  final String title;
  final List<String> letters;
  const LetterGroup(this.title, this.letters);
}

// The order the alphabet trainer teaches the letters in: small groups of
// letters that share a shape, so the differences (mostly dots) stand out.
const List<LetterGroup> alphabetGroups = [
  LetterGroup('The tall line and the boat', ['ا', 'ب', 'ت', 'ث']),
  LetterGroup('The hooks', ['ج', 'ح', 'خ']),
  LetterGroup('Short strokes', ['د', 'ذ', 'ر', 'ز']),
  LetterGroup('Teeth and loops', ['س', 'ش', 'ص', 'ض']),
  LetterGroup('Heavy and throat letters', ['ط', 'ظ', 'ع', 'غ']),
  LetterGroup('Round heads', ['ف', 'ق', 'ك', 'ل']),
  LetterGroup('The last five', ['م', 'ن', 'ه', 'و', 'ي']),
  LetterGroup('Extra signs', ['ء', 'ة', 'ى']),
];

final List<String> trainerLetters = [for (final g in alphabetGroups) ...g.letters];

// Arabic letters change shape depending on where they sit in a word. A
// zero-width joiner makes the text engine draw each shape on its own.
const String joiner = '‍';
const Set<String> joinsBackwardOnly = {'ا', 'أ', 'إ', 'آ', 'د', 'ذ', 'ر', 'ز', 'و', 'ؤ', 'ة', 'ى'};

class LetterForm {
  final String where;
  final String text;
  const LetterForm(this.where, this.text);
}

List<LetterForm> letterForms(String letter) {
  final forms = [LetterForm('alone', letter)];
  if (letter == 'ء') return forms;
  if (!joinsBackwardOnly.contains(letter)) {
    forms.add(LetterForm('start', '$letter$joiner'));
    forms.add(LetterForm('middle', '$joiner$letter$joiner'));
  }
  forms.add(LetterForm('end', '$joiner$letter'));
  return forms;
}

/// Splits a word into its letters, each drawn in the shape it has inside the
/// word, so the letters can be shown (and tapped) one by one.
List<String> joinedGlyphs(String word) {
  final glyphs = word.runes.map(String.fromCharCode).toList();
  bool joinsForward(String g) => g != 'ء' && !joinsBackwardOnly.contains(g);
  return [
    for (var i = 0; i < glyphs.length; i++)
      (i > 0 && joinsForward(glyphs[i - 1]) && glyphs[i] != 'ء' ? joiner : '') +
          glyphs[i] +
          (i < glyphs.length - 1 && joinsForward(glyphs[i]) && glyphs[i + 1] != 'ء' ? joiner : ''),
  ];
}

// A person saying each letter's name, in assets/audio/letters/<file>.mp3.
// Recordings by razunatmohammed88-cyber (MIT licence, see LICENSE.txt there).
const Map<String, String> letterAudio = {
  'ا': 'alif', 'ب': 'ba', 'ت': 'ta', 'ث': 'tha', 'ج': 'jim', 'ح': 'hha', 'خ': 'kha',
  'د': 'dal', 'ذ': 'dhal', 'ر': 'ra', 'ز': 'zay', 'س': 'sin', 'ش': 'shin', 'ص': 'sad',
  'ض': 'dad', 'ط': 'tta', 'ظ': 'zza', 'ع': 'ayn', 'غ': 'ghayn', 'ف': 'fa', 'ق': 'qaf',
  'ك': 'kaf', 'ل': 'lam', 'م': 'mim', 'ن': 'nun', 'ه': 'ha', 'و': 'waw', 'ي': 'ya',
  'ء': 'hamza',
};

// The two signs without a recording are read by the phone's voice, from their
// names written the way they are said.
const Map<String, String> letterSpoken = {
  'ة': 'تَاءْ مَرْبُوطَهْ',
  'ى': 'أَلِفْ مَقْصُورَهْ',
};

// Everyday words for "find the letter" questions; between them they contain
// every letter of the alphabet.
const List<(String, String)> findWords = [
  ('باب', 'door'), ('بيت', 'house'), ('كتاب', 'book'), ('مسجد', 'mosque'), ('شمس', 'sun'), ('قمر', 'moon'),
  ('ولد', 'boy'), ('بنت', 'girl'), ('ماء', 'water'), ('خبز', 'bread'), ('حليب', 'milk'), ('سمك', 'fish'),
  ('قلم', 'pen'), ('مدرسة', 'school'), ('طالب', 'student'), ('صديق', 'friend'), ('ضوء', 'light'), ('ظهر', 'noon'),
  ('عين', 'eye'), ('غرفة', 'room'), ('فيل', 'elephant'), ('ثلج', 'snow'), ('ذهب', 'gold'), ('زيت', 'oil'),
  ('جبل', 'mountain'), ('حصان', 'horse'), ('خروف', 'sheep'), ('دجاجة', 'chicken'), ('رأس', 'head'), ('يد', 'hand'),
  ('نهر', 'river'), ('هواء', 'air'), ('وردة', 'rose'), ('لحم', 'meat'), ('كلب', 'dog'), ('طاولة', 'table'),
  ('أرض', 'earth'), ('شاي', 'tea'), ('قهوة', 'coffee'), ('سيارة', 'car'), ('مستشفى', 'hospital'), ('نظيف', 'clean'),
];

// A tapped glyph counts as the letter asked for; alif also covers its hamza forms.
bool isLetter(String glyph, String letter) =>
    glyph == letter || (letter == 'ا' && 'أإآ'.contains(glyph));

List<(String, String)> wordsWith(String letter) => findWords
    .where((w) => w.$1.runes.map(String.fromCharCode).any((g) => isLetter(g, letter)))
    .toList();

final RegExp _marks = RegExp(r'[\p{M}ـ]', unicode: true);
String stripMarks(String text) => text.replaceAll(_marks, '');
