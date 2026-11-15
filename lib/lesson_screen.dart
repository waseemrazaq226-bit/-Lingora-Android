import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'academy.dart';
import 'course.dart';
import 'progress.dart';

Future<void> speak(BuildContext context, String text, {double speed = 1}) async {
  try {
    await Progress.channel.invokeMethod<void>('speak', {'text': text, 'speed': speed});
  } on PlatformException catch (error) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.message ?? 'Audio is unavailable.')));
  }
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson, required this.progress, this.review = false});
  final Lesson lesson;
  final Progress progress;
  final bool review;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  late final List<Exercise> exercises;
  final written = TextEditingController();
  final tiles = <int>[];
  final timer = Stopwatch()..start();
  late int index;
  int priorSeconds = 0;
  String? choice;
  bool? correct;
  bool struggled = false, complete = false, saving = false, pendingSave = false;
  int earned = 0;
  Progress get progress => widget.progress;
  Exercise get exercise => exercises[index];

  @override
  void initState() {
    super.initState();
    exercises = widget.lesson.exercises(urdu: progress.urdu, review: widget.review);
    final resume = !widget.review && progress.activeLesson == widget.lesson.id;
    index = resume ? progress.activeIndex.clamp(0, exercises.length - 1).toInt() : 0;
    priorSeconds = resume ? progress.activeSeconds : 0;
  }

  @override
  void dispose() {
    written.dispose();
    Progress.channel.invokeMethod<void>('stopSpeech').catchError((Object _) {});
    super.dispose();
  }

  Future<void> playPhrase() async {
    final phraseIndex = widget.lesson.phrases.indexOf(exercise.phrase);
    try {
      await Progress.channel.invokeMethod<void>('playAsset',
        {'asset': 'assets/audio/${widget.lesson.id}_$phraseIndex.mp3'});
    } on PlatformException {
      if (mounted) await speak(context, exercise.phrase.en);
    }
  }

  void check(String input) {
    setState(() {
      correct = exercise.accepts(input);
      struggled = struggled || correct == false;
    });
    if (correct == true) HapticFeedback.selectionClick();
  }

  Future<void> next() async {
    if (saving) return;
    setState(() => saving = true);
    if (!pendingSave) {
      final id = widget.lesson.id;
      final seconds = priorSeconds + timer.elapsed.inSeconds;
      if (index == exercises.length - 1) {
        final before = progress.xp;
        progress.finish(id, seconds, DateTime.now(), review: widget.review, struggled: struggled);
        earned = progress.xp - before;
      } else if (!widget.review) {
        progress.activeLesson = id;
        progress.activeIndex = index + 1;
        progress.activeSeconds = seconds;
      }
      pendingSave = true;
    }
    try {
      if (!widget.review || index == exercises.length - 1) await progress.save();
      if (!mounted) return;
      setState(() {
        saving = false; pendingSave = false;
        if (index == exercises.length - 1) {
          complete = true;
        } else {
          index++;
          correct = null; choice = null; tiles.clear(); written.clear();
        }
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Could not save progress. Tap Continue to retry.')));
    }
  }

  Future<void> restart() async {
    setState(() => saving = true);
    try {
      if (!widget.review && progress.activeLesson == widget.lesson.id) {
        progress.activeIndex = 0;
        progress.activeSeconds = 0;
        await progress.save();
      }
      if (!mounted) return;
      setState(() {
        index = 0; priorSeconds = 0; timer.reset(); correct = null; choice = null;
        tiles.clear(); written.clear(); struggled = false; saving = false;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not restart.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.lesson.title), actions: [
      if (!complete) IconButton(tooltip: 'Restart lesson', icon: const Icon(Icons.restart_alt),
        onPressed: saving || pendingSave ? null : restart),
    ]),
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 650),
      child: ListView(padding: const EdgeInsets.all(20), children: complete ? [
        TweenAnimationBuilder<double>(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 320),
          tween: Tween(begin: .86, end: 1),
          curve: Curves.easeOutBack,
          builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
          child: AcademyBanner(title: widget.review ? 'Review complete!' : 'Lesson complete!',
          subtitle: '+$earned XP', world: 4, mascot: true),
        const SizedBox(height: 18),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Back to academy')),
      ] : [
        Semantics(label: 'Exercise ${index + 1} of ${exercises.length}',
          child: LinearProgressIndicator(value: (index + 1) / exercises.length)),
        const SizedBox(height: 20),
        Text(exercise.instruction, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (!exercise.study && !exercise.listening && progress.urdu)
          UrduText(exercise.prompt, style: Theme.of(context).textTheme.titleLarge)
        else Text(exercise.prompt, textDirection: TextDirection.ltr, style: Theme.of(context).textTheme.titleLarge),
        if (exercise.listening) Align(alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(onPressed: playPhrase, icon: const Icon(Icons.volume_up),
            label: const Text('Play recording'))),
        if (exercise.study) ...[
          const SizedBox(height: 10),
          if (progress.urdu) UrduText(exercise.phrase.ur, style: Theme.of(context).textTheme.titleLarge),
          IconButton(tooltip: 'Listen to this English phrase', alignment: Alignment.centerLeft,
            icon: const Icon(Icons.volume_up), onPressed: playPhrase),
          if (progress.urdu) UrduText(exercise.phrase.urduTip) else Text(exercise.phrase.tip),
        ],
        if (exercise.options.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 14),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final option in exercise.options)
              ChoiceChip(label: Text(option), selected: choice == option,
                onSelected: correct != null ? null : (_) => setState(() => choice = option)),
          ])),
        if (exercise.tiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(tiles.isEmpty ? 'Tap the words in order.' : 'Your phrase'),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final tile in tiles)
              InputChip(label: Text(exercise.tiles[tile]),
                onDeleted: correct != null ? null : () => setState(() => tiles.remove(tile))),
          ]),
          const Divider(),
          Wrap(spacing: 7, runSpacing: 7, children: [
            for (final (tile, word) in exercise.tiles.indexed)
              if (!tiles.contains(tile)) ActionChip(label: Text(word),
                onPressed: correct != null ? null : () => setState(() => tiles.add(tile))),
          ]),
        ],
        if (exercise.expected != null) Padding(padding: const EdgeInsets.only(top: 14),
          child: TextField(key: ValueKey(index), controller: written, enabled: correct == null,
            maxLength: 64, onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Missing word'))),
        if (correct != null) ...[
          const SizedBox(height: 15),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Semantics(liveRegion: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(correct! ? 'Correct!' : 'Answer: ${exercise.answer}',
                style: TextStyle(fontWeight: FontWeight.bold, color: correct! ? success : null)),
              const SizedBox(height: 6),
              if (progress.urdu) UrduText(exercise.phrase.urduTip) else Text(exercise.phrase.tip),
            ]),
          ))),
        ],
        const SizedBox(height: 20),
        if (exercise.study || correct != null)
          FilledButton(onPressed: saving ? null : next, child: const Text('Continue'))
        else FilledButton(
          onPressed: choice == null && tiles.isEmpty && written.text.trim().isEmpty ? null :
            () => check(choice ?? (exercise.tiles.isNotEmpty
              ? tiles.map((tile) => exercise.tiles[tile]).join(' ') : written.text)),
          child: const Text('Check answer'),
        ),
      ]),
    ))),
  );
}
