import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';
import 'package:fossui/src/icons/foss_glyph.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

Finder _glyph<T extends FossGlyph>() => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is T,
);

void main() {
  group('checkbox default glyph', () {
    testWidgets('checked paints the shared check', (tester) async {
      await tester.pumpWidget(_host(const FossCheckbox(value: true)));
      expect(_glyph<CheckGlyph>(), findsOneWidget);
      expect(_glyph<MinusGlyph>(), findsNothing);
    });

    testWidgets('indeterminate paints the shared minus', (tester) async {
      await tester.pumpWidget(_host(const FossCheckbox(value: null)));
      expect(_glyph<MinusGlyph>(), findsOneWidget);
      expect(_glyph<CheckGlyph>(), findsNothing);
    });

    testWidgets('unchecked paints no glyph', (tester) async {
      await tester.pumpWidget(_host(const FossCheckbox()));
      expect(_glyph<CheckGlyph>(), findsNothing);
      expect(_glyph<MinusGlyph>(), findsNothing);
    });
  });

  group('alert default status glyph', () {
    testWidgets('each variant paints its status glyph', (tester) async {
      Future<void> pumpVariant(FossAlertVariant variant) => tester.pumpWidget(
        _host(FossAlert(variant: variant, title: const Text('Heads up'))),
      );

      await pumpVariant(FossAlertVariant.info);
      expect(_glyph<InfoGlyph>(), findsOneWidget);

      await pumpVariant(FossAlertVariant.success);
      expect(_glyph<SuccessGlyph>(), findsOneWidget);

      await pumpVariant(FossAlertVariant.warning);
      expect(_glyph<WarningGlyph>(), findsOneWidget);

      await pumpVariant(FossAlertVariant.error);
      expect(_glyph<ErrorGlyph>(), findsOneWidget);
    });

    testWidgets('the neutral variant paints no status glyph', (tester) async {
      await tester.pumpWidget(
        _host(const FossAlert(title: Text('Heads up'))),
      );
      expect(_glyph<FossGlyph>(), findsNothing);
    });

    testWidgets('a status glyph carries its label', (tester) async {
      await tester.pumpWidget(
        _host(
          const FossAlert(variant: FossAlertVariant.error, title: Text('Oops')),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is FossGlyphIcon && w.semanticLabel == 'error',
        ),
        findsOneWidget,
      );
    });
  });
}
