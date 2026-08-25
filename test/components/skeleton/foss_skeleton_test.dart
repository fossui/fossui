import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Center(child: child),
  ),
);

/// The base fill sits in the one [ShapeDecoration] under the skeleton (the
/// shimmer overlay, when present, uses a [BoxDecoration]).
ShapeDecoration _baseDecoration(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(FossSkeleton),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((d) => d.decoration)
    .whereType<ShapeDecoration>()
    .single;

SizedBox _outerBox(WidgetTester tester) => tester.widget<SizedBox>(
  find
      .descendant(
        of: find.byType(FossSkeleton),
        matching: find.byType(SizedBox),
      )
      .first,
);

void main() {
  testWidgets('box sizes to width and height', (tester) async {
    await tester.pumpWidget(_host(const FossSkeleton(width: 120, height: 16)));
    final box = _outerBox(tester);
    expect(box.width, 120);
    expect(box.height, 16);
  });

  testWidgets('circle sizes to a square and clips as a circle', (tester) async {
    await tester.pumpWidget(_host(const FossSkeleton.circle(size: 40)));
    final box = _outerBox(tester);
    expect(box.width, 40);
    expect(box.height, 40);
    expect(_baseDecoration(tester).shape, isA<CircleBorder>());
  });

  testWidgets('fills with the muted token', (tester) async {
    await tester.pumpWidget(_host(const FossSkeleton(width: 80, height: 12)));
    expect(_baseDecoration(tester).color, FossThemeData.light.colors.muted);
  });

  testWidgets('box corners are a superellipse at the sm radius', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const FossSkeleton(width: 80, height: 12)));
    final shape = _baseDecoration(tester).shape;
    expect(shape, isA<RoundedSuperellipseBorder>());
    expect(
      (shape as RoundedSuperellipseBorder).borderRadius,
      BorderRadius.circular(FossThemeData.light.radii.sm),
    );
  });

  testWidgets('shimmers while animating', (tester) async {
    await tester.pumpWidget(_host(const FossSkeleton(width: 80, height: 12)));
    expect(
      find.descendant(
        of: find.byType(FossSkeleton),
        matching: find.byType(Stack),
      ),
      findsOneWidget,
    );
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('reduced motion drops the shimmer and stops the ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const FossSkeleton(width: 80, height: 12), reduceMotion: true),
    );
    expect(
      find.descendant(
        of: find.byType(FossSkeleton),
        matching: find.byType(Stack),
      ),
      findsNothing,
    );
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('shimmer runs on the skeleton motion period', (tester) async {
    expect(FossThemeData.light.motion.skeleton, const Duration(seconds: 2));
    await tester.pumpWidget(_host(const FossSkeleton(width: 80, height: 12)));
    // Still animating well before one 2s cycle elapses.
    await tester.pump(const Duration(seconds: 1));
    expect(tester.hasRunningAnimations, isTrue);
  });

  testWidgets('constructs from runtime dimensions', (tester) async {
    // Non-const args so the constructors run at runtime rather than folding.
    // ignore: prefer_const_declarations
    final w = 64.0;
    await tester.pumpWidget(_host(FossSkeleton(width: w, height: w)));
    expect(_outerBox(tester).width, w);

    await tester.pumpWidget(_host(FossSkeleton.circle(size: w)));
    expect(_baseDecoration(tester).shape, isA<CircleBorder>());
  });

  testWidgets('turning reduced motion off restarts the shimmer', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const FossSkeleton(width: 80, height: 12), reduceMotion: true),
    );
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(
      _host(const FossSkeleton(width: 80, height: 12)),
    );
    await tester.pump();

    expect(tester.hasRunningAnimations, isTrue);
    expect(
      find.descendant(
        of: find.byType(FossSkeleton),
        matching: find.byType(Stack),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a null dimension defers to the parent', (tester) async {
    await tester.pumpWidget(
      _host(
        const SizedBox(
          width: 120,
          height: 30,
          child: FossSkeleton(height: 12),
        ),
      ),
    );

    expect(_outerBox(tester).width, isNull);
    expect(_outerBox(tester).height, 12);
    expect(tester.getSize(find.byType(FossSkeleton)).width, 120);
  });
}
