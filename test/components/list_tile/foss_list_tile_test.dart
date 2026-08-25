import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

Finder _fillFinder() => find.byWidgetPredicate(
  (w) =>
      w is DecoratedBox &&
      w.decoration is ShapeDecoration &&
      (w.decoration as ShapeDecoration).shape is RoundedSuperellipseBorder,
);

ShapeDecoration _fill(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_fillFinder().first).decoration
        as ShapeDecoration;

DefaultTextStyle _lineStyle(WidgetTester tester, String text) =>
    tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(text),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );

/// The start edge of [finder] measured from the row's own start edge, so the
/// assertions read as insets rather than screen coordinates.
double _startInset(WidgetTester tester, Finder finder) {
  final row = tester.getRect(find.byType(FossListTile));
  final box = tester.getRect(finder);
  return _ltr(tester) ? box.left - row.left : row.right - box.right;
}

/// The end edge of [finder] measured back from the row's own end edge.
double _endInset(WidgetTester tester, Finder finder) {
  final row = tester.getRect(find.byType(FossListTile));
  final box = tester.getRect(finder);
  return _ltr(tester) ? row.right - box.right : box.left - row.left;
}

/// The row's focus ring, scoped to the tile so a host's own painters (the
/// debug banner) cannot stand in for it.
CustomPainter? _ringPainter(WidgetTester tester) {
  final painters = tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(FossListTile),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((p) => p.foregroundPainter)
      .whereType<CustomPainter>();
  return painters.isEmpty ? null : painters.first;
}

bool _ltr(WidgetTester tester) =>
    Directionality.of(tester.element(find.byType(FossListTile))) ==
    TextDirection.ltr;

/// Attaches a mouse and puts the focus manager in the pointer-driven mode, so
/// hover highlights surface at all under a synthetic pointer.
Future<TestGesture> _hoverPointer(WidgetTester tester) async {
  FocusManager.instance.highlightStrategy =
      FocusHighlightStrategy.alwaysTraditional;
  addTearDown(
    () => FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.automatic,
  );
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer();
  addTearDown(gesture.removePointer);
  return gesture;
}

