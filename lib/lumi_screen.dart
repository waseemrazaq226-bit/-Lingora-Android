import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'academy.dart';
import 'lesson_screen.dart';
import 'progress.dart';
import 'tutor.dart';

class LumiScreen extends StatefulWidget {
  const LumiScreen({super.key, required this.progress});
  final Progress progress;
  @override
  State<LumiScreen> createState() => _LumiScreenState();
}

class _LumiScreenState extends State<LumiScreen> {
  static const scenarios = ['Free practice', 'Ordering food', 'Introductions', 'Directions',
    'School', 'Travel', 'Shopping', 'Job interview', 'Daily conversations'];
  final input = TextEditingController();
  final history = <Map<String, String>>[];
  TutorClient? client;
  String scenario = scenarios.first;
  String? error;
  bool sending = false, listening = false;
  double speed = 1;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    for (final interest in widget.progress.interests) {
      if (scenarios.contains(interest)) { scenario = interest; break; }
    }
  }

  @override
  void dispose() { input.dispose(); super.dispose(); }

  Future<void> connect() async {
    final url = TextEditingController(text: client?.endpoint.toString() ?? '');
    final token = TextEditingController();
    final result = await showDialog<TutorClient>(context: context, builder: (context) =>
      StatefulBuilder(builder: (context, update) => AlertDialog(
        title: const Text('Connect Lumi AI'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter your tutor server and student access code. Messages and course progress counts are sent to the configured provider.'),
          const SizedBox(height: 10),
          TextField(controller: url, keyboardType: TextInputType.url,
            onChanged: (_) => update(() {}), decoration: const InputDecoration(labelText: 'HTTPS server URL')),
          const SizedBox(height: 10),
          TextField(controller: token, obscureText: true, onChanged: (_) => update(() {}),
            decoration: const InputDecoration(labelText: 'Student access code')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: TutorClient.parseEndpoint(url.text) == null || token.text.trim().length < 24
            ? null : () => Navigator.pop(context, TutorClient(TutorClient.parseEndpoint(url.text)!, token.text.trim())),
            child: const Text('Connect')),
        ],
      )));
    await Future<void>.delayed(const Duration(milliseconds: 350));
    url.dispose(); token.dispose();
    if (mounted && result != null) setState(() { client = result; error = null; });
  }

  Future<void> send() async {
    final selected = client;
    final message = input.text.trim();
    if (selected == null || message.isEmpty || sending || listening) return;
    final ticket = ++generation;
    setState(() { sending = true; error = null; });
    final turn = {'role': 'user', 'content': message};
    final context = history.length > 10 ? history.sublist(history.length - 10) : history;
    try {
      final answer = await selected.send({
        'messages': [...context, turn],
        'scenario': scenario,
        'completed': widget.progress.completed.length,
        'level': widget.progress.level,
        'explanation': widget.progress.urdu ? 'ur' : 'en',
      });
      if (!mounted || ticket != generation) return;
      setState(() {
        history.addAll([turn, {'role': 'assistant', 'content': answer}]);
        if (history.length > 30) history.removeRange(0, 2);
        input.clear();
      });
    } on TutorError catch (failure) {
      if (mounted && ticket == generation) setState(() => error = failure.message);
    } finally {
      if (mounted && ticket == generation) setState(() => sending = false);
    }
  }

  Future<void> recognize() async {
    if (listening || sending) return;
    final ticket = generation;
    setState(() { listening = true; error = null; });
    try {
      final words = await Progress.channel.invokeMethod<String>('recognize');
      if (mounted && ticket == generation && words != null) input.text =
        words.length > 1000 ? words.substring(0, 1000) : words;
    } on PlatformException catch (failure) {
      if (mounted && ticket == generation) setState(() => error = failure.message ?? 'Speech recognition is unavailable.');
    } finally {
      if (mounted) setState(() => listening = false);
    }
  }

  @override
  Widget build(BuildContext context) => Center(child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 720),
    child: ListView(primary: false, padding: const EdgeInsets.all(16), children: [
      AcademyBanner(title: 'Practice with Lumi', world: 3, mascot: true,
        subtitle: client == null ? 'Tutor setup required' : 'AI-generated tutoring · English practice',
        accessory: widget.progress.accessory),
      const SizedBox(height: 14),
      if (client == null) ...[
        const Text('Connect a tutor server for live responses. Your offline lessons are available from Learn.'),
        const SizedBox(height: 10),
        FilledButton(onPressed: connect, child: const Text('Connect tutor server')),
      ] else ...[
        ListTile(title: const Text('Roleplay scenario'), subtitle: DropdownButton<String>(
          isExpanded: true, value: scenario,
          items: scenarios.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: sending ? null : (value) {
            if (value != null) setState(() { scenario = value; history.clear(); });
          },
        )),
        const Text('Leave out personal details. Android’s speech service handles microphone input. Review your transcript before sending.'),
        if (history.isNotEmpty) ...[
          Row(children: [
            const Icon(Icons.speed),
            Expanded(child: Slider(value: speed, min: .6, max: 1.4, divisions: 8,
              label: '${speed.toStringAsFixed(1)}×', onChanged: (value) => setState(() => speed = value))),
            IconButton(tooltip: 'Stop playback', icon: const Icon(Icons.stop_circle_outlined),
              onPressed: () => Progress.channel.invokeMethod<void>('stopSpeech')),
          ]),
          for (final message in history)
            Card(child: ListTile(
              title: Text(message['role'] == 'user' ? 'You' : 'Lumi · AI'),
              subtitle: Text(message['content']!, textDirection: message['role'] == 'assistant'
                && widget.progress.urdu ? TextDirection.rtl : TextDirection.ltr),
              trailing: message['role'] == 'assistant' && !widget.progress.urdu ? IconButton(
                tooltip: 'Read or replay English reply', icon: const Icon(Icons.volume_up),
                onPressed: () => speak(context, message['content']!, speed: speed),
              ) : null,
            )),
        ],
        const SizedBox(height: 12),
        TextField(controller: input, maxLength: 1000, maxLines: 3, enabled: !sending && !listening,
          decoration: const InputDecoration(labelText: 'Practice message')),
        if (error != null) Semantics(liveRegion: true, child: Text(error!)),
        Wrap(spacing: 8, runSpacing: 8, children: [
          OutlinedButton.icon(onPressed: sending || listening ? null : recognize,
            icon: const Icon(Icons.mic_none), label: Text(listening ? 'Listening…' : 'Speak English')),
          FilledButton(onPressed: sending || listening ? null : send,
            child: Text(sending ? 'Waiting for Lumi…' : error == null ? 'Send' : 'Retry')),
          TextButton(onPressed: () => setState(() {
            generation++; history.clear(); input.clear(); sending = false; error = null;
          }), child: const Text('Clear conversation')),
          TextButton(onPressed: () => setState(() {
            generation++; client = null; history.clear(); input.clear(); sending = false; error = null;
          }), child: const Text('Disconnect')),
        ]),
      ],
      const SizedBox(height: 22),
      OutlinedButton.icon(icon: const Icon(Icons.hearing), label: const Text('Listen and repeat'),
        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(
          builder: (_) => const SpeakingPractice()))),
    ]),
  ));
}

