// The built-in courses beyond the alphabet: reading vowel marks, everyday
// words and short phrases, ported from the Arabic Reader app. Each course is a
// list of units, and every unit a list of items the practice rounds build
// their questions from.

class LessonItem {
  final String id;
  final String ar;
  final String translit;
  final String meaning;
  const LessonItem(this.ar, this.translit, this.meaning, [String? id]) : id = id ?? ar;
}

/// A vowel mark. It is practised on a different consonant every time, so it
/// is the mark that is learned, not one syllable.
class MarkItem extends LessonItem {
  final String name;
  final String about;
  final String Function(String consonant) write;
  final String Function(String latin) read;
  const MarkItem(String id, this.name, this.about, this.write, this.read) : super('', '', about, id);
}

class Unit {
  final String id;
  final String title;
  final List<LessonItem> items;
  final String blurb;
  const Unit(this.id, this.title, this.items, [this.blurb = '']);
}

enum CourseKind { mark, word, phrase }

class Course {
  final String id;
  final CourseKind kind;
  final String title;
  final String blurb;
  final List<Unit> units;
  const Course(this.id, this.kind, this.title, this.blurb, this.units);

  Unit? unitById(String id) {
    for (final unit in units) {
      if (unit.id == id) return unit;
    }
    return null;
  }
}

final List<Unit> _marksUnits = [
  Unit('short', 'Short vowels', [
    MarkItem('fatha', 'fatḥa', 'a small stroke above the letter: a short a', (c) => '$cَ', (l) => '${l}a'),
    MarkItem('kasra', 'kasra', 'a small stroke below the letter: a short i', (c) => '$cِ', (l) => '${l}i'),
    MarkItem('damma', 'ḍamma', 'a small loop above the letter: a short u', (c) => '$cُ', (l) => '${l}u'),
  ], 'The three small marks that give a letter its vowel.'),
  Unit('long', 'Long vowels', [
    MarkItem('long-a', 'long ā', 'fatḥa followed by alif: a long ā', (c) => '$cَا', (l) => '$lā'),
    MarkItem('long-i', 'long ī', 'kasra followed by yā: a long ī', (c) => '$cِي', (l) => '$lī'),
    MarkItem('long-u', 'long ū', 'ḍamma followed by wāw: a long ū', (c) => '$cُو', (l) => '$lū'),
  ], 'A short vowel followed by alif, yā or wāw is held twice as long.'),
  Unit('stops', 'Silence and doubling', [
    MarkItem('sukun', 'sukūn', 'a small circle above the letter: no vowel follows it', (c) => '$cْ', (l) => l),
    MarkItem('shadda', 'shadda', 'a small w shape above the letter: the letter is doubled', (c) => '$cَّ', (l) => '$l${l}a'),
  ], 'Sukūn means no vowel at all; shadda means the letter is said twice.'),
  Unit('tanwin', 'Endings with n', [
    MarkItem('tanwin-a', 'tanwīn fatḥ', 'two strokes above, usually with an alif: an', (c) => '$cًا', (l) => '${l}an'),
    MarkItem('tanwin-i', 'tanwīn kasr', 'two strokes below: in', (c) => '$cٍ', (l) => '${l}in'),
    MarkItem('tanwin-u', 'tanwīn ḍamm', 'a doubled ḍamma above: un', (c) => '$cٌ', (l) => '${l}un'),
  ], 'A doubled vowel mark at the end of a word adds an n sound.'),
];

// Consonants the marks are shown on, with how each is written in Latin letters.
const List<(String, String)> markCarriers = [
  ('ب', 'b'), ('ت', 't'), ('د', 'd'), ('ر', 'r'), ('س', 's'), ('ك', 'k'),
  ('ل', 'l'), ('م', 'm'), ('ن', 'n'), ('ف', 'f'), ('ج', 'j'), ('ز', 'z'),
];

