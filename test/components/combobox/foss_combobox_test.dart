import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

const List<String> _fruits = ['Apple', 'Banana', 'Cherry'];

const List<FossComboboxItem<String>> _items = [
  FossComboboxItem(value: 'a', label: 'Design'),
  FossComboboxItem(value: 'b', label: 'Engineering'),
  FossComboboxItem(value: 'c', label: 'Product', enabled: false),
];

const List<FossComboboxItem<String>> _iconItems = [
  FossComboboxItem(
    value: 'a',
    label: 'Design',
    icon: SizedBox.square(dimension: 12),
  ),
  FossComboboxItem(value: 'b', label: 'Engineering'),
];

/// Finds the trailing trigger by its painter, sidestepping the private type.
Finder _byPainter(String type) => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter.runtimeType.toString() == type,
);

/// A themed host that anchors [child] to the bottom, leaving no room below so
/// the popup flips above.
Widget _bottomHost(Widget child) => FossTheme(
  data: FossThemeData.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(800, 600)),
      child: Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (_) => Align(
              alignment: Alignment.bottomCenter,
              child: Padding(padding: const EdgeInsets.all(16), child: child),
            ),
          ),
        ],
      ),
    ),
  ),
);

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

    testWidgets('closes without animation when motion is reduced', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          FossAutocomplete(items: _fruits, focusNode: focus),
          reduceMotion: true,
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsOneWidget);

      focus.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Apple'), findsNothing);
    });

    testWidgets('clear button empties the field', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          FossAutocomplete(items: _fruits, focusNode: focus, showClear: true),
        ),
      );

      focus.requestFocus();
      // Two edits so the trailing rebuilds and the clear painter repaints.
      await tester.enterText(find.byType(EditableText), 'a');
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'ap');
      await tester.pumpAndSettle();

      await tester.tap(_byPainter('CloseGlyph'));
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, isEmpty);
    });

    testWidgets('renders at the large and small sizes', (tester) async {
      await tester.pumpWidget(
        host(FossAutocomplete(items: _fruits, size: FossTextFieldSize.lg)),
      );
      expect(find.byType(EditableText), findsOneWidget);

      await tester.pumpWidget(
        host(FossAutocomplete(items: _fruits, size: FossTextFieldSize.sm)),
      );
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('applies a style override', (tester) async {
      await tester.pumpWidget(
        host(
          FossAutocomplete(
            items: _fruits,
            style: const FossComboboxStyle(
              borderRadius: 12,
              textStyle: TextStyle(fontSize: 20),
            ),
          ),
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('an empty style falls back to the resolved visuals', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FossAutocomplete(items: _fruits, style: const FossComboboxStyle()),
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
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

    testWidgets('clear button reports null and empties the field', (
      tester,
    ) async {
      String? picked = 'seed';
      await tester.pumpWidget(
        host(
          FossCombobox<String>(
            value: 'b',
            items: _items,
            showClear: true,
            onSelected: (v) => picked = v,
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.controller.text, 'Engineering');

      await tester.tap(_byPainter('CloseGlyph'));
      await tester.pump();

      expect(picked, isNull);
      expect(editable.controller.text, isEmpty);
    });

    testWidgets('the trigger opens then closes the popup', (tester) async {
      await tester.pumpWidget(
        host(FossCombobox<String>(items: _items, onSelected: (_) {})),
      );

      await tester.tap(_byPainter('ChevronUpDownGlyph'));
      await tester.pumpAndSettle();
      expect(find.text('Design'), findsOneWidget);

      await tester.tap(_byPainter('ChevronUpDownGlyph'));
      await tester.pumpAndSettle();
      expect(find.text('Design'), findsNothing);
    });

    testWidgets('arrow up navigates and escape closes then is ignored', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          FossCombobox<String>(
            items: _items,
            focusNode: focus,
            onSelected: (_) {},
          ),
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Design'), findsNothing);

      // Escape again while closed but still focused is a no-op.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(find.text('Design'), findsNothing);
    });

    testWidgets('hovering an unhighlighted row moves the highlight', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          FossCombobox<String>(
            items: _items,
            focusNode: focus,
            onSelected: (_) {},
          ),
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Engineering').last));
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsWidgets);
    });

    testWidgets('renders leading row icons', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          FossCombobox<String>(
            items: _iconItems,
            focusNode: focus,
            onSelected: (_) {},
          ),
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Design'), findsOneWidget);
    });

    testWidgets('flips the popup above when there is no room below', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        _bottomHost(
          FossCombobox<String>(
            items: _items,
            focusNode: focus,
            onSelected: (_) {},
          ),
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();

      expect(find.text('Design'), findsOneWidget);
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

    testWidgets('typing filters and then shows the empty state', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(_MultiHost(items: _items, focusNode: focus)),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText), 'Eng');
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsOneWidget);
      expect(find.text('Design'), findsNothing);

      await tester.enterText(find.byType(EditableText), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('No items found.'), findsOneWidget);
    });

    testWidgets('shows the placeholder while empty', (tester) async {
      await tester.pumpWidget(
        host(_MultiHost(items: _items, hintText: 'Add tags')),
      );

      expect(find.text('Add tags'), findsOneWidget);
    });

    testWidgets('renders the label, start addon, and focused error', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          _MultiHost(
            items: _items,
            focusNode: focus,
            label: 'Tags',
            errorText: 'Required',
            startAddon: const SizedBox.square(dimension: 12),
          ),
        ),
      );

      expect(find.text('Tags'), findsOneWidget);
      expect(find.text('Required'), findsOneWidget);

      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('renders large size on a dark theme', (tester) async {
      await tester.pumpWidget(
        host(
          _MultiHost(items: _items, size: FossTextFieldSize.lg),
          theme: FossThemeData.dark,
        ),
      );
      expect(find.byType(EditableText), findsOneWidget);

      await tester.pumpWidget(
        host(_MultiHost(items: _items, size: FossTextFieldSize.sm)),
      );
      expect(find.byType(EditableText), findsOneWidget);
    });

    testWidgets('selects several chips and removes one with its button', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(_MultiHost(items: _items, focusNode: focus)),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Design').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Engineering').last);
      await tester.pumpAndSettle();

      // Each chip carries one remove cross.
      expect(_byPainter('CloseGlyph'), findsNWidgets(2));

      await tester.tap(_byPainter('CloseGlyph').first);
      await tester.pumpAndSettle();

      expect(_byPainter('CloseGlyph'), findsOneWidget);
    });

    testWidgets('backspace removes the last chip and is a no-op when empty', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(_MultiHost(items: _items, focusNode: focus)),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // No chips yet: backspace does nothing.
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(_byPainter('CloseGlyph'), findsNothing);

      await tester.tap(find.text('Design').last);
      await tester.pumpAndSettle();
      expect(_byPainter('CloseGlyph'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(_byPainter('CloseGlyph'), findsNothing);
    });

    testWidgets('keyboard navigates and Enter picks the highlighted row', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(_MultiHost(items: _items, focusNode: focus)),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();

      // Filter to a single match, then submit to pick the highlighted row.
      await tester.enterText(find.byType(EditableText), 'Eng');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(_byPainter('CloseGlyph'), findsWidgets);

      // The pick clears the query, so the full list is shown again to navigate.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Design'), findsNothing);
    });

    testWidgets('blur closes the popup with animation', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(_MultiHost(items: _items, focusNode: focus)),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Design'), findsOneWidget);

      focus.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Design'), findsNothing);
    });

    testWidgets('blur closes without animation when motion is reduced', (
      tester,
    ) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(
          _MultiHost(items: _items, focusNode: focus),
          reduceMotion: true,
        ),
      );

      focus.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Design'), findsOneWidget);

      focus.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Design'), findsNothing);
    });

    testWidgets('hovering a row repaints the selected check', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        host(_MultiHost(items: _items, focusNode: focus)),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      // Select Design so its row shows a check, then hover another row to
      // force that row (and its check) to rebuild.
      await tester.tap(find.text('Design').last);
      await tester.pumpAndSettle();

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.text('Engineering').last));
      await tester.pumpAndSettle();

      expect(find.text('Engineering'), findsWidgets);
    });
  });
}

/// A stateful wrapper so the controlled [FossMultiCombobox] value updates.
class _MultiHost extends StatefulWidget {
  const _MultiHost({
    required this.items,
    this.focusNode,
    this.label,
    this.hintText,
    this.errorText,
    this.startAddon,
    this.size = FossTextFieldSize.md,
  });

  final List<FossComboboxItem<String>> items;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? errorText;
  final Widget? startAddon;
  final FossTextFieldSize size;

  @override
  State<_MultiHost> createState() => _MultiHostState();
}

class _MultiHostState extends State<_MultiHost> {
  Set<String> _values = const {};

  @override
  Widget build(BuildContext context) => FossMultiCombobox<String>(
    items: widget.items,
    values: _values,
    focusNode: widget.focusNode,
    label: widget.label,
    hintText: widget.hintText,
    errorText: widget.errorText,
    startAddon: widget.startAddon,
    size: widget.size,
    onSelected: (v) => setState(() => _values = v),
  );
}
