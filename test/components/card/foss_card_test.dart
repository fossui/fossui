import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

void main() {
  Widget host(
    Widget child, {
    FossThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
  }) => FossTheme(
    data: theme ?? FossThemeData.light,
    child: Directionality(
      textDirection: direction,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 320, child: child),
        ),
      ),
    ),
  );

  // The Padding that immediately wraps the slot whose child is [text].
  EdgeInsets slotPadding(WidgetTester tester, String text) {
    final padding = tester.widget<Padding>(
      find.ancestor(of: find.text(text), matching: find.byType(Padding)).first,
    );
    return padding.padding as EdgeInsets;
  }

  group('FossCardStyle.merge', () {
    test('lays every non-null field of other over this', () {
      const base = FossCardStyle(
        borderRadius: 8,
        borderColor: Color(0xFF111111),
      );
      const over = FossCardStyle(borderRadius: 16);

      final merged = base.merge(over);

      expect(merged.borderRadius, 16);
      expect(merged.borderColor, const Color(0xFF111111));
    });

    test('returns this unchanged when other is null', () {
      const base = FossCardStyle(borderRadius: 12);
      expect(base.merge(null), same(base));
    });
  });

  testWidgets('renders every slot', (tester) async {
    await tester.pumpWidget(
      host(
        const FossCard(
          title: Text('Project'),
          description: Text('Manage settings.'),
          action: Text('Add'),
          content: Text('body'),
          footer: Text('footer'),
        ),
      ),
    );

    for (final t in ['Project', 'Manage settings.', 'Add', 'body', 'footer']) {
      expect(find.text(t), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a card with only content is valid', (tester) async {
    await tester.pumpWidget(host(const FossCard(content: Text('body'))));

    expect(find.text('body'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('lone content keeps the full inset on every side', (
    tester,
  ) async {
    await tester.pumpWidget(host(const FossCard(content: Text('body'))));

    expect(slotPadding(tester, 'body'), const EdgeInsets.all(24));
  });

  testWidgets('the seam between stacked slots collapses', (tester) async {
    await tester.pumpWidget(
      host(
        const FossCard(
          title: Text('Project'),
          content: Text('body'),
          footer: Text('footer'),
        ),
      ),
    );

    // Header bottom tightens to 16 above content; content drops both touching
    // edges to 0; footer top tightens to 16 below content.
    expect(
      slotPadding(tester, 'Project'),
      const EdgeInsets.fromLTRB(24, 24, 24, 16),
    );
    expect(
      slotPadding(tester, 'body'),
      const EdgeInsets.fromLTRB(24, 0, 24, 0),
    );
    expect(
      slotPadding(tester, 'footer'),
      const EdgeInsets.fromLTRB(24, 16, 24, 24),
    );
  });

  testWidgets('the action pins trailing and mirrors in RTL', (tester) async {
    Future<void> pump(TextDirection direction) => tester.pumpWidget(
      host(
        const FossCard(title: Text('Project'), action: Text('Add')),
        direction: direction,
      ),
    );

    await pump(TextDirection.ltr);
    expect(
      tester.getCenter(find.text('Add')).dx,
      greaterThan(tester.getCenter(find.text('Project')).dx),
    );

    await pump(TextDirection.rtl);
    expect(
      tester.getCenter(find.text('Add')).dx,
      lessThan(tester.getCenter(find.text('Project')).dx),
    );
  });

  testWidgets('dark surface builds', (tester) async {
    await tester.pumpWidget(
      host(
        const FossCard(title: Text('Project'), content: Text('body')),
        theme: FossThemeData.dark,
      ),
    );

    expect(find.text('Project'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grows with text at 2x scale without overflow', (tester) async {
    await tester.pumpWidget(
      host(
        const FossCard(
          title: Text('Project'),
          description: Text('Manage your settings and configuration.'),
          content: Text('body'),
        ),
        textScale: 2,
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