class SpeakingPractice extends StatefulWidget {
  const SpeakingPractice({super.key});
  @override
  State<SpeakingPractice> createState() => _SpeakingPracticeState();
}

class _SpeakingPracticeState extends State<SpeakingPractice> {
  static const phrases = ['Nice to meet you.', 'Can I have some water?', 'Where is the station?'];
  String phrase = phrases.first;
  String? transcript;
  bool listening = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Listen and repeat')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(20), children: [
      const AcademyBanner(title: 'Speaking practice', subtitle: 'Listen, repeat, and review the transcript.', world: 3),
      const SizedBox(height: 12),
      DropdownButton<String>(isExpanded: true, value: phrase, items: phrases
        .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
        onChanged: listening ? null : (value) {
          if (value != null) setState(() { phrase = value; transcript = null; });
        }),
      const Text('The transcript comes from Android speech recognition. Pronunciation assessment is unavailable.'),
      Wrap(spacing: 8, children: [
        OutlinedButton.icon(onPressed: listening ? null : () => speak(context, phrase, speed: .8),
          icon: const Icon(Icons.volume_up), label: const Text('Listen')),
        FilledButton.icon(onPressed: listening ? null : () async {
          setState(() => listening = true);
          String? result;
          try { result = await Progress.channel.invokeMethod<String>('recognize'); }
          on PlatformException catch (error) { result = error.message ?? 'Speech recognition is unavailable.'; }
          if (mounted) setState(() { transcript = result; listening = false; });
        }, icon: const Icon(Icons.mic_none), label: Text(listening ? 'Listening…' : 'Repeat')),
      ]),
      if (transcript != null) Padding(padding: const EdgeInsets.only(top: 12),
        child: Semantics(liveRegion: true, child: Text(transcript!))),
    ])),
  );
}
