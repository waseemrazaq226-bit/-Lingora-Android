import 'dart:convert';
import 'dart:math';

class Phrase {
  Phrase(Map<String, dynamic> data)
      : en = data['en'] as String,
        ur = data['ur'] as String,
        tip = data['tip'] as String,
        urduTip = data['urduTip'] as String;
  final String en, ur, tip, urduTip;
}

class Lesson {
  Lesson(Map<String, dynamic> data)
      : id = data['id'] as String,
        title = data['title'] as String,
        urdu = data['urdu'] as String,
        phrases = (data['entries'] as List<dynamic>)
            .map((row) => Phrase(row as Map<String, dynamic>)).toList();
  final String id, title, urdu;
  final List<Phrase> phrases;

  List<Exercise> exercises({required bool urdu, bool review = false}) {
    final result = <Exercise>[];
    final random = Random(id.codeUnits.fold<int>(0, (a, b) => a + b));
    for (var index = 0; index < phrases.length; index++) {
      final phrase = phrases[index];
      final answer = phrase.en;
      final meaning = urdu ? phrase.ur : phrase.tip;
      final words = normalize(answer).split(' ');
      if (!review) {
        result.add(Exercise('Study the phrase', answer, phrase, study: true));
      }
      final options = phrases.map((p) => p.en).toList()..shuffle(random);
      result.add(Exercise('Choose the English phrase', meaning, phrase,
          options: options));
      if (index.isEven) {
        result.add(Exercise('Build the phrase', meaning, phrase,
            tiles: [...words]..shuffle(random)));
      } else {
        result.add(Exercise('Fill in the missing word',
            '$meaning\n\n${words.take(words.length - 1).join(' ')} ___', phrase,
            expected: words.last));
      }
    }
    if (!review) {
      final phrase = phrases.last;
      result.add(Exercise('Listen and choose', 'Which phrase did you hear?',
          phrase, listening: true, options: phrases.map((p) => p.en).toList()..shuffle(random)));
    }
    return result;
  }
}

class World {
  World(Map<String, dynamic> data)
      : title = data['title'] as String,
        urdu = data['urdu'] as String,
        lessons = (data['lessons'] as List<dynamic>)
            .map((row) => Lesson(row as Map<String, dynamic>)).toList();
  final String title, urdu;
  final List<Lesson> lessons;
}

List<World> parseCourse(String json) => (jsonDecode(json) as List<dynamic>)
    .map((row) => World(row as Map<String, dynamic>)).toList();

String normalize(String input) => input.toLowerCase().trim()
    .replaceAll('’', "'").replaceAll(RegExp(r'[.!?,۔؟]'), '')
    .replaceAll(RegExp(r'\s+'), ' ');

class Exercise {
  const Exercise(this.instruction, this.prompt, this.phrase,
      {this.options = const [], this.tiles = const [], this.expected, this.study = false, this.listening = false});
  final String instruction, prompt;
  final Phrase phrase;
  final List<String> options, tiles;
  final String? expected;
  final bool study, listening;
  String get answer => expected ?? phrase.en;
  bool accepts(String input) => normalize(input) == normalize(answer);
}
