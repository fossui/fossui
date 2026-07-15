import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

Finder _boxFinder = find.descendant(
  of: find.byType(FossTextField),
  matching: find.byType(DecoratedBox),
);

ShapeDecoration _decoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_boxFinder).decoration as ShapeDecoration;

Color _borderColor(WidgetTester tester) =>
    (_decoration(tester).shape as RoundedSuperellipseBorder).side.color;

void main() {
  group('FossTextField input', () {
    testWidgets('reports text through onChanged', (tester) async {
      var value = '';
      await tester.pumpWidget(
        host(FossTextField(onChanged: (v) => value = v)),
      );

      await tester.enterText(find.byType(EditableText), 'hello');

      expect(value, 'hello');
    });

    testWidgets('reports submission through onSubmitted', (tester) async {
      String? submitted;
      await tester.pumpWidget(
        host(FossTextField(onSubmitted: (v) => submitted = v)),
      );

      await tester.enterText(find.byType(EditableText), 'done');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(submitted, 'done');
    });

    testWidgets('uses a supplied controller', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(FossTextField(controller: controller)));

      await tester.enterText(find.byType(EditableText), 'abc');

      expect(controller.text, 'abc');
    });
  });

  group('FossTextField placeholder', () {
    testWidgets('shows the hint while empty and hides it once filled', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossTextField(hintText: 'Email')));

      expect(find.text('Email'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pump();

      expect(find.text('Email'), findsNothing);
    });
  });

  group('FossTextField captions', () {
    testWidgets('renders helper text', (tester) async {
      await tester.pumpWidget(
        host(const FossTextField(helperText: 'Required')),
      );

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('error text replaces the helper', (tester) async {
      await tester.pumpWidget(
        host(
          const FossTextField(helperText: 'Required', errorText: 'Too short'),
        ),
      );

      expect(find.text('Too short'), findsOneWidget);
      expect(find.text('Required'), findsNothing);
    });
  });

  group('FossTextField states', () {
    testWidgets('resting border uses the input token', (tester) async {
      await tester.pumpWidget(host(const FossTextField()));

      expect(_borderColor(tester), FossColors.light.input);
    });

    testWidgets('focus switches the border to the ring token', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(host(FossTextField(focusNode: focusNode)));

      focusNode.requestFocus();
      await tester.pump();

      expect(_borderColor(tester), FossColors.light.ring);
    });

    testWidgets('error tints the border with destructive', (tester) async {
      await tester.pumpWidget(host(const FossTextField(errorText: 'Bad')));

      expect(
        _borderColor(tester),
        FossColors.light.destructive.withValues(alpha: 0.36),
      );
    });

    testWidgets('disabled dims and does not focus on tap', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        host(FossTextField(enabled: false, focusNode: focusNode)),
      );

      await tester.tap(find.byType(FossTextField), warnIfMissed: false);
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
      expect(
        find.descendant(
          of: find.byType(FossTextField),
          matching: find.byType(Opacity),
        ),
        findsOneWidget,
      );
    });
  });

  group('FossTextField sizes', () {
    Future<double> heightFor(
      WidgetTester tester,
      FossTextFieldSize size,
    ) async {
      await tester.pumpWidget(host(FossTextField(size: size)));
      return tester.getSize(_boxFinder).height;
    }

    testWidgets('each size sets its box min-height', (tester) async {
      expect(await heightFor(tester, FossTextFieldSize.sm), 30);
      expect(await heightFor(tester, FossTextFieldSize.md), 34);
      expect(await heightFor(tester, FossTextFieldSize.lg), 38);
    });
  });

  group('FossTextField affixes', () {
    testWidgets('renders leading and trailing widgets', (tester) async {
      await tester.pumpWidget(
        host(
          const FossTextField(
            leading: Icon(IconData(0x1)),
            trailing: Icon(IconData(0x2)),
          ),
        ),
      );

      expect(find.byType(Icon), findsNWidgets(2));
    });
  });

  group('FossTextField accessibility', () {
    testWidgets('exposes a text field with its label', (tester) async {
      await tester.pumpWidget(host(const FossTextField(label: 'Email')));

      expect(find.bySemanticsLabel('Email'), findsWidgets);
    });

    testWidgets('meets the tap-target guideline', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const FossTextField()));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('label and value meet the contrast guideline', (tester) async {
      final controller = TextEditingController(text: 'Jane Doe');
      addTearDown(controller.dispose);
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(FossTextField(label: 'Name', controller: controller)),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });
  });

  group('FossTextField responsive', () {
    testWidgets('box grows with the text scale', (tester) async {
      final controller = TextEditingController(text: 'Ag');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: FossTextField(controller: controller)),
          ),
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );

      // The md box is 34 tall at 1x; doubled text pushes it past that.
      expect(tester.getSize(_boxFinder).height, greaterThan(34));
    });

    testWidgets('lays the leading slot at the start under RTL', (tester) async {
      await tester.pumpWidget(
        host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: FossTextField(
              leading: Icon(IconData(0x1)),
              trailing: Icon(IconData(0x2)),
            ),
          ),
        ),
      );

      final leading = tester.getCenter(find.byIcon(const IconData(0x1)));
      final trailing = tester.getCenter(find.byIcon(const IconData(0x2)));
      // Start is on the right in RTL, so leading sits to the right of trailing.
      expect(leading.dx, greaterThan(trailing.dx));
    });
  });

  group('FossTextField lifecycle', () {
    testWidgets('dropping an external controller keeps its text', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'kept');
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(FossTextField(controller: controller)));
      expect(find.text('kept'), findsOneWidget);

      // Same position, controller removed: the field creates an internal one
      // seeded with the outgoing text.
      await tester.pumpWidget(host(const FossTextField()));

      expect(find.text('kept'), findsOneWidget);
    });

    testWidgets('swapping the focus node keeps focus tracking', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(FossTextField(focusNode: node)));

      // Remove the external node; the field falls back to an internal one and
      // must rewire the focus listener to it. Entering text focuses that node,
      // which should flip the border to the ring token.
      await tester.pumpWidget(host(const FossTextField()));
      await tester.enterText(find.byType(EditableText), 'x');
      await tester.pump();

      expect(_borderColor(tester), FossColors.light.ring);
    });
  });

  group('FossTextField style', () {
    testWidgets('a per-instance style overrides the resolved visuals', (
      tester,
    ) async {
      const shadow = [BoxShadow(color: Color(0x22000000), blurRadius: 2)];
      await tester.pumpWidget(
        host(
          const FossTextField(
            label: 'L',
            helperText: 'H',
            style: FossTextFieldStyle(
              backgroundColor: Color(0xFF102030),
              borderColor: Color(0xFF405060),
              borderRadius: 4,
              contentPadding: EdgeInsets.all(2),
              minHeight: 40,
              textStyle: TextStyle(fontSize: 20),
              labelStyle: TextStyle(fontSize: 14),
              helperStyle: TextStyle(fontSize: 10),
              iconSize: 12,
              gap: 3,
              shadow: shadow,
            ),
          ),
        ),
      );

      expect(_borderColor(tester), const Color(0xFF405060));
      expect(_decoration(tester).color, const Color(0xFF102030));
      expect(_decoration(tester).shadows, shadow);
    });
  });

  group('FossTextField gesture', () {
    testWidgets('tapping an enabled field drives the selection detector', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(host(FossTextField(focusNode: focusNode)));

      await tester.tap(find.byType(FossTextField));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
    });
  });

  group('FossTextField adoption', () {
    testWidgets('adopting an external controller uses it', (tester) async {
      await tester.pumpWidget(host(const FossTextField()));

      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(FossTextField(controller: controller)));

      await tester.enterText(find.byType(EditableText), 'typed');

      expect(controller.text, 'typed');
    });

    testWidgets('adopting an external focus node tracks it', (tester) async {
      await tester.pumpWidget(host(const FossTextField()));

      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(FossTextField(focusNode: node)));

      await tester.enterText(find.byType(EditableText), 'x');
      await tester.pump();

      expect(_borderColor(tester), FossColors.light.ring);
    });
  });

  group('FossTextField focused error', () {
    testWidgets('deepens the border and paints the destructive ring', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(FossTextField(errorText: 'Bad', focusNode: node)),
      );

      node.requestFocus();
      await tester.pump();

      expect(
        _borderColor(tester),
        FossColors.light.destructive.withValues(alpha: 0.64),
      );

      // Rebuild while the ring stays up so its painter is diffed against the
      // previous instance.
      await tester.pumpWidget(
        host(FossTextField(errorText: 'Worse', focusNode: node)),
      );
      await tester.pump();

      expect(find.text('Worse'), findsOneWidget);
    });
  });

  group('FossTextField dark', () {
    testWidgets('lifts the fill above the bare surface', (tester) async {
      await tester.pumpWidget(
        host(
          const FossTheme(data: FossThemeData.dark, child: FossTextField()),
        ),
      );

      expect(_decoration(tester).color, isNot(FossColors.dark.background));
    });
  });

  group('FossTextField shadow', () {
    testWidgets('rests with a shadow, drops it on focus', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(FossTextField(focusNode: node)));
      expect(_decoration(tester).shadows, isNotEmpty);

      node.requestFocus();
      await tester.pump();

      expect(_decoration(tester).shadows, isEmpty);
    });

    testWidgets('error drops the resting shadow', (tester) async {
      await tester.pumpWidget(host(const FossTextField(errorText: 'Bad')));

      expect(_decoration(tester).shadows, isEmpty);
    });

    testWidgets('disabled drops the resting shadow', (tester) async {
      await tester.pumpWidget(host(const FossTextField(enabled: false)));

      expect(_decoration(tester).shadows, isEmpty);
    });
  });

  group('FossTextField obscured', () {
    testWidgets('obscureText hides the entered value', (tester) async {
      await tester.pumpWidget(host(const FossTextField(obscureText: true)));

      await tester.enterText(find.byType(EditableText), 'secret');
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.obscureText, isTrue);
      expect(editable.controller.text, 'secret');
    });
  });

  group('FossTextField multiline', () {
    testWidgets('passes minLines and maxLines to the editable', (tester) async {
      await tester.pumpWidget(
        host(const FossTextField(minLines: 3, maxLines: 6)),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.minLines, 3);
      expect(editable.maxLines, 6);
    });

    testWidgets('grows taller than a single-line field', (tester) async {
      await tester.pumpWidget(host(const FossTextField()));
      final single = tester.getSize(_boxFinder).height;

      await tester.pumpWidget(host(const FossTextField(maxLines: null)));
      final multi = tester.getSize(_boxFinder).height;

      expect(multi, greaterThan(single));
    });

    testWidgets('accepts multiple lines of text', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        host(FossTextField(controller: controller, maxLines: null)),
      );

      await tester.enterText(find.byType(EditableText), 'line one\nline two');

      expect(controller.text, 'line one\nline two');
    });

    testWidgets('rejects icon slots on a multiline field', (tester) async {
      expect(
        () => FossTextField(maxLines: null, leading: const SizedBox()),
        throwsAssertionError,
      );
    });

    testWidgets('resting height scales with the text scale', (tester) async {
      await tester.pumpWidget(host(const FossTextField(maxLines: null)));
      final base = tester.getSize(_boxFinder).height;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: const FossTextField(maxLines: null)),
          ),
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.getSize(_boxFinder).height, greaterThan(base));
    });
  });

  group('FossTextField keyboard hygiene', () {
    testWidgets('obscured field disables autocorrect and suggestions', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossTextField(obscureText: true)));

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.autocorrect, isFalse);
      expect(editable.enableSuggestions, isFalse);
    });

    testWidgets('plain field keeps autocorrect and suggestions', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossTextField()));

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.autocorrect, isTrue);
      expect(editable.enableSuggestions, isTrue);
    });

    testWidgets('a dark theme requests a dark keyboard', (tester) async {
      await tester.pumpWidget(
        host(
          const FossTheme(data: FossThemeData.dark, child: FossTextField()),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.keyboardAppearance, Brightness.dark);
    });
  });

  group('FossTextField focus release', () {
    testWidgets('tapping outside releases focus', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        host(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FossTextField(focusNode: node),
              GestureDetector(
                onTap: () {},
                child: const SizedBox(
                  key: Key('sink'),
                  height: 40,
                  width: 200,
                ),
              ),
            ],
          ),
        ),
      );

      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);

      await tester.tap(find.byKey(const Key('sink')));
      await tester.pump();

      expect(node.hasFocus, isFalse);
    });

    testWidgets('disabling a focused field releases focus', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(host(FossTextField(focusNode: node)));

      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);

      await tester.pumpWidget(
        host(FossTextField(focusNode: node, enabled: false)),
      );
      await tester.pump();

      expect(node.hasFocus, isFalse);
    });
  });

  group('FossTextField theming', () {
    testWidgets('affixes are sized to 18 at 80% of the text color', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(const FossTextField(leading: Icon(IconData(0x1)))),
      );

      final iconTheme = tester.widget<IconTheme>(
        find
            .ancestor(
              of: find.byIcon(const IconData(0x1)),
              matching: find.byType(IconTheme),
            )
            .first,
      );
      final fg = FossColors.light.foreground;
      expect(iconTheme.data.size, 18);
      expect(iconTheme.data.color, fg.withValues(alpha: fg.a * 0.8));
    });

    testWidgets('the error caption uses the destructive-foreground color', (
      tester,
    ) async {
      await tester.pumpWidget(host(const FossTextField(errorText: 'Bad')));

      expect(
        tester.widget<Text>(find.text('Bad')).style?.color,
        FossColors.light.destructiveForeground,
      );
    });

    testWidgets('style label and helper sizes reach the rendered text', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossTextField(
            label: 'L',
            helperText: 'H',
            style: FossTextFieldStyle(
              labelStyle: TextStyle(fontSize: 14),
              helperStyle: TextStyle(fontSize: 10),
            ),
          ),
        ),
      );

      expect(tester.widget<Text>(find.text('L')).style?.fontSize, 14);
      expect(tester.widget<Text>(find.text('H')).style?.fontSize, 10);
    });
  });
}
