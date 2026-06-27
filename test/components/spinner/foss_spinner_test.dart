import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Center(child: child),
  ),
);

CustomPainter _painterOf(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(FossSpinner),
      matching: find.byType(CustomPaint),
    ),
  );
  final painter = paint.painter;
  if (painter == null) fail('spinner has no painter');
  return painter;
}

void main() {
  testWidgets('rotates while animating', (tester) async {
    await tester.pumpWidget(_host(const FossSpinner()));
    expect(
      find.descendant(
        of: find.byType(FossSpinner),
        matching: find.byType(RotationTransition),
      ),
      findsOneWidget,
    );
    await tester.pump(const Duration(milliseconds: 16)); // animation runs
  });

  testWidgets('sizes to the given dimension', (tester) async {
    await tester.pumpWidget(_host(const FossSpinner(size: 40)));
    final box = tester.widget<SizedBox>(
      find
          .descendant(
            of: find.byType(FossSpinner),
            matching: find.byType(SizedBox),
          )
          .first,
    );
    expect(box.width, 40);
    expect(box.height, 40);
  });

  testWidgets('uses the explicit color', (tester) async {
    const pink = Color(0xFFFF00FF);
    await tester.pumpWidget(_host(const FossSpinner(color: pink)));
    expect((_painterOf(tester) as dynamic).color, pink);
  });

  testWidgets('defaults to the foreground token', (tester) async {
    await tester.pumpWidget(_host(const FossSpinner()));
    expect(
      (_painterOf(tester) as dynamic).color,
      FossThemeData.light.colors.foreground,
    );
  });

  testWidgets('reduced motion renders a static arc', (tester) async {
    await tester.pumpWidget(_host(const FossSpinner(), reduceMotion: true));
    expect(
      find.descendant(
        of: find.byType(FossSpinner),
        matching: find.byType(RotationTransition),
      ),
      findsNothing,
    );
  });

  testWidgets('announces a default loading label', (tester) async {
    await tester.pumpWidget(_host(const FossSpinner()));
    expect(find.bySemanticsLabel('Loading'), findsOneWidget);
  });

  testWidgets('honors a custom semantic label', (tester) async {
    await tester.pumpWidget(
      _host(const FossSpinner(semanticLabel: 'Fetching')),
    );
    expect(find.bySemanticsLabel('Fetching'), findsOneWidget);
  });
}
