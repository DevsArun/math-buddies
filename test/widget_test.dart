import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_buddies/main.dart';
import 'package:math_buddies/ui/widgets/game_widgets.dart';

void main() {
  testWidgets('App boots to onboarding with age choices',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MathBuddiesApp());
    await tester.pumpAndSettle();
    expect(find.text('Math Buddies'), findsWidgets);
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
