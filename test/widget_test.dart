import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_buddies/main.dart';
import 'package:math_buddies/ui/onboarding.dart';
import 'package:math_buddies/ui/widgets/game_widgets.dart';

void main() {
  testWidgets('App builds and shows the splash', (WidgetTester tester) async {
    await tester.pumpWidget(const MathBuddiesApp());
    // First frame only: the splash is synchronous and needs no channels.
    await tester.pump();
    expect(find.text('Math Buddies'), findsWidgets);
    expect(find.text('🚀'), findsOneWidget);
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
