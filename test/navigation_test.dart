import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingora/main.dart';
import 'package:lingora/progress.dart';

void main() {
  testWidgets('guest progress loads and map opens a real lesson', (tester) async {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    String? saved = (Progress()..onboarded = true).encode();
    messenger.setMockMethodCallHandler(Progress.channel, (call) async {
      if (call.method == 'loadProgress') return saved;
      if (call.method == 'saveProgress') { saved = call.arguments as String; }
      return null;
    });
    await tester.pumpWidget(const Lingora());
    await tester.runAsync(() async { await Future<void>.delayed(const Duration(milliseconds: 100)); });
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learn'));
    await tester.pumpAndSettle();
    expect(find.text('Adventure map'), findsOneWidget);
    await tester.tap(find.text('Greetings').first);
    await tester.pumpAndSettle();
    expect(find.text('Hello.'), findsOneWidget);
    expect(tester.widget<Text>(find.text('سلام۔')).textDirection, TextDirection.rtl);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(Progress.decode(saved!).activeIndex, 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lumi AI').first);
    await tester.pumpAndSettle();
    expect(find.text('Tutor setup required'), findsOneWidget);
    verifyNoExceptions(tester);
    messenger.setMockMethodCallHandler(Progress.channel, null);
  });
}

void verifyNoExceptions(WidgetTester tester) => expect(tester.takeException(), isNull);