const List<Unit> _wordsUnits = [
  Unit('basics', 'Greetings and basics', [
    LessonItem('مَرْحَبًا', 'marḥaban', 'hello'),
    LessonItem('أَهْلًا', 'ahlan', 'welcome'),
    LessonItem('شُكْرًا', 'shukran', 'thank you'),
    LessonItem('عَفْوًا', 'ʿafwan', 'you\'re welcome'),
    LessonItem('نَعَمْ', 'naʿam', 'yes'),
    LessonItem('لَا', 'lā', 'no'),
    LessonItem('آسِف', 'āsif', 'sorry'),
    LessonItem('اِسْم', 'ism', 'name'),
    LessonItem('صَبَاح', 'ṣabāḥ', 'morning'),
    LessonItem('مَسَاء', 'masāʾ', 'evening'),
    LessonItem('سَلَام', 'salām', 'peace'),
    LessonItem('جَيِّد', 'jayyid', 'good'),
  ]),
  Unit('pronouns', 'Pronouns and question words', [
    LessonItem('أَنَا', 'anā', 'I'),
    LessonItem('أَنْتَ', 'anta', 'you (to a man)'),
    LessonItem('أَنْتِ', 'anti', 'you (to a woman)'),
    LessonItem('هُوَ', 'huwa', 'he'),
    LessonItem('هِيَ', 'hiya', 'she'),
    LessonItem('نَحْنُ', 'naḥnu', 'we'),
    LessonItem('هُمْ', 'hum', 'they'),
    LessonItem('هٰذَا', 'hādhā', 'this (masculine)'),
    LessonItem('هٰذِهِ', 'hādhihi', 'this (feminine)'),
    LessonItem('مَا', 'mā', 'what'),
    LessonItem('مَنْ', 'man', 'who'),
    LessonItem('أَيْنَ', 'ayna', 'where'),
    LessonItem('مَتَى', 'matā', 'when'),
    LessonItem('كَيْفَ', 'kayfa', 'how'),
    LessonItem('لِمَاذَا', 'limādhā', 'why'),
  ]),
  Unit('family', 'People and family', [
    LessonItem('أَب', 'ab', 'father'),
    LessonItem('أُمّ', 'umm', 'mother'),
    LessonItem('أَخ', 'akh', 'brother'),
    LessonItem('أُخْت', 'ukht', 'sister'),
    LessonItem('اِبْن', 'ibn', 'son'),
    LessonItem('بِنْت', 'bint', 'girl, daughter'),
    LessonItem('وَلَد', 'walad', 'boy'),
    LessonItem('رَجُل', 'rajul', 'man'),
    LessonItem('اِمْرَأَة', 'imraʾa', 'woman'),
    LessonItem('طِفْل', 'ṭifl', 'child'),
    LessonItem('صَدِيق', 'ṣadīq', 'friend'),
    LessonItem('زَوْج', 'zawj', 'husband'),
    LessonItem('زَوْجَة', 'zawja', 'wife'),
    LessonItem('جَدّ', 'jadd', 'grandfather'),
    LessonItem('جَدَّة', 'jadda', 'grandmother'),
  ]),
  Unit('food', 'Food and drink', [
    LessonItem('مَاء', 'māʾ', 'water'),
    LessonItem('خُبْز', 'khubz', 'bread'),
    LessonItem('حَلِيب', 'ḥalīb', 'milk'),
    LessonItem('شَاي', 'shāy', 'tea'),
    LessonItem('قَهْوَة', 'qahwa', 'coffee'),
    LessonItem('لَحْم', 'laḥm', 'meat'),
    LessonItem('سَمَك', 'samak', 'fish'),
    LessonItem('دَجَاج', 'dajāj', 'chicken'),
    LessonItem('أَرُزّ', 'aruzz', 'rice'),
    LessonItem('بَيْض', 'bayḍ', 'eggs'),
    LessonItem('تُفَّاح', 'tuffāḥ', 'apples'),
    LessonItem('فَاكِهَة', 'fākiha', 'fruit'),
    LessonItem('مِلْح', 'milḥ', 'salt'),
    LessonItem('سُكَّر', 'sukkar', 'sugar'),
    LessonItem('عَسَل', 'ʿasal', 'honey'),
  ]),
  Unit('home', 'Home and things', [
    LessonItem('بَيْت', 'bayt', 'house'),
    LessonItem('بَاب', 'bāb', 'door'),
    LessonItem('غُرْفَة', 'ghurfa', 'room'),
    LessonItem('مَطْبَخ', 'maṭbakh', 'kitchen'),
    LessonItem('نَافِذَة', 'nāfidha', 'window'),
    LessonItem('كِتَاب', 'kitāb', 'book'),
    LessonItem('قَلَم', 'qalam', 'pen'),
    LessonItem('كُرْسِيّ', 'kursiyy', 'chair'),
    LessonItem('طَاوِلَة', 'ṭāwila', 'table'),
    LessonItem('سَرِير', 'sarīr', 'bed'),
    LessonItem('مِفْتَاح', 'miftāḥ', 'key'),
    LessonItem('هَاتِف', 'hātif', 'phone'),
    LessonItem('حَقِيبَة', 'ḥaqība', 'bag'),
    LessonItem('سَيَّارَة', 'sayyāra', 'car'),
  ]),
  Unit('numbers', 'Numbers one to ten', [
    LessonItem('وَاحِد', 'wāḥid', 'one · ١'),
    LessonItem('اِثْنَان', 'ithnān', 'two · ٢'),
    LessonItem('ثَلَاثَة', 'thalātha', 'three · ٣'),
    LessonItem('أَرْبَعَة', 'arbaʿa', 'four · ٤'),
    LessonItem('خَمْسَة', 'khamsa', 'five · ٥'),
    LessonItem('سِتَّة', 'sitta', 'six · ٦'),
    LessonItem('سَبْعَة', 'sabʿa', 'seven · ٧'),
    LessonItem('ثَمَانِيَة', 'thamāniya', 'eight · ٨'),
    LessonItem('تِسْعَة', 'tisʿa', 'nine · ٩'),
    LessonItem('عَشَرَة', 'ʿashara', 'ten · ١٠'),
  ]),
  Unit('describing', 'Colours and describing', [
    LessonItem('أَبْيَض', 'abyaḍ', 'white'),
    LessonItem('أَسْوَد', 'aswad', 'black'),
    LessonItem('أَحْمَر', 'aḥmar', 'red'),
    LessonItem('أَخْضَر', 'akhḍar', 'green'),
    LessonItem('أَزْرَق', 'azraq', 'blue'),
    LessonItem('أَصْفَر', 'aṣfar', 'yellow'),
    LessonItem('كَبِير', 'kabīr', 'big'),
    LessonItem('صَغِير', 'ṣaghīr', 'small'),
    LessonItem('جَدِيد', 'jadīd', 'new'),
    LessonItem('قَدِيم', 'qadīm', 'old'),
    LessonItem('جَمِيل', 'jamīl', 'beautiful'),
    LessonItem('طَوِيل', 'ṭawīl', 'long, tall'),
    LessonItem('قَصِير', 'qaṣīr', 'short'),
    LessonItem('سَهْل', 'sahl', 'easy'),
    LessonItem('صَعْب', 'ṣaʿb', 'difficult'),
  ]),
  Unit('time', 'Time and days', [
    LessonItem('يَوْم', 'yawm', 'day'),
    LessonItem('لَيْلَة', 'layla', 'night'),
    LessonItem('أُسْبُوع', 'usbūʿ', 'week'),
    LessonItem('شَهْر', 'shahr', 'month'),
    LessonItem('سَنَة', 'sana', 'year'),
    LessonItem('سَاعَة', 'sāʿa', 'hour, clock'),
    LessonItem('دَقِيقَة', 'daqīqa', 'minute'),
    LessonItem('وَقْت', 'waqt', 'time'),
    LessonItem('اَلْيَوْم', 'al-yawm', 'today'),
    LessonItem('غَدًا', 'ghadan', 'tomorrow'),
    LessonItem('أَمْس', 'ams', 'yesterday'),
    LessonItem('اَلْآن', 'al-ān', 'now'),
  ]),
  Unit('places', 'Places', [
    LessonItem('مَدْرَسَة', 'madrasa', 'school'),
    LessonItem('مَسْجِد', 'masjid', 'mosque'),
    LessonItem('سُوق', 'sūq', 'market'),
    LessonItem('مَدِينَة', 'madīna', 'city'),
    LessonItem('شَارِع', 'shāriʿ', 'street'),
    LessonItem('مَطَار', 'maṭār', 'airport'),
    LessonItem('مَطْعَم', 'maṭʿam', 'restaurant'),
    LessonItem('مُسْتَشْفَى', 'mustashfā', 'hospital'),
    LessonItem('جَامِعَة', 'jāmiʿa', 'university'),
    LessonItem('مَكْتَبَة', 'maktaba', 'library'),
    LessonItem('بَلَد', 'balad', 'country'),
    LessonItem('بَحْر', 'baḥr', 'sea'),
    LessonItem('جَبَل', 'jabal', 'mountain'),
    LessonItem('نَهْر', 'nahr', 'river'),
  ]),
  Unit('verbs', 'Common verbs', [
    LessonItem('كَتَبَ', 'kataba', 'he wrote'),
    LessonItem('قَرَأَ', 'qaraʾa', 'he read'),
    LessonItem('ذَهَبَ', 'dhahaba', 'he went'),
    LessonItem('خَرَجَ', 'kharaja', 'he went out'),
    LessonItem('جَلَسَ', 'jalasa', 'he sat'),
    LessonItem('أَكَلَ', 'akala', 'he ate'),
    LessonItem('شَرِبَ', 'shariba', 'he drank'),
    LessonItem('فَتَحَ', 'fataḥa', 'he opened'),
    LessonItem('سَمِعَ', 'samiʿa', 'he heard'),
    LessonItem('عَرَفَ', 'ʿarafa', 'he knew'),
    LessonItem('عَمِلَ', 'ʿamila', 'he worked'),
    LessonItem('دَرَسَ', 'darasa', 'he studied'),
    LessonItem('قَالَ', 'qāla', 'he said'),
    LessonItem('كَانَ', 'kāna', 'he was'),
    LessonItem('رَأَى', 'raʾā', 'he saw'),
  ]),
  Unit('quran', 'Words from the Quran', [
    LessonItem('اللَّه', 'Allāh', 'God'),
    LessonItem('رَبّ', 'rabb', 'Lord'),
    LessonItem('رَسُول', 'rasūl', 'messenger'),
    LessonItem('دِين', 'dīn', 'religion'),
    LessonItem('صَلَاة', 'ṣalāh', 'prayer'),
    LessonItem('رَحْمَة', 'raḥma', 'mercy'),
    LessonItem('أَرْض', 'arḍ', 'earth'),
    LessonItem('سَمَاء', 'samāʾ', 'sky, heaven'),
    LessonItem('نَاس', 'nās', 'people'),
    LessonItem('قَلْب', 'qalb', 'heart'),
    LessonItem('نُور', 'nūr', 'light'),
    LessonItem('حَقّ', 'ḥaqq', 'truth'),
    LessonItem('عِلْم', 'ʿilm', 'knowledge'),
    LessonItem('خَيْر', 'khayr', 'good'),
    LessonItem('صَبْر', 'ṣabr', 'patience'),
    LessonItem('جَنَّة', 'janna', 'garden, paradise'),
    LessonItem('نَار', 'nār', 'fire'),
  ]),
];

