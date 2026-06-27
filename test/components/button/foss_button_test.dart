import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

import 'host.dart';

ShapeDecoration _decoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
        as ShapeDecoration;

double _radius(WidgetTester tester) =>
    (_decoration(tester).shape as RoundedSuperellipseBorder).borderRadius
        .resolve(TextDirection.ltr)
        .topLeft
        .x;

void main() {
  group('FossButton interaction', () {
    testWidgets('fires onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(FossButton(onPressed: () => taps++, child: const Text('Go'))),
      );

      await tester.tap(find.byType(FossButton));

      expect(taps, 1);
    });

    testWidgets('a null onPressed disables the button', (tester) async {
      await tester.pumpWidget(host(const FossButton(child: Text('Go'))));

      await tester.tap(find.byType(FossButton), warnIfMissed: false);

      expect(find.byType(Opacity), findsOneWidget);
    });

    testWidgets('activates on Enter and Space', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(FossButton(onPressed: () => taps++, child: const Text('Go'))),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(taps, 2);
    });
  });

  group('FossButton variants', () {
    testWidgets('primary fills with the primary token', (tester) async {
      await tester.pumpWidget(
        host(FossButton(onPressed: () {}, child: const Text('Go'))),
      );

      expect(_decoration(tester).color, FossColors.light.primary);
    });

    testWidgets('secondary fills with the secondary token', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton(
            onPressed: () {},
            variant: FossButtonVariant.secondary,
            child: const Text('Go'),
          ),
        ),
      );

      expect(_decoration(tester).color, FossColors.light.secondary);
    });

    testWidgets('ghost is transparent at rest', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton(
            onPressed: () {},
            variant: FossButtonVariant.ghost,
            child: const Text('Go'),
          ),
        ),
      );

      expect(_decoration(tester).color, const Color(0x00000000));
    });
  });

  group('FossButton sizing', () {
    testWidgets('md sets a 36px minimum content height', (tester) async {
      await tester.pumpWidget(
        host(FossButton(onPressed: () {}, child: const Text('Go'))),
      );

      final box = tester.widget<ConstrainedBox>(
        find
            .descendant(
              of: find.byType(DecoratedBox),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );

      expect(box.constraints.minHeight, 36);
    });

    testWidgets('leading icon is themed to 18px', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton(
            onPressed: () {},
            leading: const Icon(IconData(0x44)),
            child: const Text('Go'),
          ),
        ),
      );

      final iconTheme = tester.widget<IconTheme>(
        find
            .descendant(
              of: find.byType(FossButton),
              matching: find.byType(IconTheme),
            )
            .first,
      );

      expect(iconTheme.data.size, 18);
    });
  });

  group('FossButton responsive', () {
    testWidgets('keeps a long label on one line under a width clamp', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const SizedBox(
            width: 120,
            child: FossButton(
              child: Text('A very very very long button label that overflows'),
            ),
          ),
        ),
      );

      // No RenderFlex overflow is thrown, and the button honors the clamp.
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FossButton)).width,
        lessThanOrEqualTo(120),
      );

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.overflow ?? TextOverflow.ellipsis, TextOverflow.ellipsis);
    });

    testWidgets('grows taller with text scale', (tester) async {
      // Measure the visual surface, not the button: the 48px tap-target floor
      // masks growth on the outer box until the content passes 48.
      await tester.pumpWidget(
        host(FossButton(onPressed: () {}, child: const Text('Go'))),
      );
      final base = tester.getSize(find.byType(DecoratedBox)).height;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Center(
              child: FossButton(onPressed: () {}, child: const Text('Go')),
            ),
          ),
        ),
      );
      final scaled = tester.getSize(find.byType(DecoratedBox)).height;

      expect(scaled, greaterThan(base));
      expect(tester.takeException(), isNull);
    });

    testWidgets('lays the leading slot at the start in RTL', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Center(
              child: FossButton(
                onPressed: () {},
                leading: const Icon(IconData(0x44)),
                child: const Text('Go'),
              ),
            ),
          ),
        ),
      );

      // Start is the right edge in RTL, so leading sits past the label.
      final iconX = tester.getCenter(find.byType(Icon)).dx;
      final labelX = tester.getCenter(find.text('Go')).dx;
      expect(iconX, greaterThan(labelX));
    });
  });

  group('FossButton loading', () {
    testWidgets('shows a spinner and is non-interactive', (tester) async {
      await tester.pumpWidget(
        host(const FossButton(loading: true, child: Text('Save'))),
      );
      // The spinner animates forever, so settle a single frame only.
      await tester.pump();

      expect(find.byType(CustomPaint), findsWidgets);
      // Label hidden behind the spinner, plus the disabled dim.
      expect(find.byType(Opacity), findsWidgets);

      // Non-interactive: tapping must not throw and the button is disabled.
      await tester.tap(find.byType(FossButton), warnIfMissed: false);
      expect(
        tester.widget<FossButton>(find.byType(FossButton)).enabled,
        isFalse,
      );
    });

    testWidgets('uses a custom indicator when provided', (tester) async {
      await tester.pumpWidget(
        host(
          const FossButton(
            loading: true,
            loadingIndicator: Icon(Icons.refresh),
            child: Text('Save'),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });
  });

  group('FossButton accessibility', () {
    testWidgets('exposes a button role and enabled state', (tester) async {
      await tester.pumpWidget(
        host(FossButton(onPressed: () {}, child: const Text('Go'))),
      );

      expect(
        tester.getSemantics(find.byType(FossButton)),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          label: 'Go',
        ),
      );
    });

    testWidgets('uses semanticLabel when given', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton(
            onPressed: () {},
            semanticLabel: 'Confirm',
            leading: const Icon(IconData(0x44)),
            child: const SizedBox.shrink(),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Confirm'), findsOneWidget);
    });

    testWidgets('meets tap target and labeled-target guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(FossButton(onPressed: () {}, child: const Text('Continue'))),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    // destructive is excluded by design: it is white-on-`destructive`, which
    // sits near 3.8:1, below the 4.5:1 normal-text bar but matching the
    // reference's solid-danger treatment.
    testWidgets('label meets text contrast on a themed surface', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          ColoredBox(
            color: FossColors.light.background,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final variant in FossButtonVariant.values)
                  if (variant != FossButtonVariant.destructive)
                    FossButton(
                      onPressed: () {},
                      variant: variant,
                      child: const Text('Continue'),
                    ),
              ],
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));

      handle.dispose();
    });
  });

  group('FossButton variants', () {
    testWidgets('destructive fills with the destructive token', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton(
            onPressed: () {},
            variant: FossButtonVariant.destructive,
            child: const Text('Go'),
          ),
        ),
      );

      expect(_decoration(tester).color, FossColors.light.destructive);
    });
  });

  group('FossButton sizing', () {
    Future<double> minHeightFor(
      WidgetTester tester,
      FossButtonSize size,
    ) async {
      await tester.pumpWidget(
        host(
          FossButton(onPressed: () {}, size: size, child: const Text('Go')),
        ),
      );
      final box = tester.widget<ConstrainedBox>(
        find
            .descendant(
              of: find.byType(DecoratedBox),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      return box.constraints.minHeight;
    }

    testWidgets('sm and lg set their minimum heights', (tester) async {
      expect(await minHeightFor(tester, FossButtonSize.sm), 32);
      expect(await minHeightFor(tester, FossButtonSize.lg), 40);
    });

    testWidgets('themes a trailing icon to 18px', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton(
            onPressed: () {},
            trailing: const Icon(IconData(0x44)),
            child: const Text('Go'),
          ),
        ),
      );

      final iconTheme = tester.widget<IconTheme>(
        find
            .descendant(
              of: find.byType(FossButton),
              matching: find.byType(IconTheme),
            )
            .first,
      );

      expect(iconTheme.data.size, 18);
    });
  });

  group('FossButton style override', () {
    testWidgets('applies a per-instance style', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton(
            onPressed: () {},
            style: const FossButtonStyle(minHeight: 50, borderRadius: 4),
            child: const Text('Go'),
          ),
        ),
      );

      expect(_radius(tester), 4);
      final box = tester.widget<ConstrainedBox>(
        find
            .descendant(
              of: find.byType(DecoratedBox),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(box.constraints.minHeight, 50);
    });
  });

  group('FossButton link variant', () {
    DefaultTextStyle labelStyle(WidgetTester tester) =>
        tester.widget<DefaultTextStyle>(
          find
              .ancestor(
                of: find.text('Go'),
                matching: find.byType(DefaultTextStyle),
              )
              .first,
        );

    testWidgets('is transparent at rest', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton(
            onPressed: () {},
            variant: FossButtonVariant.link,
            child: const Text('Go'),
          ),
        ),
      );

      expect(_decoration(tester).color, const Color(0x00000000));
      expect(labelStyle(tester).style.decoration, TextDecoration.none);
    });

    testWidgets('underlines the label while pressed', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton(
            onPressed: () {},
            variant: FossButtonVariant.link,
            child: const Text('Go'),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FossButton)),
      );
      await tester.pump();
      expect(labelStyle(tester).style.decoration, TextDecoration.underline);

      await gesture.up();
      await tester.pump();
      expect(labelStyle(tester).style.decoration, TextDecoration.none);
    });
  });

  group('FossButton.icon', () {
    testWidgets('is square at its size', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton.icon(
            onPressed: () {},
            semanticLabel: 'Share',
            icon: const Icon(IconData(0x44)),
          ),
        ),
      );

      final size = tester.getSize(find.byType(DecoratedBox));
      expect(size.width, size.height);
      expect(size.height, 36);
    });

    testWidgets('drops side padding', (tester) async {
      await tester.pumpWidget(
        host(
          FossButton.icon(
            onPressed: () {},
            semanticLabel: 'Share',
            icon: const Icon(IconData(0x44)),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(DecoratedBox),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(padding.padding, EdgeInsets.zero);
    });

    testWidgets('fires onPressed and exposes its label', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          FossButton.icon(
            onPressed: () => taps++,
            semanticLabel: 'Share',
            icon: const Icon(IconData(0x44)),
          ),
        ),
      );

      await tester.tap(find.byType(FossButton));

      expect(taps, 1);
      expect(find.bySemanticsLabel('Share'), findsOneWidget);
    });

    testWidgets('controller loading shows a spinner and blocks taps', (
      tester,
    ) async {
      final controller = FossButtonController();
      addTearDown(controller.dispose);
      var taps = 0;
      await tester.pumpWidget(
        host(
          FossButton.icon(
            controller: controller,
            onPressed: () => taps++,
            semanticLabel: 'Add',
            icon: const Icon(IconData(0x44)),
          ),
        ),
      );

      expect(find.byType(FossSpinner), findsNothing);

      controller.loading();
      await tester.pump();

      expect(find.byType(FossSpinner), findsOneWidget);
      await tester.tap(find.byType(FossButton), warnIfMissed: false);
      expect(taps, 0);
      expect(
        tester.widget<FossButton>(find.byType(FossButton)).enabled,
        isFalse,
      );
    });
  });

  group('FossButton interaction', () {
    testWidgets('swapping the controller resyncs disabled', (tester) async {
      final enabled = FossButtonController();
      final off = FossButtonController(FossButtonStatus.disabled);
      addTearDown(enabled.dispose);
      addTearDown(off.dispose);

      Widget withController(FossButtonController c) => host(
        FossButton(controller: c, onPressed: () {}, child: const Text('Go')),
      );

      await tester.pumpWidget(withController(enabled));
      expect(
        tester.widget<FossButton>(find.byType(FossButton)).enabled,
        isTrue,
      );

      await tester.pumpWidget(withController(off));
      expect(
        tester.widget<FossButton>(find.byType(FossButton)).enabled,
        isFalse,
      );
    });

    testWidgets('hovering while focused repaints the focus ring', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossButton(onPressed: () {}, child: const Text('Go'))),
      );

      // Keyboard focus shows the ring; a following hover rebuilds it, which
      // exercises the painter's repaint check.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(FossButton)));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('clears the pressed state when the tap is cancelled', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossButton(onPressed: () {}, child: const Text('Go'))),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FossButton)),
      );
      await tester.pump();
      await gesture.moveTo(const Offset(500, 500));
      await gesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
