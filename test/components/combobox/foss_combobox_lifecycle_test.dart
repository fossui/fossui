import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

const List<FossComboboxItem<String>> _items = [
  FossComboboxItem(value: 'a', label: 'Design'),
  FossComboboxItem(value: 'b', label: 'Engineering'),
];

// A host that genuinely rebuilds its child on each pump, so didUpdateWidget
// fires on the field under test.
Widget _host(Widget child) => FossTheme(
  data: FossThemeData.light,
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: const MediaQueryData(size: Size(400, 640)),
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 280, child: child),
      ),
    ),
  ),
);

void main() {
  group('FossCombobox rebuild', () {
    testWidgets('a changed value syncs the field text', (tester) async {
      await tester.pumpWidget(
        _host(
          FossCombobox<String>(items: _items, value: 'a', onSelected: (_) {}),
        ),
      );
      expect(find.text('Design'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          FossCombobox<String>(items: _items, value: 'b', onSelected: (_) {}),
        ),
      );
      await tester.pump();
      expect(find.text('Engineering'), findsOneWidget);
    });

    testWidgets('a swapped focus node keeps the field alive', (tester) async {
      final first = FocusNode();
      final second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await tester.pumpWidget(
        _host(FossCombobox<String>(items: _items, focusNode: first)),
      );
      await tester.pumpWidget(
        _host(FossCombobox<String>(items: _items, focusNode: second)),
      );
      // Back to an owned node.
      await tester.pumpWidget(
        _host(const FossCombobox<String>(items: _items)),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('FossAutocomplete rebuild', () {
    testWidgets('swapping the controller adopts its text', (tester) async {
      final first = TextEditingController(text: 'Apple');
      final second = TextEditingController(text: 'Banana');
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await tester.pumpWidget(
        _host(FossAutocomplete(items: const ['Apple'], controller: first)),
      );
      expect(find.text('Apple'), findsOneWidget);

      await tester.pumpWidget(
        _host(FossAutocomplete(items: const ['Apple'], controller: second)),
      );
      await tester.pump();
      expect(find.text('Banana'), findsOneWidget);

      // Dropping the controller falls back to an owned one seeded from it.
      await tester.pumpWidget(
        _host(const FossAutocomplete(items: ['Apple'])),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('FossMultiCombobox', () {
    testWidgets('renders selections and an error, then swaps focus', (
      tester,
    ) async {
      final first = FocusNode();
      final second = FocusNode();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await tester.pumpWidget(
        _host(
          FossMultiCombobox<String>(
            items: _items,
            values: const {'a'},
            errorText: 'Pick at least two',
            focusNode: first,
            // A style with these set exercises the token-override branches.
            style: const FossComboboxStyle(
              backgroundColor: Color(0xFFF5F5F5),
              borderRadius: 12,
            ),
          ),
        ),
      );
      expect(find.text('Design'), findsOneWidget);
      expect(find.text('Pick at least two'), findsOneWidget);

      await tester.pumpWidget(
        _host(
          FossMultiCombobox<String>(
            items: _items,
            values: const {'a'},
            focusNode: second,
          ),
        ),
      );
      await tester.pumpWidget(
        _host(
          FossMultiCombobox<String>(items: _items, values: const {'a'}),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });
}
