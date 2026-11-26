import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/fossui.dart';

void main() {
  group('FossMenuStyle.merge', () {
    test('a null override returns the receiver', () {
      const base = FossMenuStyle(minWidth: 200, iconSize: 18);
      expect(base.merge(null), same(base));
    });

    test('non-null fields of the override win, the rest are kept', () {
      const base = FossMenuStyle(minWidth: 200, iconSize: 18, rowRadius: 6);
      const override = FossMenuStyle(iconSize: 20);

      final merged = base.merge(override);
      expect(merged.minWidth, 200);
      expect(merged.iconSize, 20);
      expect(merged.rowRadius, 6);
    });

    test('every field carries across', () {
      const override = FossMenuStyle(
        minWidth: 240,
        backgroundColor: Color(0xFF101010),
        borderColor: Color(0xFF202020),
        borderRadius: 12,
        padding: EdgeInsets.all(6),
        rowRadius: 4,
        highlightColor: Color(0xFF303030),
        highlightForeground: Color(0xFF404040),
        foreground: Color(0xFF505050),
        iconSize: 22,
        textStyle: TextStyle(fontSize: 15),
      );

      final merged = const FossMenuStyle().merge(override);
      expect(merged.minWidth, 240);
      expect(merged.backgroundColor, const Color(0xFF101010));
      expect(merged.borderColor, const Color(0xFF202020));
      expect(merged.borderRadius, 12);
      expect(merged.padding, const EdgeInsets.all(6));
      expect(merged.rowRadius, 4);
      expect(merged.highlightColor, const Color(0xFF303030));
      expect(merged.highlightForeground, const Color(0xFF404040));
      expect(merged.foreground, const Color(0xFF505050));
      expect(merged.iconSize, 22);
      expect(merged.textStyle?.fontSize, 15);
    });

    test('text styles layer rather than replace', () {
      const base = FossMenuStyle(
        textStyle: TextStyle(fontSize: 15, letterSpacing: 2),
      );
      const override = FossMenuStyle(textStyle: TextStyle(fontSize: 17));

      final merged = base.merge(override);
      expect(merged.textStyle?.fontSize, 17);
      expect(merged.textStyle?.letterSpacing, 2);
    });

    test('a null text style on the override keeps the receiver', () {
      const base = FossMenuStyle(textStyle: TextStyle(fontSize: 15));
      final merged = base.merge(const FossMenuStyle(minWidth: 100));
      expect(merged.textStyle?.fontSize, 15);
    });
  });

  group('FossMenuItem', () {
    test('an action row keeps its fields', () {
      void select() {}
      final item = FossMenuItem(
        label: 'New file',
        shortcut: 'Ctrl N',
        onSelected: select,
        destructive: true,
        inset: true,
      );

      expect(item.label, 'New file');
      expect(item.shortcut, 'Ctrl N');
      expect(item.onSelected, select);
      expect(item.enabled, isTrue);
      expect(item.destructive, isTrue);
      expect(item.inset, isTrue);
    });

    test('an action row defaults to enabled, plain, and not inset', () {
      const item = FossMenuItem(label: 'New file');

      expect(item.enabled, isTrue);
      expect(item.onSelected, isNull);
      expect(item.destructive, isFalse);
      expect(item.inset, isFalse);
      expect(item.icon, isNull);
      expect(item.shortcut, isNull);
    });

    test('a separator carries no label and no action', () {
      const item = FossMenuItem.separator();

      expect(item.label, isEmpty);
      expect(item.onSelected, isNull);
      expect(item.icon, isNull);
      expect(item.shortcut, isNull);
    });

    test('a heading carries its label and can be inset', () {
      const item = FossMenuItem.label('Actions', inset: true);

      expect(item.label, 'Actions');
      expect(item.inset, isTrue);
      expect(item.onSelected, isNull);
    });
  });
}
