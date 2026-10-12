import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

Finder _byRole(SemanticsRole role) => find.byWidgetPredicate(
  (w) => w is Semantics && w.properties.role == role,
);

void main() {
  group('FossMenu a11y', () {
    testWidgets('the panel is a menu and its rows are menu items', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              FossMenuItem(label: 'First', onSelected: () {}),
              FossMenuItem(label: 'Second', onSelected: () {}),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_byRole(SemanticsRole.menu), findsOneWidget);
      expect(_byRole(SemanticsRole.menuItem), findsNWidgets(2));
    });

    testWidgets('a list of only disabled rows keeps the menu role', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const FossMenu(
            items: [FossMenuItem(label: 'Blocked', enabled: false)],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_byRole(SemanticsRole.menu), findsOneWidget);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('a list of only separators and headings carries no role', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          const FossMenu(
            items: [
              FossMenuItem.label('Actions'),
              FossMenuItem.separator(),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_byRole(SemanticsRole.menu), findsNothing);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('an empty list carries no role', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(const FossMenu(items: [], child: menuTrigger)),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(_byRole(SemanticsRole.menu), findsNothing);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('a disabled row announces itself as disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              FossMenuItem(label: 'First', onSelected: () {}),
              const FossMenuItem(label: 'Blocked', enabled: false),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Blocked')),
        matchesSemantics(
          label: 'Blocked',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a shortcut is announced as part of its row', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [
              FossMenuItem(
                label: 'New file',
                shortcut: 'Ctrl N',
                onSelected: () {},
              ),
            ],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.text('New file'));
      expect(node.label, contains('New file'));
      expect(node.label, contains('Ctrl N'));
      handle.dispose();
    });

    testWidgets('the trigger meets the Android tap target guideline', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'First', onSelected: () {})],
            child: const SizedBox(width: 96, height: 48, child: menuTrigger),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('the trigger announces its expanded state', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'First', onSelected: () {})],
            child: menuTrigger,
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Open')),
        matchesSemantics(
          label: 'Open',
          isButton: true,
          isFocusable: true,
          hasExpandedState: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.text('Open')),
        matchesSemantics(
          label: 'Open',
          isButton: true,
          isFocusable: true,
          hasExpandedState: true,
          isExpanded: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('focus returns to the trigger after Escape', (tester) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'First', onSelected: () {})],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'FossMenu trigger',
      );
    });

    testWidgets('focus returns to the trigger after a selection', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'First', onSelected: () {})],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('First'));
      await tester.pumpAndSettle();

      expect(
        tester.binding.focusManager.primaryFocus?.debugLabel,
        'FossMenu trigger',
      );
    });

    testWidgets('the Android back button dismisses the panel', (tester) async {
      await tester.pumpWidget(
        host(
          FossMenu(
            items: [FossMenuItem(label: 'First', onSelected: () {})],
            child: menuTrigger,
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final handled = await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(handled, isTrue);
      expect(find.text('First'), findsNothing);
    });
  });
}
