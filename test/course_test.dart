import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingora/catalog.dart';
import 'package:lingora/course.dart';
import 'package:lingora/progress.dart';
import 'package:lingora/tutor.dart';

void main() {
  final course = parseCourse(File('assets/english_urdu.json').readAsStringSync());
  test('five worlds have unique lessons and all exercises validate offline', () {
    expect(course, hasLength(5));
    final lessons = course.expand((w) => w.lessons).toList();
    expect(lessons.map((l) => l.id).toSet(), hasLength(15));
    for (final lesson in lessons) {
      final exercises = lesson.exercises(urdu: true);
      expect(exercises, hasLength(10));
      expect(exercises.where((e) => e.listening), hasLength(1));
      for (final exercise in exercises) {
        expect(exercise.accepts(exercise.answer), isTrue);
        expect(exercise.accepts('wrong answer'), isFalse);
        expect(exercise.accepts('  ${exercise.answer.toUpperCase()}  '), isTrue);
        if (exercise.tiles.isNotEmpty) {
          expect((exercise.tiles.toList()..sort()),
              (normalize(exercise.answer).split(' ')..sort()));
        }
        if (exercise.options.isNotEmpty) expect(exercise.options, contains(exercise.answer));
      }
    }
  });
  test('rewards, profile and checkpoint round trip and reviews become due', () {
    final today = DateTime(2026, 11, 15, 12);
    final progress = Progress()..onboarded = true..urdu = true..goal = 15;
    progress.finish('w1l1', 70, today, review: false, struggled: false);
    progress.activeLesson = 'w1l2';
    progress.activeIndex = 4;
    final restored = Progress.decode(progress.encode());
    expect(restored.completed, {'w1l1'});
    expect(restored.activeLesson, 'w1l2');
    expect(restored.activeIndex, 4);
    expect(restored.xp, 30);
    expect(restored.gems, 5);
    expect(restored.secondsToday(today), 70);
    expect(restored.due('w1l1', today), isFalse);
    expect(restored.due('w1l1', today.add(const Duration(days: 1))), isTrue);
    restored.finish('w1l1', 50, today, review: true, struggled: true);
    expect(restored.xp, 40);
    expect(restored.gems, 5);
    expect(restored.activeLesson, 'w1l2');
  });
  test('catalog matches Unicode and advertises only bundled courses', () {
    expect(languages, hasLength(59));
    expect(languages.where((x) => x.available).single.code, 'en');
    expect(languages.where((x) => x.matches('اردو')).single.code, 'ur');
    expect(languages.where((x) => x.matches('日本語')).single.code, 'ja');
  });
  test('tutor client only accepts credential-free HTTPS base URLs', () {
    expect(TutorClient.parseEndpoint('https://tutor.example.org'), isNotNull);
    expect(TutorClient.parseEndpoint('http://tutor.example.org'), isNull);
    expect(TutorClient.parseEndpoint('https://user:token@tutor.example.org'), isNull);
  });
}