const List<Unit> _phrasesUnits = [
  Unit('meeting', 'Meeting people', [
    LessonItem('اَلسَّلَامُ عَلَيْكُمْ', 'as-salāmu ʿalaykum', 'Peace be upon you'),
    LessonItem('وَعَلَيْكُمُ السَّلَامُ', 'wa-ʿalaykumu s-salām', 'And upon you be peace'),
    LessonItem('صَبَاحُ الْخَيْرِ', 'ṣabāḥu l-khayr', 'Good morning'),
    LessonItem('مَسَاءُ الْخَيْرِ', 'masāʾu l-khayr', 'Good evening'),
    LessonItem('أَهْلًا وَسَهْلًا', 'ahlan wa-sahlan', 'Welcome'),
    LessonItem('كَيْفَ حَالُكَ؟', 'kayfa ḥāluka?', 'How are you?'),
    LessonItem('أَنَا بِخَيْرٍ', 'anā bi-khayr', 'I am well'),
    LessonItem('مَا اسْمُكَ؟', 'mā smuka?', 'What is your name?'),
    LessonItem('اِسْمِي أَحْمَدُ', 'ismī Aḥmad', 'My name is Ahmad'),
    LessonItem('مِنْ أَيْنَ أَنْتَ؟', 'min ayna anta?', 'Where are you from?'),
    LessonItem('أَنَا مِنْ مِصْرَ', 'anā min Miṣr', 'I am from Egypt'),
    LessonItem('إِلَى اللِّقَاءِ', 'ilā l-liqāʾ', 'See you later'),
    LessonItem('مَعَ السَّلَامَةِ', 'maʿa s-salāma', 'Goodbye'),
  ]),
  Unit('describing', 'Saying what something is', [
    LessonItem('هٰذَا كِتَابٌ', 'hādhā kitābun', 'This is a book'),
    LessonItem('هٰذِهِ مَدْرَسَةٌ', 'hādhihi madrasatun', 'This is a school'),
    LessonItem('أَنَا طَالِبٌ', 'anā ṭālibun', 'I am a student'),
    LessonItem('هُوَ مُعَلِّمٌ', 'huwa muʿallimun', 'He is a teacher'),
    LessonItem('هِيَ طَبِيبَةٌ', 'hiya ṭabībatun', 'She is a doctor'),
    LessonItem('اَلْبَيْتُ كَبِيرٌ', 'al-baytu kabīrun', 'The house is big'),
    LessonItem('اَلْوَلَدُ صَغِيرٌ', 'al-waladu ṣaghīrun', 'The boy is small'),
    LessonItem('اَلْقَهْوَةُ حَارَّةٌ', 'al-qahwatu ḥārratun', 'The coffee is hot'),
    LessonItem('اَلْكِتَابُ عَلَى الطَّاوِلَةِ', 'al-kitābu ʿalā ṭ-ṭāwilati', 'The book is on the table'),
    LessonItem('اَلْقَلَمُ فِي الْحَقِيبَةِ', 'al-qalamu fī l-ḥaqībati', 'The pen is in the bag'),
    LessonItem('عِنْدِي سَيَّارَةٌ جَدِيدَةٌ', 'ʿindī sayyāratun jadīdatun', 'I have a new car'),
    LessonItem('أَيْنَ الْمَسْجِدُ؟', 'ayna l-masjidu?', 'Where is the mosque?'),
  ]),
  Unit('doing', 'Saying what you do', [
    LessonItem('أُرِيدُ مَاءً', 'urīdu māʾan', 'I want water'),
    LessonItem('أَشْرَبُ الشَّايَ', 'ashrabu sh-shāya', 'I drink tea'),
    LessonItem('آكُلُ الْخُبْزَ', 'ākulu l-khubza', 'I eat bread'),
    LessonItem('أُحِبُّ الْقَهْوَةَ', 'uḥibbu l-qahwata', 'I love coffee'),
    LessonItem('أَقْرَأُ كِتَابًا', 'aqraʾu kitāban', 'I am reading a book'),
    LessonItem('لَا أَفْهَمُ', 'lā afhamu', 'I do not understand'),
    LessonItem('أَتَكَلَّمُ الْعَرَبِيَّةَ', 'atakallamu l-ʿarabiyyata', 'I speak Arabic'),
    LessonItem('هَلْ تَتَكَلَّمُ الْعَرَبِيَّةَ؟', 'hal tatakallamu l-ʿarabiyyata?', 'Do you speak Arabic?'),
    LessonItem('أَسْكُنُ فِي الْمَدِينَةِ', 'askunu fī l-madīnati', 'I live in the city'),
    LessonItem('أَذْهَبُ إِلَى الْمَدْرَسَةِ', 'adhhabu ilā l-madrasati', 'I go to school'),
    LessonItem('كَتَبَ الْوَلَدُ الدَّرْسَ', 'kataba l-waladu d-darsa', 'The boy wrote the lesson'),
    LessonItem('ذَهَبَ الرَّجُلُ إِلَى السُّوقِ', 'dhahaba r-rajulu ilā s-sūqi', 'The man went to the market'),
  ]),
  Unit('remembrance', 'From the Quran and daily remembrance', [
    LessonItem('بِسْمِ اللَّهِ الرَّحْمٰنِ الرَّحِيمِ', 'bismi llāhi r-raḥmāni r-raḥīm', 'In the name of God, the Entirely Merciful, the Especially Merciful'),
    LessonItem('اَلْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ', 'al-ḥamdu lillāhi rabbi l-ʿālamīn', 'All praise is for God, Lord of the worlds'),
    LessonItem('إِيَّاكَ نَعْبُدُ', 'iyyāka naʿbudu', 'You alone we worship'),
    LessonItem('اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ', 'ihdinā ṣ-ṣirāṭa l-mustaqīm', 'Guide us to the straight path'),
    LessonItem('قُلْ هُوَ اللَّهُ أَحَدٌ', 'qul huwa llāhu aḥad', 'Say: He is God, the One'),
    LessonItem('لَا إِلٰهَ إِلَّا اللَّهُ', 'lā ilāha illā llāh', 'There is no god but God'),
    LessonItem('اَللَّهُ أَكْبَرُ', 'Allāhu akbar', 'God is greatest'),
    LessonItem('سُبْحَانَ اللَّهِ', 'subḥāna llāh', 'Glory be to God'),
    LessonItem('إِنْ شَاءَ اللَّهُ', 'in shāʾa llāh', 'If God wills'),
    LessonItem('مَا شَاءَ اللَّهُ', 'mā shāʾa llāh', 'What God has willed'),
    LessonItem('أَسْتَغْفِرُ اللَّهَ', 'astaghfiru llāh', 'I ask God\'s forgiveness'),
    LessonItem('جَزَاكَ اللَّهُ خَيْرًا', 'jazāka llāhu khayran', 'May God reward you with good'),
  ]),
];

final List<Course> courses = [
  Course(
    'marks',
    CourseKind.mark,
    'Vowel marks',
    'Arabic letters are consonants. Small marks above and below them say which vowel follows, and reading them is the step after the alphabet.',
    _marksUnits,
  ),
  const Course(
    'words',
    CourseKind.word,
    'Words',
    'Common words by topic: what they mean, how they are read, how they sound and how they are spelled.',
    _wordsUnits,
  ),
  const Course(
    'phrases',
    CourseKind.phrase,
    'Phrases',
    'Whole sentences: put the words in order, fill the gap and understand what you hear.',
    _phrasesUnits,
  ),
];
