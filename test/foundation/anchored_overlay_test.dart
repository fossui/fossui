import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fossui/src/foundation/anchored_overlay.dart';

void main() {
  // A 40x20 trigger centered in an 800x600 viewport, with room on every side.
  const anchor = Rect.fromLTWH(380, 290, 40, 20);
  const viewport = Size(800, 600);
  const child = Size(100, 50);
  const margin = kAnchorViewportMargin;

  Offset position(
    AnchorSide side, {
    AnchorAlign align = AnchorAlign.center,
    double sideOffset = kAnchorSideOffset,
    double alignOffset = 0,
    Rect rect = anchor,
    Size size = viewport,
  }) => AnchoredLayout(
    anchor: rect,
    side: side,
    align: align,
    sideOffset: sideOffset,
    alignOffset: alignOffset,
  ).getPositionForChild(size, child);

  group('AnchoredLayout main axis', () {
    test('bottom sits below the anchor by the side offset', () {
      expect(position(AnchorSide.bottom).dy, anchor.bottom + kAnchorSideOffset);
    });

    test('top sits above the anchor by the side offset', () {
      expect(
        position(AnchorSide.top).dy,
        anchor.top - kAnchorSideOffset - child.height,
      );
    });

    test('right sits past the trailing edge by the side offset', () {
      expect(position(AnchorSide.right).dx, anchor.right + kAnchorSideOffset);
    });

    test('left sits before the leading edge by the side offset', () {
      expect(
        position(AnchorSide.left).dx,
        anchor.left - kAnchorSideOffset - child.width,
      );
    });

    test('a custom side offset widens the gap', () {
      expect(
        position(AnchorSide.bottom, sideOffset: 12).dy,
        anchor.bottom + 12,
      );
    });
  });

  group('AnchoredLayout cross axis align', () {
    test('center aligns the child midpoint to the anchor midpoint', () {
      expect(
        position(AnchorSide.bottom).dx,
        anchor.center.dx - child.width / 2,
      );
    });

    test('start aligns to the leading edge', () {
      expect(
        position(AnchorSide.bottom, align: AnchorAlign.start).dx,
        anchor.left,
      );
    });

    test('end aligns to the trailing edge', () {
      expect(
        position(AnchorSide.bottom, align: AnchorAlign.end).dx,
        anchor.right - child.width,
      );
    });

    test('align offset shifts along the cross axis', () {
      final base = position(AnchorSide.bottom, align: AnchorAlign.start).dx;
      expect(
        position(
          AnchorSide.bottom,
          align: AnchorAlign.start,
          alignOffset: 6,
        ).dx,
        base + 6,
      );
    });

    test('vertical sides align on the y axis', () {
      expect(
        position(AnchorSide.right, align: AnchorAlign.start).dy,
        anchor.top,
      );
      expect(
        position(AnchorSide.right, align: AnchorAlign.end).dy,
        anchor.bottom - child.height,
      );
    });
  });

  group('AnchoredLayout flip', () {
    test('bottom flips to top with no room below', () {
      // Trigger flush to the viewport bottom: below cannot fit, above can.
      const low = Rect.fromLTWH(380, 580, 40, 20);
      expect(
        position(AnchorSide.bottom, rect: low).dy,
        low.top - kAnchorSideOffset - child.height,
      );
    });

    test('right flips to left with no room on the right', () {
      const far = Rect.fromLTWH(740, 290, 40, 20);
      expect(
        position(AnchorSide.right, rect: far).dx,
        far.left - kAnchorSideOffset - child.width,
      );
    });

    test('stays put when neither side fits', () {
      // A child taller than the whole viewport fits nowhere; the side holds and
      // the position clamps to the top margin.
      const tall = Size(100, 700);
      final delegate = AnchoredLayout(anchor: anchor, side: AnchorSide.bottom);
      expect(delegate.getPositionForChild(viewport, tall).dy, margin);
    });
  });

  group('AnchoredLayout clamp', () {
    test('keeps the child off the viewport edge', () {
      // An end-aligned child on a near-edge trigger clamps to the margin.
      const edge = Rect.fromLTWH(0, 290, 40, 20);
      final dx = position(
        AnchorSide.bottom,
        align: AnchorAlign.end,
        rect: edge,
      ).dx;
      expect(dx, greaterThanOrEqualTo(margin));
    });

    test('constraints subtract the horizontal margin', () {
      final constraints = AnchoredLayout(
        anchor: anchor,
        side: AnchorSide.bottom,
      ).getConstraintsForChild(BoxConstraints.tight(viewport));
      expect(constraints.maxWidth, viewport.width - margin * 2);
    });

    test('constraints subtract the vertical margin', () {
      // A tall child must be bounded to the viewport height so it shrinks to
      // fit rather than overflowing off-screen after the clamp.
      final constraints = AnchoredLayout(
        anchor: anchor,
        side: AnchorSide.bottom,
      ).getConstraintsForChild(BoxConstraints.tight(viewport));
      expect(constraints.maxHeight, viewport.height - margin * 2);
    });
  });

  group('shouldRelayout', () {
    test('true when any field differs', () {
      final base = AnchoredLayout(anchor: anchor, side: AnchorSide.bottom);
      expect(
        base.shouldRelayout(
          AnchoredLayout(anchor: anchor, side: AnchorSide.top),
        ),
        isTrue,
      );
      expect(
        base.shouldRelayout(
          AnchoredLayout(anchor: anchor, side: AnchorSide.bottom),
        ),
        isFalse,
      );
    });
  });
}
