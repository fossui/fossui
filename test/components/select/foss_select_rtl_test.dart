import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

import 'host.dart';

const List<FossSelectItem<String>> _items = [
  FossSelectItem(value: 'a', label: 'Apple'),
  FossSelectItem(value: 'b', label: 'Banana'),
];

void main() {
  testWidgets('opens the popup aligned to the anchor under RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FossSelect<String>(
          placeholder: 'Pick',
          items: _items,
          onChanged: (_) {},
        ),
        direction: TextDirection.rtl,
      ),
    );

    await tester.tap(find.text('Pick'));
    await tester.pumpAndSettle();

    expect(find.text('Banana'), findsOneWidget);
  });
}
