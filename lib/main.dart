import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'academy.dart';
import 'catalog.dart';
import 'course.dart';
import 'lesson_screen.dart';
import 'lumi_screen.dart';
import 'progress.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Lingora());
}

class Lingora extends StatefulWidget {
  const Lingora({super.key});
  @override
  State<Lingora> createState() => _LingoraState();
}

class _LingoraState extends State<Lingora> {
  late Future<(Progress, List<World>)> loading;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    loading = load();
  }

  Future<(Progress, List<World>)> load() async =>
      (await Progress.load(), parseCourse(await rootBundle.loadString('assets/english_urdu.json')));

  void refresh() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) => FutureBuilder<(Progress, List<World>)>(
    future: loading,
    builder: (context, snapshot) {
      final data = snapshot.data;
      final light = data?.$1.light ?? false;
      return MaterialApp(
        title: 'LINGORA', debugShowCheckedModeBanner: false,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('en'), Locale('ur')],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: purple,
            brightness: light ? Brightness.light : Brightness.dark,
            surface: light ? const Color(0xfffaf6ff) : const Color(0xff221a40)),
          scaffoldBackgroundColor: light ? const Color(0xfff7f1ff) : midnight,
          filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
            backgroundColor: purple, foregroundColor: Colors.white,
            minimumSize: const Size(52, 51), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          )),
          inputDecorationTheme: InputDecorationTheme(
            filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        home: snapshot.hasError ? Scaffold(body: Center(child: FilledButton(
          onPressed: () => setState(() => loading = load()), child: const Text('Retry loading LINGORA'),
        ))) : data == null ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : !data.$1.onboarded ? Onboarding(progress: data.$1, finish: refresh)
            : AcademyHome(progress: data.$1, worlds: data.$2, index: tab,
              select: (value) => setState(() => tab = value), refresh: refresh),
      );
    },
  );
}

class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.progress, required this.finish});
  final Progress progress;
  final VoidCallback finish;
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int stage = 0;
  String issue = '';
  bool saving = false;
  Progress get progress => widget.progress;
  final custom = TextEditingController(text: '10');
  bool customGoal = false;
  static const levels = ['Complete beginner', 'Know a few words', 'Intermediate', 'Advanced'];

  @override
  void dispose() { custom.dispose(); super.dispose(); }

  Future<void> next() async {
    if (stage == 3 && customGoal) {
      final value = int.tryParse(custom.text);
      if (value == null || value < 1 || value > 180) {
        setState(() => issue = 'Enter a goal between 1 and 180 minutes.');
        return;
      }
      progress.goal = value;
    }
    if (stage < 6) {
      setState(() { stage++; issue = ''; });
      return;
    }
    setState(() => saving = true);
    progress.onboarded = true;
    try { await progress.save(); widget.finish(); }
    on PlatformException {
      progress.onboarded = false;
      if (mounted) setState(() { saving = false; issue = 'Progress could not be saved. Try again.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = ['LINGORA', 'Explanation language', 'Choose a course', 'Daily study goal',
      'Your English level', 'Your interests', 'Your adventure begins'];
    final bodies = <Widget>[
      const AcademyBanner(title: 'LINGORA', subtitle: 'Your Language. Your Adventure. Your World.', mascot: true),
      Wrap(spacing: 10, runSpacing: 10, children: [
        ChoiceChip(label: const Text('Urdu · اردو'), selected: progress.urdu,
          onSelected: (_) => setState(() => progress.urdu = true)),
        ChoiceChip(label: const Text('English'), selected: !progress.urdu,
          onSelected: (_) => setState(() => progress.urdu = false)),
      ]),
      Column(children: [
        const ListTile(leading: Icon(Icons.check_circle, color: success),
          title: Text('English'), subtitle: Text('Available · Beginner course')),
        OutlinedButton(onPressed: () => Navigator.push(context,
          MaterialPageRoute<void>(builder: (_) => const CatalogScreen())),
          child: const Text('Browse language catalog')),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final goal in [5,10,15,20])
            ChoiceChip(label: Text('$goal minutes'), selected: !customGoal && progress.goal == goal,
              onSelected: (_) => setState(() { customGoal = false; progress.goal = goal; })),
          ChoiceChip(label: const Text('Custom'), selected: customGoal,
            onSelected: (_) => setState(() => customGoal = true)),
        ]),
        if (customGoal) Padding(padding: const EdgeInsets.only(top: 12), child: TextField(
          controller: custom, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minutes per day'),
        )),
      ]),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final level in levels)
          ChoiceChip(label: Text(level), selected: progress.level == level,
            onSelected: (_) => setState(() => progress.level = level)),
      ]),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final interest in ['Travel','School','Daily conversations','Work','Entertainment'])
          FilterChip(label: Text(interest), selected: progress.interests.contains(interest),
            onSelected: (enabled) => setState(() => enabled
              ? progress.interests.add(interest) : progress.interests.remove(interest))),
      ]),
      const AcademyBanner(title: 'Beginning Forest',
        subtitle: 'Meet Lumi and learn your first English greetings.', mascot: true),
    ];
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: stage > 0 ? BackButton(onPressed: saving ? null : () => setState(() { stage--; issue = ''; })) : null,
        title: Text('${stage + 1} of 7'),
      ),
      body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
        LinearProgressIndicator(value: (stage + 1) / 7, borderRadius: BorderRadius.circular(8)),
        const SizedBox(height: 34),
        if (stage > 0) ...[
          Text(titles[stage], style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),
        ],
        AnimatedSwitcher(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 220),
          child: KeyedSubtree(key: ValueKey(stage), child: bodies[stage]),
        ),
        if (stage == 1) const Padding(padding: EdgeInsets.only(top: 14),
          child: Text('This sets lesson explanations. App menus are in English.')),
        if (issue.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 15), child: Text(issue)),
        const SizedBox(height: 24),
        FilledButton(onPressed: saving ? null : next,
          child: Text(stage == 0 ? 'Get Started' : stage == 6 ? 'Begin as guest' : 'Continue')),
      ])),
    );
  }
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}
class _CatalogScreenState extends State<CatalogScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = languages.where((language) => language.matches(query)).toList();
    return Scaffold(appBar: AppBar(title: const Text('Language catalog')),
      body: SafeArea(child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(labelText: 'Search languages', prefixIcon: Icon(Icons.search)),
        )),
        Expanded(child: filtered.isEmpty ? const Center(child: Text('No matching languages.'))
          : ListView.builder(itemCount: filtered.length, itemBuilder: (context, index) {
            final language = filtered[index];
            return ListTile(
              leading: Icon(language.available ? Icons.auto_stories : Icons.lock_outline,
                color: language.available ? success : null),
              title: Text(language.name), subtitle: Text(language.nativeName),
              trailing: Text(language.status),
            );
          })),
      ])),
    );
  }
}

