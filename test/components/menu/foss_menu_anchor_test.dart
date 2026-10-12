import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/src/foundation/anchored_overlay.dart';

/// The panel promises to open against any rectangle, including a zero-size one
/// at a pointer, which is the path a press-anchored opener takes. These cover
/// that promise at the layout level, with no trigger widget in the tree.
void main() {
  const viewport = Size(800, 600);
  const panel = Size(160, 120);

  group('a panel anchored to a pointer', () {
    test('opens at the pointer with no gap', () {
      final layout = AnchoredLayout(
        anchor: const Rect.fromLTWH(200, 300, 0, 0),
        side: AnchorSide.bottom,
        align: AnchorAlign.start,
        sideOffset: 0,
      );

      expect(
        layout.getPositionForChild(viewport, panel),
        const Offset(200, 300),
      );
    });

    test('clamps inside the viewport near the end corner', () {
      final layout = AnchoredLayout(
        anchor: const Rect.fromLTWH(795, 595, 0, 0),
        side: AnchorSide.bottom,
        align: AnchorAlign.start,
        sideOffset: 0,
      );

      final offset = layout.getPositionForChild(viewport, panel);
      expect(offset.dx, viewport.width - panel.width - 8);
      expect(offset.dy, viewport.height - panel.height - 8);
    });

    test('flips above a pointer with no room below', () {
      final layout = AnchoredLayout(
        anchor: const Rect.fromLTWH(100, 560, 0, 0),
        side: AnchorSide.bottom,
        align: AnchorAlign.start,
        sideOffset: 0,
      );

      expect(
        layout.getPositionForChild(viewport, panel).dy,
        560 - panel.height,
      );
    });

    test('the end align hangs the panel back from the pointer', () {
      final layout = AnchoredLayout(
        anchor: const Rect.fromLTWH(400, 200, 0, 0),
        side: AnchorSide.bottom,
        align: AnchorAlign.end,
        sideOffset: 0,
      );

      expect(
        layout.getPositionForChild(viewport, panel).dx,
        400 - panel.width,
      );
    });
  });
}