void main() {
  final light = FossThemeData.light.colors;
  const transparent = Color(0x00000000);

  group('FossListTile slots', () {
    testWidgets('a title-only row renders just the title', (tester) async {
      await tester.pumpWidget(
        host(const FossListTile(title: Text('Notifications'))),
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('all four slots render together', (tester) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
            subtitle: Text('Push and email'),
            trailing: Icon(Icons.chevron_right),
          ),
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Push and email'), findsOneWidget);
      expect(find.byType(Icon), findsNWidgets(2));
    });

    testWidgets('the leading gap collapses with the slot', (tester) async {
      await tester.pumpWidget(
        host(const FossListTile(title: Text('Notifications'))),
      );
      final bare = _startInset(tester, find.text('Notifications'));

      await tester.pumpWidget(
        host(
          const FossListTile(
            leading: SizedBox.square(dimension: 24),
            title: Text('Notifications'),
          ),
        ),
      );
      final withLeading = _startInset(tester, find.text('Notifications'));

      // Only the padding sits before a bare title; the leading slot adds its
      // own width plus one gap and nothing else.
      expect(bare, 16);
      expect(withLeading, 16 + 24 + 16);
    });

    testWidgets('the leading and trailing slots keep their own size', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            leading: SizedBox.square(dimension: 40, key: Key('avatar')),
            title: Text('Notifications'),
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const Key('avatar'))),
        const Size(40, 40),
      );
    });

    testWidgets('a leading icon inherits the themed size and color', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            leading: Icon(Icons.notifications),
            title: Text('Notifications'),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      final theme = IconTheme.of(
        tester.element(find.byType(Icon)),
      );
      expect(icon.size, isNull);
      expect(theme.size, 18);
      expect(theme.color, light.foreground);
    });
  });

  group('FossListTile metrics', () {
    testWidgets('a one-line row measures the tap floor', (tester) async {
      await tester.pumpWidget(
        host(const FossListTile(title: Text('Notifications'))),
      );

      expect(tester.getSize(find.byType(FossListTile)).height, 48);
    });

    testWidgets('a subtitle grows the row past the floor', (tester) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            title: Text('Notifications'),
            subtitle: Text('Push and email'),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FossListTile)).height, 72);
    });

    testWidgets('a taller slot grows the row', (tester) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            leading: SizedBox.square(dimension: 40),
            title: Text('Notifications'),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FossListTile)).height, 64);
    });

    testWidgets('the title clamps to one line, the subtitle to two', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            title: Text('Notifications'),
            subtitle: Text('Push and email'),
          ),
        ),
      );

      final title = _lineStyle(tester, 'Notifications');
      final subtitle = _lineStyle(tester, 'Push and email');
      expect(title.maxLines, 1);
      expect(title.overflow, TextOverflow.ellipsis);
      expect(subtitle.maxLines, 2);
      expect(subtitle.overflow, TextOverflow.ellipsis);
    });

    testWidgets('a long title yields rather than pushing the trailing slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('A notification title far longer than the row'),
            trailing: const SizedBox.square(dimension: 40, key: Key('end')),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_endInset(tester, find.byKey(const Key('end'))), 16);
    });
  });

  group('FossListTile interaction', () {
    testWidgets('a tap fires onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          FossListTile(title: const Text('Storage'), onTap: () => taps++),
        ),
      );

      await tester.tap(find.byType(FossListTile));
      expect(taps, 1);
    });

    testWidgets('Space activates the focused row', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          FossListTile(title: const Text('Storage'), onTap: () => taps++),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(taps, 1);
    });

    testWidgets('Enter activates the focused row', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          FossListTile(title: const Text('Storage'), onTap: () => taps++),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });

    testWidgets('an inert row takes no focus and no hover fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            title: Text('Storage'),
            variant: FossListTileVariant.plain,
          ),
        ),
      );

      final gesture = await _hoverPointer(tester);
      await gesture.moveTo(tester.getCenter(find.byType(FossListTile)));
      await tester.pump();
      expect(_fill(tester).color, transparent);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(_ringPainter(tester), isNull);
    });

    testWidgets('a disabled row dims and blocks the tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('Storage'),
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(FossListTile));
      expect(taps, 0);
      expect(
        tester.widget<Opacity>(find.byType(Opacity).first).opacity,
        0.64,
      );
    });

    testWidgets('an inert row stays at full opacity', (tester) async {
      await tester.pumpWidget(
        host(const FossListTile(title: Text('Storage'))),
      );

      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('a row disabled mid-press drops the highlight', (
      tester,
    ) async {
      Widget tile({required bool enabled}) => host(
        FossListTile(
          title: const Text('Storage'),
          variant: FossListTileVariant.plain,
          enabled: enabled,
          onTap: () {},
        ),
      );

      await tester.pumpWidget(tile(enabled: true));
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FossListTile)),
      );
      await tester.pump();
      expect(_fill(tester).color, light.accent);

      // The pointer is still down, so the release never reaches the row.
      await tester.pumpWidget(tile(enabled: false));
      await tester.pump();
      expect(_fill(tester).color, transparent);

      await gesture.up();
    });

    testWidgets('a tap on an interactive trailing widget skips onTap', (
      tester,
    ) async {
      var taps = 0;
      bool? switched;
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('Notifications'),
            trailing: FossSwitch(
              value: false,
              onChanged: (v) => switched = v,
            ),
            onTap: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(FossSwitch));
      expect(switched, isTrue);
      expect(taps, 0);
    });
  });

  group('FossListTile visuals', () {
    testWidgets('a filled row paints the accent surface at rest', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossListTile(title: const Text('Storage'), onTap: () {})),
      );

      expect(_fill(tester).color, light.accent);
      expect(
        (_fill(tester).shape as RoundedSuperellipseBorder).borderRadius,
        BorderRadius.all(Radius.circular(FossThemeData.light.radii.lg)),
      );
    });

    testWidgets('a plain row is transparent at rest and rounds tighter', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('Storage'),
            variant: FossListTileVariant.plain,
            onTap: () {},
          ),
        ),
      );

      expect(_fill(tester).color, transparent);
      expect(
        (_fill(tester).shape as RoundedSuperellipseBorder).borderRadius,
        BorderRadius.all(Radius.circular(FossThemeData.light.radii.sm)),
      );
    });

    testWidgets('hovering a filled row steps past its rest fill', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossListTile(title: const Text('Storage'), onTap: () {})),
      );

      final gesture = await _hoverPointer(tester);
      await gesture.moveTo(tester.getCenter(find.byType(FossListTile)));
      await tester.pump();

      // The rest fill is translucent, so compare against what it composites to
      // on the page rather than against the raw token.
      final restOver = Color.alphaBlend(light.accent, light.background);
      final lit = _fill(tester).color;
      expect(lit, isNot(light.accent));
      expect(lit?.computeLuminance(), lessThan(restOver.computeLuminance()));
    });

    testWidgets('hovering a plain row lights it to the accent role', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('Storage'),
            variant: FossListTileVariant.plain,
            onTap: () {},
          ),
        ),
      );

      final gesture = await _hoverPointer(tester);
      await gesture.moveTo(tester.getCenter(find.byType(FossListTile)));
      await tester.pump();

      expect(_fill(tester).color, light.accent);
    });

    testWidgets('pressing fills the row the same way hover does', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('Storage'),
            variant: FossListTileVariant.plain,
            onTap: () {},
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FossListTile)),
      );
      await tester.pump();
      expect(_fill(tester).color, light.accent);

      await gesture.up();
      await tester.pump();
      expect(_fill(tester).color, transparent);
    });

    testWidgets('keyboard focus paints the ring', (tester) async {
      await tester.pumpWidget(
        host(FossListTile(title: const Text('Storage'), onTap: () {})),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(_ringPainter(tester), isNotNull);
    });

    testWidgets('the ring repaints when the theme changes under focus', (
      tester,
    ) async {
      Widget tile(FossThemeData theme) => host(
        FossListTile(title: const Text('Storage'), onTap: () {}),
        theme: theme,
      );

      await tester.pumpWidget(tile(FossThemeData.light));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      await tester.pumpWidget(tile(FossThemeData.dark));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('the ring repaints when only the corners change', (
      tester,
    ) async {
      Widget tile(double radius) => host(
        FossListTile(
          title: const Text('Storage'),
          onTap: () {},
          style: FossListTileStyle(borderRadius: radius),
        ),
      );

      await tester.pumpWidget(tile(6));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // Same theme, so the ring keeps its color and offset and only the corner
      // radius differs, which is the branch a color change short-circuits past.
      await tester.pumpWidget(tile(2));
      await tester.pump();

      expect(
        (_fill(tester).shape as RoundedSuperellipseBorder).borderRadius,
        const BorderRadius.all(Radius.circular(2)),
      );
    });

    testWidgets('the text resolves from the type and color roles', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            title: Text('Notifications'),
            subtitle: Text('Push and email'),
          ),
        ),
      );

      final typography = FossThemeData.light.typography;
      final title = _lineStyle(tester, 'Notifications').style;
      final subtitle = _lineStyle(tester, 'Push and email').style;
      expect(title.fontSize, typography.base.fontSize);
      expect(title.fontWeight, FontWeight.w600);
      expect(title.color, light.foreground);
      expect(subtitle.fontSize, typography.sm.fontSize);
      expect(subtitle.color, light.mutedForeground);
    });

    testWidgets('dark resolves from the same roles', (tester) async {
      final dark = FossThemeData.dark.colors;
      await tester.pumpWidget(
        host(
          const FossListTile(
            title: Text('Notifications'),
            subtitle: Text('Push and email'),
          ),
          theme: FossThemeData.dark,
        ),
      );

      expect(_lineStyle(tester, 'Notifications').style.color, dark.foreground);
      expect(
        _lineStyle(tester, 'Push and email').style.color,
        dark.mutedForeground,
      );
    });
  });

  group('FossListTile accessibility', () {
    testWidgets('a tappable row announces as one enabled button', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('Notifications'),
            subtitle: const Text('Push and email'),
            onTap: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(FossListTile)),
        isSemantics(
          label: 'Notifications\nPush and email',
          isButton: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );
    });

    testWidgets('an inert row carries no button role', (tester) async {
      await tester.pumpWidget(
        host(const FossListTile(title: Text('Notifications'))),
      );

      expect(
        tester.getSemantics(find.byType(FossListTile)),
        isSemantics(label: 'Notifications', isButton: false),
      );
    });

    testWidgets('a disabled row announces disabled', (tester) async {
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('Notifications'),
            enabled: false,
            onTap: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(FossListTile)),
        isSemantics(isButton: true, isEnabled: false),
      );
    });

    testWidgets('a semantic label replaces the visible lines', (tester) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            title: Text('Notifications'),
            subtitle: Text('Push and email'),
            semanticLabel: 'Notification settings',
          ),
        ),
      );

      expect(find.text('Notifications'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(FossListTile)).label,
        'Notification settings',
      );
    });

    testWidgets('a tappable row meets the tap target guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(FossListTile(title: const Text('Storage'), onTap: () {})),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('RTL puts the leading slot at the start', (tester) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            leading: SizedBox.square(dimension: 24, key: Key('lead')),
            title: Text('Notifications'),
            trailing: SizedBox.square(dimension: 24, key: Key('end')),
          ),
          direction: TextDirection.rtl,
        ),
      );

      expect(_startInset(tester, find.byKey(const Key('lead'))), 16);
      expect(_endInset(tester, find.byKey(const Key('end'))), 16);
    });

    testWidgets('a doubled text scale grows the row without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            title: Text('Notifications'),
            subtitle: Text('Push and email'),
          ),
          textScale: 2,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(FossListTile)).height,
        greaterThan(72),
      );
    });
  });

  group('FossListTile style', () {
    testWidgets('the override wins over the resolved defaults', (tester) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            title: Text('Storage'),
            style: FossListTileStyle(
              minHeight: 64,
              borderRadius: 2,
              padding: EdgeInsets.all(8),
              gap: 4,
              iconSize: 30,
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(FossListTile)).height, 64);
      expect(
        (_fill(tester).shape as RoundedSuperellipseBorder).borderRadius,
        const BorderRadius.all(Radius.circular(2)),
      );
      expect(_startInset(tester, find.text('Storage')), 8);
    });

    testWidgets('a background override resolves against the row state', (
      tester,
    ) async {
      const pressedFill = Color(0xFF16A34A);
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('Storage'),
            onTap: () {},
            style: FossListTileStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? pressedFill
                    : transparent,
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(FossListTile)),
      );
      await tester.pump();
      expect(_fill(tester).color, pressedFill);
      await gesture.up();
    });

    testWidgets('a background override sees the disabled state', (
      tester,
    ) async {
      const disabledFill = Color(0xFFDC2626);
      await tester.pumpWidget(
        host(
          FossListTile(
            title: const Text('Storage'),
            enabled: false,
            onTap: () {},
            style: FossListTileStyle(
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.disabled)
                    ? disabledFill
                    : transparent,
              ),
            ),
          ),
        ),
      );

      expect(_fill(tester).color, disabledFill);
    });

    testWidgets('a text override merges over the resolved style', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            title: Text('Storage'),
            subtitle: Text('Local and cloud'),
            style: FossListTileStyle(
              titleStyle: TextStyle(fontSize: 22),
              subtitleStyle: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
      );

      final title = _lineStyle(tester, 'Storage').style;
      final subtitle = _lineStyle(tester, 'Local and cloud').style;
      expect(title.fontSize, 22);
      expect(title.color, light.foreground);
      expect(subtitle.fontStyle, FontStyle.italic);
      expect(subtitle.color, light.mutedForeground);
    });

    testWidgets('an icon size override reaches both slots', (tester) async {
      await tester.pumpWidget(
        host(
          const FossListTile(
            leading: Icon(Icons.notifications),
            title: Text('Storage'),
            style: FossListTileStyle(iconSize: 30),
          ),
        ),
      );

      expect(IconTheme.of(tester.element(find.byType(Icon))).size, 30);
    });
  });
}
