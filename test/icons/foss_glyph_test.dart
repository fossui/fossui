import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/src/icons/foss_glyph.dart';

const Color _a = Color(0xFF112233);
const Color _b = Color(0xFF445566);

const List<FossGlyph> _glyphs = [
  CheckGlyph(_a),
  CloseGlyph(_a),
  ChevronUpDownGlyph(_a),
  MinusGlyph(_a),
  InfoGlyph(_a),
  SuccessGlyph(_a),
  WarningGlyph(_a),
  ErrorGlyph(_a),
];

Finder _painterOf(FossGlyph glyph) => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter.runtimeType == glyph.runtimeType,
);

void main() {
  group('FossGlyphIcon', () {
    testWidgets('every glyph paints without error', (tester) async {
      for (final glyph in _glyphs) {
        await tester.pumpWidget(
          Center(child: FossGlyphIcon(glyph, size: 16)),
        );
        expect(_painterOf(glyph), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('a decorative glyph is excluded from semantics', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Center(child: FossGlyphIcon(CheckGlyph(_a), size: 16)),
      );
      expect(
        find.descendant(
          of: find.byType(FossGlyphIcon),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a labeled glyph exposes its label to assistive tech', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: FossGlyphIcon(
              InfoGlyph(_a),
              size: 16,
              semanticLabel: 'info',
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('info'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('size sets the paint extent; null fills the parent', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Center(child: FossGlyphIcon(CheckGlyph(_a), size: 20)),
      );
      final sized = tester.widget<CustomPaint>(
        _painterOf(const CheckGlyph(_a)),
      );
      expect(sized.size, const Size.square(20));

      await tester.pumpWidget(
        Center(
          child: SizedBox.square(
            dimension: 12,
            child: FossGlyphIcon(const CheckGlyph(_a)),
          ),
        ),
      );
      final filled = tester.getSize(_painterOf(const CheckGlyph(_a)));
      expect(filled, const Size.square(12));
    });
  });

  group('FossGlyph.shouldRepaint', () {
    test('repaints only when the color changes', () {
      expect(const CheckGlyph(_a).shouldRepaint(const CheckGlyph(_a)), isFalse);
      expect(const CheckGlyph(_a).shouldRepaint(const CheckGlyph(_b)), isTrue);
    });
  });
}
