import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui/src/icons/foss_glyph.dart';

import 'host.dart';

const _previous = 'Go to previous page';
const _next = 'Go to next page';

/// The control carrying [label], which is how every button in the row is named.
Finder _control(String label) =>
    find.byWidgetPredicate((w) => w is FossButton && w.semanticLabel == label);

/// The ellipsis slots, which are inert and carry nothing but a label.
Finder _more([String label = 'More pages']) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.label == label,
);

/// The chevrons in row order: previous first, next last.
List<FossGlyph> _chevrons(WidgetTester tester) => tester
    .widgetList<FossGlyphIcon>(find.byType(FossGlyphIcon))
    .map((w) => w.glyph)
    .toList();

void main() {
  group('rendering', () {
    testWidgets('lists every page when they all fit', (tester) async {
      await tester.pumpWidget(
        host(FossPagination(page: 3, pageCount: 5, onPageChanged: (_) {})),
      );

      for (var i = 1; i <= 5; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
      expect(_more(), findsNothing);
    });

    testWidgets('cuts the run with ellipses past the threshold', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      // 1 ... 4 5 6 ... 10
      for (final page in ['1', '4', '5', '6', '10']) {
        expect(find.text(page), findsOneWidget);
      }
      for (final hidden in ['2', '3', '7', '8', '9']) {
        expect(find.text(hidden), findsNothing);
      }
      expect(_more(), findsNWidgets(2));
    });

    testWidgets('marks the current page with the active variant', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossPagination(page: 4, pageCount: 10, onPageChanged: (_) {})),
      );

      final current = tester.widget<FossButton>(_control('Page 4'));
      final other = tester.widget<FossButton>(_control('Page 5'));
      expect(current.variant, FossButtonVariant.outline);
      expect(other.variant, FossButtonVariant.ghost);
    });

    testWidgets('an ellipsis is as wide as a page button, so the row holds '
        'its size as ellipses come and go', (tester) async {
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      final button = tester.getSize(_control('Page 5')).width;
      final ellipsis = tester.getSize(_more().first);
      expect(ellipsis.width, button);
    });

    testWidgets('a page number does not widen its slot', (tester) async {
      await tester.pumpWidget(
        host(FossPagination(page: 500, pageCount: 999, onPageChanged: (_) {})),
      );

      expect(tester.getSize(_control('Page 500')).width, 48);
    });
  });

  group('interaction', () {
    testWidgets('tapping a page reports it once', (tester) async {
      final reported = <int>[];
      await tester.pumpWidget(
        host(
          FossPagination(page: 5, pageCount: 10, onPageChanged: reported.add),
        ),
      );

      await tester.tap(find.text('6'));
      expect(reported, [6]);
    });

    testWidgets('tapping the current page reports nothing', (tester) async {
      final reported = <int>[];
      await tester.pumpWidget(
        host(
          FossPagination(page: 5, pageCount: 10, onPageChanged: reported.add),
        ),
      );

      await tester.tap(find.text('5'));
      expect(reported, isEmpty);
    });

    testWidgets('previous and next step by one', (tester) async {
      final reported = <int>[];
      await tester.pumpWidget(
        host(
          FossPagination(page: 5, pageCount: 10, onPageChanged: reported.add),
        ),
      );

      await tester.tap(_control(_previous));
      await tester.tap(_control(_next));
      expect(reported, [4, 6]);
    });

    testWidgets('previous is disabled on the first page', (tester) async {
      final reported = <int>[];
      await tester.pumpWidget(
        host(
          FossPagination(page: 1, pageCount: 10, onPageChanged: reported.add),
        ),
      );

      expect(tester.widget<FossButton>(_control(_previous)).enabled, isFalse);
      expect(tester.widget<FossButton>(_control(_next)).enabled, isTrue);
      await tester.tap(_control(_previous));
      expect(reported, isEmpty);
    });

    testWidgets('next is disabled on the last page', (tester) async {
      final reported = <int>[];
      await tester.pumpWidget(
        host(
          FossPagination(page: 10, pageCount: 10, onPageChanged: reported.add),
        ),
      );

      expect(tester.widget<FossButton>(_control(_next)).enabled, isFalse);
      expect(tester.widget<FossButton>(_control(_previous)).enabled, isTrue);
      await tester.tap(_control(_next));
      expect(reported, isEmpty);
    });

    testWidgets('a single page disables both steps', (tester) async {
      await tester.pumpWidget(
        host(FossPagination(page: 1, pageCount: 1, onPageChanged: (_) {})),
      );

      expect(tester.widget<FossButton>(_control(_previous)).enabled, isFalse);
      expect(tester.widget<FossButton>(_control(_next)).enabled, isFalse);
    });

    testWidgets('a null callback makes the whole row inert', (tester) async {
      await tester.pumpWidget(
        host(
          const FossPagination(page: 5, pageCount: 10, onPageChanged: null),
        ),
      );

      for (final button in tester.widgetList<FossButton>(
        find.byType(FossButton),
      )) {
        expect(button.enabled, isFalse);
      }
    });

    testWidgets('the ellipsis is not a button', (tester) async {
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      // Seven slots plus the two steps, with two of the slots ellipses.
      expect(find.byType(FossButton), findsNWidgets(7));
    });
  });

  group('width', () {
    testWidgets('drops the sibling run when the row cannot fit it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {}),
          width: 360,
        ),
      );

      // 1 ... 5 ... 10, the widest row a small phone holds.
      expect(find.text('5'), findsOneWidget);
      expect(find.text('4'), findsNothing);
      expect(find.text('6'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the requested run when the width allows it', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {}),
        ),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('never shows more than the requested run', (tester) async {
      await tester.pumpWidget(
        host(
          FossPagination(
            page: 10,
            pageCount: 40,
            siblingCount: 0,
            onPageChanged: (_) {},
          ),
          width: 2000,
        ),
      );

      expect(find.text('10'), findsOneWidget);
      expect(find.text('9'), findsNothing);
    });

    testWidgets('takes the request as-is under an unbounded width', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FossTheme(
            data: FossThemeData.light,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: FossPagination(
                page: 5,
                pageCount: 10,
                onPageChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives a 2.0 text scale', (tester) async {
      await tester.pumpWidget(
        host(
          FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {}),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('5'), findsOneWidget);
    });
  });

  group('accessibility', () {
    testWidgets('names the row and every control', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      expect(find.bySemanticsLabel('Pagination'), findsOneWidget);
      expect(find.bySemanticsLabel('Page 5'), findsOneWidget);
      expect(find.bySemanticsLabel(_previous), findsOneWidget);
      expect(find.bySemanticsLabel(_next), findsOneWidget);
      expect(find.bySemanticsLabel('More pages'), findsNWidgets(2));
      handle.dispose();
    });

    testWidgets('takes overridden labels', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossPagination(
            page: 5,
            pageCount: 10,
            onPageChanged: (_) {},
            label: 'Results',
            pageLabel: (n) => 'Result page $n',
            previousLabel: 'Back',
            nextLabel: 'Forward',
            moreLabel: 'Skipped',
          ),
        ),
      );

      expect(find.bySemanticsLabel('Results'), findsOneWidget);
      expect(find.bySemanticsLabel('Result page 5'), findsOneWidget);
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.bySemanticsLabel('Forward'), findsOneWidget);
      expect(find.bySemanticsLabel('Skipped'), findsNWidgets(2));
      handle.dispose();
    });

    testWidgets('reports the current page as selected', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Page 5')),
        matchesSemantics(
          label: 'Page 5',
          isButton: true,
          isFocusable: true,
          hasSelectedState: true,
          isSelected: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Page 6')),
        matchesSemantics(
          label: 'Page 6',
          isButton: true,
          isFocusable: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('the ellipsis announces only its label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('More pages').first),
        matchesSemantics(label: 'More pages'),
      );
      handle.dispose();
    });

    testWidgets('meets the tap target guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

  group('direction', () {
    testWidgets('previous points against the reading direction', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      final glyphs = _chevrons(tester);
      expect(glyphs.first, isA<ChevronLeftGlyph>());
      expect(glyphs.last, isA<ChevronRightGlyph>());
    });

    testWidgets('the chevrons swap under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {}),
          direction: TextDirection.rtl,
        ),
      );

      final glyphs = _chevrons(tester);
      expect(glyphs.first, isA<ChevronRightGlyph>());
      expect(glyphs.last, isA<ChevronLeftGlyph>());
    });

    testWidgets('the row order reverses under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {}),
          direction: TextDirection.rtl,
        ),
      );

      final previous = tester.getCenter(_control(_previous));
      final next = tester.getCenter(_control(_next));
      expect(previous.dx, greaterThan(next.dx));
    });
  });

  group('slot alignment', () {
    testWidgets('a page number sits centred in its button', (tester) async {
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      final number = tester.getCenter(find.text('5'));
      final button = tester.getCenter(_control('Page 5'));
      expect(number.dx, moreOrLessEquals(button.dx, epsilon: 0.5));
      expect(number.dy, moreOrLessEquals(button.dy, epsilon: 0.5));
    });

    testWidgets('the page number takes the button foreground, so a filled '
        'active variant stays legible', (tester) async {
      const theme = FossThemeData.dark;
      await tester.pumpWidget(
        host(
          FossPagination(
            page: 5,
            pageCount: 10,
            onPageChanged: (_) {},
            style: const FossPaginationStyle(
              activeVariant: FossButtonVariant.primary,
            ),
          ),
          theme: theme,
        ),
      );

      // The filled variant flips its foreground; a number painted in the plain
      // foreground role would be white on white.
      final number = tester.widget<Text>(find.text('5'));
      final color = number.style?.color;
      final expected = theme.colors.primaryForeground;
      expect(color, isNotNull);
      expect(color?.r, isNot(theme.colors.foreground.r));
      expect(color?.r, expected.r);
      expect(color?.g, expected.g);
      expect(color?.b, expected.b);
    });

    testWidgets('a chevron keeps the button icon size', (tester) async {
      await tester.pumpWidget(
        host(FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {})),
      );

      final chevron = find.descendant(
        of: _control(_previous),
        matching: find.byType(FossGlyphIcon),
      );
      expect(tester.getSize(chevron), const Size(18, 18));
    });
  });

  testWidgets('renders in dark', (tester) async {
    await tester.pumpWidget(
      host(
        FossPagination(page: 5, pageCount: 10, onPageChanged: (_) {}),
        theme: FossThemeData.dark,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('5'), findsOneWidget);
  });
}
