import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_buddies/main.dart';
import 'package:math_buddies/ui/buddy.dart';
import 'package:math_buddies/ui/onboarding.dart';
import 'package:math_buddies/ui/widgets/game_widgets.dart';

void main() {
  testWidgets('App shows splash, then onboarding after the brand timer',
      (WidgetTester tester) async {
    // runAsync = REAL timers and REAL platform-channel replies. The splash
    // gate waits on BOTH (storage load + 1.9s brand timer), and fake-async
    // pumps schedule those differently across Flutter versions - which is
    // exactly what made this test flaky twice. Real async: no guessing.
    await tester.runAsync(() async {
      await tester.pumpWidget(const MathBuddiesApp());
      await tester.pump();
      // Splash (synchronous first frame).
      expect(find.text('Math Buddies'), findsOneWidget);
      expect(find.text('Playful math adventures!'), findsOneWidget);
      expect(find.byType(Buddy), findsOneWidget);
      // Wait past the 1.9s brand timer (real time) -> gate flips.
      await Future<void>.delayed(const Duration(milliseconds: 2300));
      await tester.pump();
      await tester.pump();
      expect(find.text('Ages 3-4'), findsOneWidget);
      expect(find.text('Ages 5-6'), findsOneWidget);
    });
  });

  testWidgets('Onboarding shows both age choices', (WidgetTester tester) async {
    // Direct screen test: no splash gate, no platform channels,
    // no pumpAndSettle (Buddy/FloatingStars repeat forever). Deterministic.
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    await tester.pump();
    expect(find.text('Math Buddies'), findsOneWidget);
    expect(find.text('Ages 3-4'), findsOneWidget);
    expect(find.text('Ages 5-6'), findsOneWidget);
  });

  testWidgets('AnswerPad reports picked value', (WidgetTester tester) async {
    int picked = -1;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnswerPad(
            options: const <int>[2, 4, 6],
            onPick: (int v) => picked = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('4'));
    expect(picked, 4);
  });
}
