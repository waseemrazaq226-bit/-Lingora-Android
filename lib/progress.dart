import 'dart:convert';
import 'package:flutter/services.dart';

class Progress {
  Progress();
  Progress.decode(String input) {
    final data = jsonDecode(input) as Map<String, dynamic>;
    onboarded = data['onboarded'] as bool? ?? false;
    urdu = data['urdu'] as bool? ?? true;
    light = data['light'] as bool? ?? false;
    streaks = data['streaks'] as bool? ?? true;
    name = data['name'] as String? ?? 'Explorer';
    goal = data['goal'] as int? ?? 10;
    level = data['level'] as String? ?? 'Complete beginner';
    interests = List<String>.from(data['interests'] as List<dynamic>? ?? []);
    xp = data['xp'] as int? ?? 0;
    gems = data['gems'] as int? ?? 0;
    accessory = data['accessory'] as bool? ?? false;
    completed.addAll(List<String>.from(data['completed'] as List<dynamic>? ?? []));
    reviews.addAll(Map<String, int>.from(data['reviews'] as Map<String, dynamic>? ?? {}));
    intervals.addAll(Map<String, int>.from(data['intervals'] as Map<String, dynamic>? ?? {}));
    activity.addAll(Map<String, int>.from(data['activity'] as Map<String, dynamic>? ?? {}));
    activeLesson = data['activeLesson'] as String?;
    activeIndex = data['activeIndex'] as int? ?? 0;
    activeSeconds = data['activeSeconds'] as int? ?? 0;
  }

  static const channel = MethodChannel('com.lingora.academy/device');
  bool onboarded = false, urdu = true, light = false, streaks = true, accessory = false;
  String name = 'Explorer', level = 'Complete beginner';
  List<String> interests = [];
  int goal = 10, xp = 0, gems = 0;
  final completed = <String>{};
  final reviews = <String, int>{}, intervals = <String, int>{}, activity = <String, int>{};
  String? activeLesson;
  int activeIndex = 0, activeSeconds = 0;

  static Future<Progress> load() async {
    final value = await channel.invokeMethod<String>('loadProgress');
    return value == null ? Progress() : Progress.decode(value);
  }

  String encode() => jsonEncode({
    'onboarded': onboarded, 'urdu': urdu, 'light': light, 'streaks': streaks,
    'name': name, 'level': level, 'interests': interests, 'goal': goal, 'xp': xp,
    'gems': gems, 'accessory': accessory, 'completed': completed.toList(),
    'reviews': reviews, 'intervals': intervals, 'activity': activity,
    'activeLesson': activeLesson, 'activeIndex': activeIndex, 'activeSeconds': activeSeconds,
  });

  Future<void> save() => channel.invokeMethod<void>('saveProgress', encode());

  String day(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  int secondsToday(DateTime date) => activity[day(date)] ?? 0;
  int streak(DateTime date) {
    var count = 0;
    var cursor = DateTime(date.year, date.month, date.day);
    if (!activity.containsKey(day(cursor))) {
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    while (activity.containsKey(day(cursor))) {
      count++;
      cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
    }
    return count;
  }

  bool due(String id, DateTime now) => (reviews[id] ?? 0) <= now.millisecondsSinceEpoch;
  void finish(String id, int seconds, DateTime now, {required bool review, required bool struggled}) {
    final first = completed.add(id);
    xp += first ? 30 : (review ? 10 : 5);
    if (first) gems += 5;
    final interval = struggled ? 0 : ((intervals[id] ?? 0) * 2).clamp(1, 32).toInt();
    intervals[id] = interval;
    reviews[id] = now.add(interval == 0 ? const Duration(hours: 4) : Duration(days: interval))
        .millisecondsSinceEpoch;
    activity.update(day(now), (value) => value + seconds, ifAbsent: () => seconds);
    if (!review) {
      activeLesson = null;
      activeIndex = 0;
      activeSeconds = 0;
    }
  }
}
