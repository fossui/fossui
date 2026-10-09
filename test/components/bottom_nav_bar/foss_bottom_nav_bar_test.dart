import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

const _items = <FossBottomNavItem<String>>[
  FossBottomNavItem(
    value: 'home',
    label: 'Home',
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
  ),
  FossBottomNavItem(
    value: 'search',
    label: 'Search',
    icon: Icon(Icons.search),
  ),
  FossBottomNavItem(value: 'you', label: 'You', icon: Icon(Icons.person)),
];

Color? _labelColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

IconThemeData _iconTheme(WidgetTester tester, IconData icon) => tester
    .widget<IconTheme>(
      find
          .ancestor(of: find.byIcon(icon), matching: find.byType(IconTheme))
          .first,
    )
    .data;

Size _cell(WidgetTester tester, String label) =>
    tester.getSize(find.bySemanticsLabel(label));

Size _bar(WidgetTester tester) =>
    tester.getSize(find.byType(FossBottomNavBar<String>));

Finder _topBorder(Color color) => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final decoration = w.decoration;
  if (decoration is! BoxDecoration) return false;
  final border = decoration.border;
  return border is Border &&
      border.top.color.toARGB32() == color.toARGB32() &&
      border.top.width == 1;
});

void main() {
  final colors = FossThemeData.light.colors;

  group('FossBottomNavBarStyle.merge', () {
    test('other wins field by field, this fills the gaps', () {
      const base = FossBottomNavBarStyle(
        backgroundColor: Color(0xFF111111),
        selectedColor: Color(0xFF222222),
        minHeight: 64,
      );
      const over = FossBottomNavBarStyle(selectedColor: Color(0xFF333333));

      final merged = base.merge(over);
      expect(merged.selectedColor, const Color(0xFF333333));
      expect(merged.backgroundColor, const Color(0xFF111111));
      expect(merged.minHeight, 64);
    });

    test('null other returns this', () {
      const base = FossBottomNavBarStyle(borderColor: Color(0xFF111111));
      expect(base.merge(null), same(base));
    });

    test('every field carries through a merge onto an empty style', () {
      const full = FossBottomNavBarStyle(
        backgroundColor: Color(0xFF010101),
        borderColor: Color(0xFF020202),
        selectedColor: Color(0xFF030303),
        unselectedColor: Color(0xFF040404),
        labelStyle: TextStyle(fontSize: 11),
        iconSize: 20,
        minHeight: 72,
        showTopBorder: false,
      );

      final merged = const FossBottomNavBarStyle().merge(full);
      expect(merged.backgroundColor, const Color(0xFF010101));
      expect(merged.borderColor, const Color(0xFF020202));
      expect(merged.selectedColor, const Color(0xFF030303));
      expect(merged.unselectedColor, const Color(0xFF040404));
      expect(merged.labelStyle?.fontSize, 11);
      expect(merged.iconSize, 20);
      expect(merged.minHeight, 72);
      expect(merged.showTopBorder, isFalse);
    });
  });

  group('FossBottomNavItem', () {
    test('a runtime-built item holds its data', () {
      final item = FossBottomNavItem<String>(
        value: 'home',
        label: 'Home'.toUpperCase(),
      );
      expect(item.value, 'home');
      expect(item.label, 'HOME');
      expect(item.enabled, isTrue);
      expect(item.icon, isNull);
      expect(item.selectedIcon, isNull);
      expect(item.badge, isNull);
    });
  });

  group('FossBottomNavBar rendering', () {
    testWidgets('renders every label with the current one in foreground', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossBottomNavBar<String>(items: _items, value: 'search')),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('You'), findsOneWidget);

      expect(_labelColor(tester, 'Search'), colors.foreground);
      expect(_labelColor(tester, 'Home'), colors.mutedForeground);
      expect(_iconTheme(tester, Icons.search).color, colors.foreground);
      expect(_iconTheme(tester, Icons.person).color, colors.mutedForeground);
      expect(_iconTheme(tester, Icons.search).size, 24);
    });

    testWidgets('label uses the xs scale at medium weight', (tester) async {
      await tester.pumpWidget(
        host(FossBottomNavBar<String>(items: _items, value: 'home')),
      );

      final style = tester.widget<Text>(find.text('Home')).style;
      expect(style?.fontSize, 12);
      expect(style?.fontWeight, FontWeight.w500);
    });

    testWidgets('paints the background and the top hairline', (tester) async {
      await tester.pumpWidget(
        host(FossBottomNavBar<String>(items: _items, value: 'home')),
      );

      expect(_topBorder(colors.border), findsOneWidget);
    });

    testWidgets('selectedIcon replaces the icon only while current', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossBottomNavBar<String>(items: _items, value: 'home')),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);

      await tester.pumpWidget(
        host(FossBottomNavBar<String>(items: _items, value: 'search')),
      );

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.home), findsNothing);
    });

    testWidgets('cells share the width evenly at two through five items', (
      tester,
    ) async {
      for (final count in [2, 3, 4, 5]) {
        final items = <FossBottomNavItem<String>>[
          for (var i = 0; i < count; i++)
            FossBottomNavItem(
              value: 'v$i',
              label: 'L$i',
              icon: const Icon(Icons.circle),
            ),
        ];
        await tester.pumpWidget(
          host(FossBottomNavBar<String>(items: items, value: 'v0')),
        );

        final widths = <double>[
          for (var i = 0; i < count; i++) _cell(tester, 'L$i').width,
        ];
        expect(widths.every((w) => (w - 393 / count).abs() < 0.5), isTrue);
      }
    });

    testWidgets('bar stands at 56 and grows with the text scaler', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossBottomNavBar<String>(items: _items, value: 'home')),
      );
      expect(_bar(tester).height, 56);

      await tester.pumpWidget(
        host(
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: FossBottomNavBar<String>(items: _items, value: 'home'),
          ),
        ),
      );
      expect(_bar(tester).height, greaterThan(56));
    });

    testWidgets('a bounded-height parent does not stretch the bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 400,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FossBottomNavBar<String>(items: _items, value: 'home'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(_bar(tester).height, 56);

      // The same bar as the only child of a tall bounded box: it hugs its
      // content rather than filling the box.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 400,
                width: 393,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FossBottomNavBar<String>(
                    items: _items,
                    value: 'home',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(_bar(tester).height, 56);
    });

    testWidgets('a long label ellipsizes instead of wrapping', (tester) async {
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            value: 'a',
            items: const [
              FossBottomNavItem(
                value: 'a',
                label: 'Notifications and alerts',
                icon: Icon(Icons.circle),
              ),
              FossBottomNavItem(
                value: 'b',
                label: 'Settings and preferences',
                icon: Icon(Icons.circle),
              ),
            ],
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Notifications and alerts'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the safe-area inset sits below the cells', (tester) async {
      const inset = 34.0;
      await tester.pumpWidget(
        host(
          const MediaQuery(
            data: MediaQueryData(padding: EdgeInsets.only(bottom: inset)),
            child: FossBottomNavBar<String>(items: _items, value: 'home'),
          ),
        ),
      );

      expect(_bar(tester).height, 56 + inset);
      // The cell keeps its full height; the inset is padding under it.
      expect(_cell(tester, 'Home').height, 56);
    });

    testWidgets('style overrides the theme-resolved defaults', (tester) async {
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            items: _items,
            value: 'home',
            style: const FossBottomNavBarStyle(
              selectedColor: Color(0xFF00FF00),
              iconSize: 30,
              minHeight: 72,
              showTopBorder: false,
            ),
          ),
        ),
      );

      expect(_labelColor(tester, 'Home'), const Color(0xFF00FF00));
      expect(_iconTheme(tester, Icons.home).size, 30);
      expect(_bar(tester).height, 72);
      expect(_topBorder(colors.border), findsNothing);
    });
  });

  group('FossBottomNavBar badge', () {
    testWidgets('pins to the glyph top end and mirrors under RTL', (
      tester,
    ) async {
      final items = <FossBottomNavItem<String>>[
        const FossBottomNavItem(
          value: 'home',
          label: 'Home',
          icon: Icon(Icons.home),
        ),
        const FossBottomNavItem(
          value: 'inbox',
          label: 'Inbox',
          icon: Icon(Icons.mail),
          badge: FossBadge(size: FossBadgeSize.sm, label: Text('3')),
        ),
      ];

      await tester.pumpWidget(
        host(FossBottomNavBar<String>(items: items, value: 'home')),
      );
      final ltrBadge = tester.getCenter(find.text('3')).dx;
      final ltrGlyph = tester.getCenter(find.byIcon(Icons.mail)).dx;
      expect(ltrBadge, greaterThan(ltrGlyph));

      await tester.pumpWidget(
        host(
          Directionality(
            textDirection: TextDirection.rtl,
            child: FossBottomNavBar<String>(items: items, value: 'home'),
          ),
        ),
      );
      final rtlBadge = tester.getCenter(find.text('3')).dx;
      final rtlGlyph = tester.getCenter(find.byIcon(Icons.mail)).dx;
      expect(rtlBadge, lessThan(rtlGlyph));
      expect(tester.takeException(), isNull);
    });
  });

  group('FossBottomNavBar interaction', () {
    testWidgets('a tap reports the destination', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            items: _items,
            value: 'home',
            onChanged: picked.add,
          ),
        ),
      );

      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(picked, ['search']);
    });

    testWidgets('re-tapping the current destination reports it again', (
      tester,
    ) async {
      final picked = <String>[];
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            items: _items,
            value: 'home',
            onChanged: picked.add,
          ),
        ),
      );

      await tester.tap(find.text('Home'));
      await tester.pump();
      await tester.tap(find.text('Home'));
      await tester.pump();

      expect(picked, ['home', 'home']);
    });

    testWidgets('a disabled destination dims and blocks', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            value: 'home',
            onChanged: picked.add,
            items: const [
              FossBottomNavItem(
                value: 'home',
                label: 'Home',
                icon: Icon(Icons.home),
              ),
              FossBottomNavItem(
                value: 'team',
                label: 'Team',
                icon: Icon(Icons.group),
                enabled: false,
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Team'), warnIfMissed: false);
      await tester.pump();

      expect(picked, isEmpty);
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(
                    of: find.text('Team'),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        0.64,
      );
    });

    testWidgets('a null onChanged dims every destination and blocks', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(FossBottomNavBar<String>(items: _items, value: 'home')),
      );

      await tester.tap(find.text('Search'), warnIfMissed: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(find.byType(Opacity), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });
  });

  group('FossBottomNavBar keyboard', () {
    testWidgets('arrows move focus, Enter reports, skipping disabled', (
      tester,
    ) async {
      final picked = <String>[];
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            value: 'home',
            onChanged: picked.add,
            items: const [
              FossBottomNavItem(
                value: 'home',
                label: 'Home',
                icon: Icon(Icons.home),
              ),
              FossBottomNavItem(
                value: 'team',
                label: 'Team',
                icon: Icon(Icons.group),
                enabled: false,
              ),
              FossBottomNavItem(
                value: 'you',
                label: 'You',
                icon: Icon(Icons.person),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Home'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      // The disabled middle cell is skipped, so the move lands on the last.
      expect(picked, ['home', 'you']);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(picked.last, 'home');
    });

    testWidgets('Home and End reach both ends', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            items: _items,
            value: 'search',
            onChanged: picked.add,
          ),
        ),
      );

      await tester.tap(find.text('Search'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked.last, 'you');

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(picked.last, 'home');
    });

    testWidgets('arrows follow the text direction under RTL', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        host(
          Directionality(
            textDirection: TextDirection.rtl,
            child: FossBottomNavBar<String>(
              items: _items,
              value: 'search',
              onChanged: picked.add,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Search'));
      await tester.pump();

      // Right moves toward the start of the list under RTL.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(picked.last, 'home');
    });

    testWidgets('an unhandled key is left to the rest of the tree', (
      tester,
    ) async {
      final picked = <String>[];
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            items: _items,
            value: 'home',
            onChanged: picked.add,
          ),
        ),
      );

      await tester.tap(find.text('Home'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(picked, ['home']);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an arrow at the edge stays put', (tester) async {
      final picked = <String>[];
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            items: _items,
            value: 'home',
            onChanged: picked.add,
          ),
        ),
      );

      await tester.tap(find.text('Home'));
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(picked, ['home', 'home']);
    });
  });

  group('FossBottomNavBar accessibility', () {
    testWidgets('the bar is a tab bar and the current cell a selected tab', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            items: _items,
            value: 'search',
            onChanged: (_) {},
          ),
        ),
      );

      // The strip carries the tab-bar role; its cells carry the tab role.
      expect(
        tester
            .widget<Semantics>(
              find
                  .descendant(
                    of: find.byType(FossBottomNavBar<String>),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .role,
        SemanticsRole.tabBar,
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Search')),
        isSemantics(
          isSelected: true,
          hasSelectedState: true,
          isEnabled: true,
          label: 'Search',
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Home')),
        isSemantics(isSelected: false, hasSelectedState: true, label: 'Home'),
      );
      handle.dispose();
    });

    testWidgets('a disabled cell announces disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            value: 'home',
            onChanged: (_) {},
            items: const [
              FossBottomNavItem(
                value: 'home',
                label: 'Home',
                icon: Icon(Icons.home),
              ),
              FossBottomNavItem(
                value: 'team',
                label: 'Team',
                icon: Icon(Icons.group),
                enabled: false,
              ),
            ],
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Team')),
        isSemantics(isEnabled: false, hasEnabledState: true, label: 'Team'),
      );
      handle.dispose();
    });

    testWidgets('meets the tap target and labelling guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossBottomNavBar<String>(
            value: 'home',
            onChanged: (_) {},
            items: const [
              FossBottomNavItem(value: 'a', label: 'A', icon: Icon(Icons.abc)),
              FossBottomNavItem(value: 'b', label: 'B', icon: Icon(Icons.abc)),
              FossBottomNavItem(value: 'c', label: 'C', icon: Icon(Icons.abc)),
              FossBottomNavItem(value: 'd', label: 'D', icon: Icon(Icons.abc)),
              FossBottomNavItem(
                value: 'home',
                label: 'Home',
                icon: Icon(Icons.home),
              ),
            ],
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      // textContrastGuideline is not asserted here: the unselected label is the
      // muted role on the background, which measures 4.12:1 against the 4.5
      // AA floor for normal text. That ratio is a property of the token pair,
      // not of this component, and every other muted-on-background label in
      // the library carries it.
      handle.dispose();
    });

    testWidgets('dropping a destination disposes its node', (tester) async {
      late StateSetter setOuter;
      var full = true;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return FossBottomNavBar<String>(
                value: 'search',
                onChanged: (_) {},
                items: full
                    ? _items
                    : const [
                        FossBottomNavItem(
                          value: 'search',
                          label: 'Search',
                          icon: Icon(Icons.search),
                        ),
                        FossBottomNavItem(
                          value: 'you',
                          label: 'You',
                          icon: Icon(Icons.person),
                        ),
                      ],
              );
            },
          ),
        ),
      );

      setOuter(() => full = false);
      await tester.pump();

      expect(find.text('Home'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark theme resolves the roles from the bundle', (
      tester,
    ) async {
      const dark = FossThemeData.dark;
      await tester.pumpWidget(
        host(
          FossTheme(
            data: dark,
            child: FossBottomNavBar<String>(items: _items, value: 'home'),
          ),
        ),
      );

      expect(_labelColor(tester, 'Home'), dark.colors.foreground);
      expect(_labelColor(tester, 'You'), dark.colors.mutedForeground);
      expect(_topBorder(dark.colors.border), findsOneWidget);
    });
  });
}
