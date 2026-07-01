import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foss_ui/foss_ui.dart';

import 'host.dart';

const List<String> _fruits = ['Apple', 'Banana', 'Cherry'];

const List<FossComboboxItem<String>> _items = [
  FossComboboxItem(value: 'a', label: 'Design'),
  FossComboboxItem(value: 'b', label: 'Engineering'),
  FossComboboxItem(value: 'c', label: 'Product', enabled: false),
];

void main() {
  group('FossAutocomplete', () {
    testWidgets('opens on focus and lists the items', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(FossAutocomplete(items: _fruits, focusNode: focus)),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Apple'), findsOneWidget);
      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Cherry'), findsOneWidget);
    });

    testWidgets('filters the list as the query changes', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(FossAutocomplete(items: _fruits, focusNode: focus)),
      );

      focus.requestFocus();
      await tester.enterText(find.byType(EditableText), 'an');
      await tester.pumpAndSettle();

      expect(find.text('Banana'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);
      expect(find.text('Cherry'), findsNothing);
    });

    testWidgets('picking a row writes its text and reports it', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      String? reported;
      await tester.pumpWidget(
        host(
          FossAutocomplete(
            items: _fruits,
            focusNode: focus,
            onChanged: (v) => reported = v,
          ),
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cherry'));
      await tester.pumpAndSettle();

      expect(reported, 'Cherry');
      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, 'Cherry');
    });

    testWidgets('shows the empty state when nothing matches', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(FossAutocomplete(items: _fruits, focusNode: focus)),
      );

      focus.requestFocus();
      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No items found.'), findsOneWidget);
    });
  });

  group('FossCombobox', () {
    testWidgets('shows the selected value label', (tester) async {
      await tester.pumpWidget(
        host(
          FossCombobox<String>(value: 'b', items: _items, onSelected: (_) {}),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, 'Engineering');
    });

    testWidgets('picking a row reports its value and closes', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      String? picked;
      await tester.pumpWidget(
        host(
          FossCombobox<String>(
            items: _items,
            focusNode: focus,
            onSelected: (v) => picked = v,
          ),
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design'));
      await tester.pumpAndSettle();

      expect(picked, 'a');
      expect(find.text('Engineering'), findsNothing);
    });

    testWidgets('does not pick a disabled item', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      var called = false;
      await tester.pumpWidget(
        host(
          FossCombobox<String>(
            items: _items,
            focusNode: focus,
            onSelected: (_) => called = true,
          ),
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Product'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
    });

    testWidgets('a null onSelected disables the field', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(FossCombobox<String>(items: _items, focusNode: focus)),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Design'), findsNothing);
    });
  });

  group('FossComboboxStyle', () {
    test('merge lets the other override non-null fields', () {
      const base = FossComboboxStyle(borderRadius: 8);
      const override = FossComboboxStyle(borderRadius: 12);

      expect(base.merge(override).borderRadius, 12);
      expect(base.merge(null).borderRadius, 8);
    });
  });

  group('FossComboboxItem', () {
    test('defaults to enabled with no icon', () {
      const item = FossComboboxItem(value: 1, label: 'One');

      expect(item.enabled, isTrue);
      expect(item.icon, isNull);
    });
  });

  group('FossCombobox keyboard and filter', () {
    testWidgets('arrow down then Enter picks the highlighted row', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      String? picked;
      await tester.pumpWidget(
        host(
          FossCombobox<String>(
            items: _items,
            focusNode: focus,
            onSelected: (v) => picked = v,
          ),
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // First enabled row is highlighted initially; one arrow-down moves to the
      // second enabled option.
      expect(picked, 'b');
    });

    testWidgets('a custom filter overrides the default match', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          FossCombobox<String>(
            items: _items,
            focusNode: focus,
            filter: (label, query) => label.startsWith(query),
            onSelected: (_) {},
          ),
        ),
      );

      focus.requestFocus();
      await tester.enterText(find.byType(EditableText), 'Eng');
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('Design'), findsNothing);
    });
  });

  group('FossMultiCombobox', () {
    Widget hostMulti() => host(
      _MultiHost(items: _items),
    );

    testWidgets('picking toggles a chip and keeps the popup open', (
      tester,
    ) async {
      await tester.pumpWidget(hostMulti());

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design').last);
      await tester.pumpAndSettle();

      // Chip present, and the popup is still open (rows still shown).
      expect(find.text('Design'), findsWidgets);
      expect(find.text('Engineering'), findsOneWidget);
    });

    testWidgets('picking an already-selected value removes its chip', (
      tester,
    ) async {
      await tester.pumpWidget(hostMulti());

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design').last);
      await tester.pumpAndSettle();

      // Only the row remains (no chip), so exactly one 'Design' text.
      expect(find.text('Design'), findsOneWidget);
    });

    testWidgets('a null onSelected disables the field', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(FossMultiCombobox<String>(items: _items, focusNode: focus)),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsNothing);
    });
  });
}

/// A stateful wrapper so the controlled [FossMultiCombobox] value updates.
class _MultiHost extends StatefulWidget {
  const _MultiHost({required this.items});

  final List<FossComboboxItem<String>> items;

  @override
  State<_MultiHost> createState() => _MultiHostState();
}

class _MultiHostState extends State<_MultiHost> {
  Set<String> _values = const {};

  @override
  Widget build(BuildContext context) => FossMultiCombobox<String>(
    items: widget.items,
    values: _values,
    onSelected: (v) => setState(() => _values = v),
  );
}