class AcademyHome extends StatelessWidget {
  const AcademyHome({super.key, required this.progress, required this.worlds,
    required this.index, required this.select, required this.refresh});
  final Progress progress;
  final List<World> worlds;
  final int index;
  final ValueChanged<int> select;
  final VoidCallback refresh;
  List<Lesson> get lessons => worlds.expand((world) => world.lessons).toList();
  Lesson? get nextLesson {
    for (final lesson in lessons) {
      if (!progress.completed.contains(lesson.id)) return lesson;
    }
    return null;
  }

  Future<void> persist(BuildContext context) async {
    refresh();
    try { await progress.save(); }
    on PlatformException {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save changes.')));
    }
  }

  void start(BuildContext context, Lesson lesson, {bool review = false}) async {
    await Navigator.push(context, MaterialPageRoute<void>(builder: (_) =>
      LessonScreen(lesson: lesson, progress: progress, review: review)));
    refresh();
  }

  Widget scroll(List<Widget> children) => SafeArea(
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720),
      child: ListView(primary: false, padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: children))),
  );

  Widget heading(String text) => Padding(padding: const EdgeInsets.only(top: 22, bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)));

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final next = nextLesson;
    final completed = progress.completed.length;
    final due = lessons.where((lesson) => progress.completed.contains(lesson.id) && progress.due(lesson.id, now)).toList();
    final titles = ['LINGORA', 'Adventure map', 'Lumi AI', 'Rewards', 'Profile'];
    return Scaffold(
      appBar: AppBar(title: Text(titles[index], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(tooltip: 'Language catalog', icon: const Icon(Icons.language),
            onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
              builder: (_) => const CatalogScreen()))),
        ]),
      bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), label: 'Learn'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Lumi AI'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), label: 'Rewards'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ]),
      body: IndexedStack(index: index, children: [
        scroll([
          AcademyBanner(title: 'Welcome, ${progress.name}',
            subtitle: 'Your Language. Your Adventure. Your World.', mascot: true,
            accessory: progress.accessory),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 5, children: [
            Chip(avatar: const Icon(Icons.bolt, color: gold), label: Text('${progress.xp} XP')),
            Chip(avatar: const Icon(Icons.diamond_outlined, color: aqua), label: Text('${progress.gems} gems')),
            if (progress.streaks)
              Chip(avatar: const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                label: Text('${progress.streak(now)} day streak')),
          ]),
          heading('Today’s goal'),
          Text('${progress.secondsToday(now) ~/ 60} of ${progress.goal} minutes'),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: math.min(1.0, progress.secondsToday(now) / (progress.goal * 60))),
          heading(next == null ? 'Course complete' : 'Continue learning'),
          if (next != null) FilledButton(onPressed: () => start(context, next),
            child: Text(next.title)),
          if (next == null) OutlinedButton(onPressed: () => select(1), child: const Text('Revisit the adventure map')),
          heading('Vocabulary review'),
          Text(due.isEmpty ? 'Your next review will appear when it is due.' : '${due.length} lessons ready to review.'),
          if (due.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10),
            child: FilledButton.tonal(onPressed: () => start(context, due.first, review: true),
              child: const Text('Start spaced review'))),
        ]),
        scroll([
          for (final (worldIndex, world) in worlds.indexed) ...[
            const SizedBox(height: 10),
            AcademyBanner(title: world.title, world: worldIndex,
              subtitle: '${world.lessons.where((lesson) => progress.completed.contains(lesson.id)).length} of ${world.lessons.length} lessons complete'),
            if (progress.urdu) Padding(padding: const EdgeInsets.only(top: 7), child: UrduText(world.urdu)),
            for (final (lessonIndex, lesson) in world.lessons.indexed)
              Align(
                alignment: [Alignment.centerLeft, Alignment.center, Alignment.centerRight][lessonIndex % 3],
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: OutlinedButton.icon(
                  onPressed: lesson == next || progress.completed.contains(lesson.id)
                    ? () => start(context, lesson) : null,
                  icon: Icon(progress.completed.contains(lesson.id) ? Icons.check_circle
                      : lesson == next ? Icons.auto_awesome : Icons.lock_outline,
                    color: progress.completed.contains(lesson.id) ? success : null),
                  label: Text(lesson.title),
                )),
              ),
          ],
        ]),
        SafeArea(child: LumiScreen(progress: progress)),
        scroll([
          const AcademyBanner(title: 'Academy treasury', subtitle: 'Earn rewards by completing lessons.', world: 4),
          heading('Achievements'),
          badge('First Lesson Completed', completed > 0, Icons.auto_stories),
          badge('Vocabulary Explorer', completed >= 3, Icons.menu_book),
          badge('Grammar Champion', worlds[2].lessons.every((l) => progress.completed.contains(l.id)), Icons.edit_note),
          badge('Seven-Day Learner', progress.streaks && progress.streak(now) >= 7, Icons.event_available),
          badge('Castle Graduate', completed == lessons.length, Icons.castle),
          heading('Lumi accessories'),
          ListTile(leading: const Icon(Icons.stars, color: gold), title: const Text('Gold explorer frame'),
            subtitle: Text(progress.accessory ? 'Equipped' : '15 gems'),
            trailing: progress.accessory ? null : FilledButton(onPressed: progress.gems < 15 ? null : () {
              progress.gems -= 15; progress.accessory = true; persist(context);
            }, child: const Text('Unlock'))),
        ]),
        scroll([
          AcademyBanner(title: progress.name, subtitle: 'English · Level ${1 + progress.xp ~/ 100}',
            mascot: true, world: 3, accessory: progress.accessory),
          heading('Study statistics'),
          Text('${progress.xp} XP · $completed of ${lessons.length} lessons completed'),
          Text('${lessons.where((l) => progress.completed.contains(l.id)).fold<int>(0, (n, l) => n + l.phrases.length)} phrases studied'),
          for (var i = 6; i >= 0; i--) ...[
            Padding(padding: const EdgeInsets.only(top: 5), child: Text(
              '${progress.day(now.subtract(Duration(days: i)))} · ${(progress.activity[progress.day(now.subtract(Duration(days: i)))] ?? 0) ~/ 60} min')),
            LinearProgressIndicator(value: math.min(1.0, (progress.activity[
              progress.day(now.subtract(Duration(days: i)))] ?? 0) / (progress.goal * 60))),
          ],
          heading('Settings'),
          ListTile(leading: const Icon(Icons.collections_bookmark_outlined),
            title: const Text('Phrase collection'),
            onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) =>
              PhraseCollection(lessons: lessons.where((l) => progress.completed.contains(l.id)).toList(),
                urdu: progress.urdu)))),
          ListTile(leading: const Icon(Icons.help_outline), title: const Text('Help and privacy'),
            onTap: () => showAboutDialog(context: context, applicationName: 'LINGORA',
              applicationVersion: '1.0.0', children: const [
                Text('Guest learning progress is stored on this device. Clear it from Profile.'),
                SizedBox(height: 8),
                Text('Live tutoring requires a separately configured server. Only send practice text you are comfortable sharing with its provider.'),
              ])),
          ListTile(leading: const Icon(Icons.edit), title: const Text('Display name'),
            onTap: () async {
              var name = progress.name;
              final value = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(
                title: const Text('Display name'), content: TextFormField(initialValue: name,
                  maxLength: 24, onChanged: (value) => name = value),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(dialog, name.trim()), child: const Text('Save')),
                ],
              ));
              if (value != null && value.isNotEmpty && context.mounted) {
                progress.name = value; await persist(context);
              }
            }),
          ListTile(leading: const Icon(Icons.timer_outlined), title: const Text('Daily study goal'),
            trailing: DropdownButton<int>(value: progress.goal, items: ({5,10,15,20,progress.goal}.toList()..sort())
              .map((goal) => DropdownMenuItem(value: goal, child: Text('$goal min'))).toList(),
              onChanged: (value) { if (value != null) { progress.goal = value; persist(context); } })),
          SwitchListTile(title: const Text('Urdu explanations'), value: progress.urdu,
            onChanged: (value) { progress.urdu = value; persist(context); }),
          SwitchListTile(title: const Text('Light theme'), value: progress.light,
            onChanged: (value) { progress.light = value; persist(context); }),
          SwitchListTile(title: const Text('Show streaks'), value: progress.streaks,
            onChanged: (value) { progress.streaks = value; persist(context); }),
          ListTile(leading: const Icon(Icons.offline_pin), title: const Text('Offline course'),
            subtitle: const Text('English lessons and review are installed with LINGORA.')),
          ListTile(leading: const Icon(Icons.delete_outline), title: const Text('Delete device progress'),
            onTap: () async {
              final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
                title: const Text('Delete device progress?'),
                content: const Text('Lessons completed, rewards, settings and study activity will be erased.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Delete')),
                ],
              ));
              if (confirmed == true && context.mounted) {
                try {
                  await Progress().save();
                  progress.onboarded = false; progress.completed.clear();
                  progress.activity.clear(); progress.reviews.clear(); progress.intervals.clear();
                  progress.xp = 0; progress.gems = 0; progress.accessory = false;
                  progress.activeLesson = null; progress.activeIndex = 0; progress.activeSeconds = 0;
                  progress.name = 'Explorer'; progress.goal = 10; progress.urdu = true;
                  progress.light = false; progress.streaks = true;
                  progress.level = 'Complete beginner'; progress.interests = [];
                  select(0);
                } on PlatformException {
                  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not delete device progress.')));
                }
              }
            }),
        ]),
      ]),
    );
  }

  Widget badge(String name, bool earned, IconData icon) => ListTile(
    leading: Icon(earned ? icon : Icons.lock_outline, color: earned ? gold : null),
    title: Text(name), subtitle: Text(earned ? 'Earned' : 'Locked'),
  );
}

class PhraseCollection extends StatelessWidget {
  const PhraseCollection({super.key, required this.lessons, required this.urdu});
  final List<Lesson> lessons;
  final bool urdu;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Phrase collection')),
    body: SafeArea(child: lessons.isEmpty
      ? const Center(child: Text('Complete a lesson to collect its phrases.'))
      : ListView(padding: const EdgeInsets.all(16), children: [
        for (final lesson in lessons) ExpansionTile(title: Text(lesson.title), children: [
          for (final phrase in lesson.phrases) ListTile(
            title: Text(phrase.en), subtitle: urdu ? UrduText(phrase.ur) : Text(phrase.tip)),
        ]),
      ])),
  );
}
