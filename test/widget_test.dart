import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_buddies/main.dart';
import 'package:math_buddies/ui/buddy.dart';
import 'package:math_buddies/ui/onboarding.dart';
import 'package:math_buddies/ui/widgets/game_widgets.dart';

void main() {
  testWidgets('App shows splash, then onboarding after the brand timer',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MathBuddiesApp());
    // Frame 1: splash is synchronous (no channels needed).
    await tester.pump();
    expect(find.text('Math Buddies'), findsOneWidget);
    expect(find.text('Playful math adventures!'), findsOneWidget);
    expect(find.byType(Buddy), findsOneWidget);
    // The splash has a 1.9s brand timer (Future.delayed). If we end the test
    // without draining it, flutter_test fails with "A Timer is still
    // pending". Advancing fake time past it also flips the gate -> this
    // verifies the splash->onboarding transition deterministically.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Ages 3-4'), findsOneWidget);
    expect(find.text('Ages 5-6'), findsOneWidget);
  });

  testWidgets('Onboarding shows both age choices', (WidgetTester tester) async {
    // Test the screen directly: no splash gate, no platform channels,
    // no pumpAndSettle (Buddy/FloatingStars repeat forever and would
    // never settle). Fully deterministic.
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
