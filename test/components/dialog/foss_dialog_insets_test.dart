import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/src/foundation/foss_dialog_surface.dart';
import 'package:fossui/src/theme/spacing/foss_spacing.dart';

void main() {
  const sp = FossSpacing.standard;

  group('resolveDialogInsets', () {
    test('all slots, filled footer: seams collapse against the header', () {
      final insets = resolveDialogInsets(
        spacing: sp,
        hasHeader: true,
        hasContent: true,
        hasActions: true,
        filled: true,
        safeBottom: 0,
      );

      expect(
        insets.header,
        EdgeInsets.only(left: sp(4), right: sp(4), top: sp(4), bottom: sp(4)),
      );
      // Body tightens its top to 1 under a header; a filled footer leaves the
      // body bottom at the full gutter.
      expect(
        insets.body,
        EdgeInsets.only(left: sp(4), right: sp(4), top: sp(1), bottom: sp(4)),
      );
      expect(
        insets.footer,
        EdgeInsets.only(left: sp(4), right: sp(4), top: sp(3), bottom: sp(3)),
      );
    });

    test('all slots, bare footer: body bottom and footer top collapse', () {
      final insets = resolveDialogInsets(
        spacing: sp,
        hasHeader: true,
        hasContent: true,
        hasActions: true,
        filled: false,
        safeBottom: 0,
      );

      // A bare footer under a panel tightens the body bottom to 1 and the
      // footer top to 3, then pads the bottom to the full gutter.
      expect(insets.body.bottom, sp(1));
      expect(
        insets.footer,
        EdgeInsets.only(left: sp(4), right: sp(4), top: sp(3), bottom: sp(4)),
      );
    });

    test('headerless body keeps its full top inset', () {
      final insets = resolveDialogInsets(
        spacing: sp,
        hasHeader: false,
        hasContent: true,
        hasActions: true,
        filled: false,
        safeBottom: 0,
      );

      expect(insets.body.top, sp(4));
      expect(insets.body.bottom, sp(1));
    });

    test('bare footer directly under a header pads its top to 4', () {
      final insets = resolveDialogInsets(
        spacing: sp,
        hasHeader: true,
        hasContent: false,
        hasActions: true,
        filled: false,
        safeBottom: 0,
      );

      expect(insets.footer.top, sp(4));
      expect(insets.footer.bottom, sp(4));
    });

    test('a large system inset absorbs into the footer bottom', () {
      final insets = resolveDialogInsets(
        spacing: sp,
        hasHeader: true,
        hasContent: true,
        hasActions: true,
        filled: true,
        safeBottom: 40,
      );

      expect(insets.footer.bottom, 40);
    });
  });
}
