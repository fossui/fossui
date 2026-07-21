import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/colors/foss_colors.dart';

/// The physical side of an anchor a floating overlay opens on, after any RTL
/// resolution. The overlay flips to the opposite side when it would overflow.
enum AnchorSide {
  /// Above the anchor.
  top,

  /// Below the anchor.
  bottom,

  /// The left of the anchor.
  left,

  /// The right of the anchor.
  right,
}

/// How a floating overlay aligns to its anchor along the cross axis of its
/// [AnchorSide]: the horizontal axis for [AnchorSide.top] / [AnchorSide.bottom],
/// the vertical axis for [AnchorSide.left] / [AnchorSide.right].
enum AnchorAlign {
  /// Flush with the anchor's leading edge on the cross axis.
  start,

  /// Centered on the anchor's cross axis.
  center,

  /// Flush with the anchor's trailing edge on the cross axis.
  end,
}

/// Default gap between an anchored overlay and its anchor, in logical pixels.
const double kAnchorSideOffset = 4;

/// Keeps an anchored overlay this far off the viewport edge on overflow.
const double kAnchorViewportMargin = 8;

/// Positions a floating overlay against [anchor] on the preferred [side] and
/// [align], flipping to the opposite side and clamping into the viewport so it
/// never overflows the screen. All values are physical: callers resolve the
/// reading direction before constructing the delegate.
class AnchoredLayout extends SingleChildLayoutDelegate {
  /// Creates a layout delegate anchored to [anchor].
  AnchoredLayout({
    required this.anchor,
    required this.side,
    this.align = AnchorAlign.center,
    this.sideOffset = kAnchorSideOffset,
    this.alignOffset = 0,
  });

  /// The anchor rectangle in the overlay's coordinate space.
  final Rect anchor;

  /// The preferred side to open on.
  final AnchorSide side;

  /// The cross-axis alignment against the anchor.
  final AnchorAlign align;

  /// The gap from the anchor along the main axis.
  final double sideOffset;

  /// The shift along the cross axis, in the physical direction of [align].
  final double alignOffset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(
        maxWidth: constraints.maxWidth - kAnchorViewportMargin * 2,
        maxHeight: constraints.maxHeight - kAnchorViewportMargin * 2,
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final position = _place(childSize, _resolveSide(size, childSize));
    return Offset(
      _clamp(position.dx, size.width - childSize.width),
      _clamp(position.dy, size.height - childSize.height),
    );
  }

  /// Keeps [value] within `[margin, upper]`, collapsing to the margin when the
  /// child is larger than the available room.
  double _clamp(double value, double upper) {
    final hi = upper - kAnchorViewportMargin;
    return hi < kAnchorViewportMargin
        ? kAnchorViewportMargin
        : value.clamp(kAnchorViewportMargin, hi);
  }

  Offset _place(Size child, AnchorSide side) {
    switch (side) {
      case AnchorSide.top:
      case AnchorSide.bottom:
        final dx =
            _crossStart(child.width, anchor.left, anchor.right) + alignOffset;
        final dy = side == AnchorSide.top
            ? anchor.top - sideOffset - child.height
            : anchor.bottom + sideOffset;
        return Offset(dx, dy);
      case AnchorSide.left:
      case AnchorSide.right:
        final dy =
            _crossStart(child.height, anchor.top, anchor.bottom) + alignOffset;
        final dx = side == AnchorSide.left
            ? anchor.left - sideOffset - child.width
            : anchor.right + sideOffset;
        return Offset(dx, dy);
    }
  }

  /// The cross-axis origin for [extent] between the anchor's [lead] and [trail]
  /// edges, resolved against [align].
  double _crossStart(double extent, double lead, double trail) =>
      switch (align) {
        AnchorAlign.start => lead,
        AnchorAlign.center => lead + (trail - lead) / 2 - extent / 2,
        AnchorAlign.end => trail - extent,
      };

  AnchorSide _resolveSide(Size size, Size child) {
    bool fitsTop() =>
        anchor.top - sideOffset - child.height >= kAnchorViewportMargin;
    bool fitsBottom() =>
        anchor.bottom + sideOffset + child.height <=
        size.height - kAnchorViewportMargin;
    bool fitsLeft() =>
        anchor.left - sideOffset - child.width >= kAnchorViewportMargin;
    bool fitsRight() =>
        anchor.right + sideOffset + child.width <=
        size.width - kAnchorViewportMargin;

    return switch (side) {
      AnchorSide.top when !fitsTop() && fitsBottom() => AnchorSide.bottom,
      AnchorSide.bottom when !fitsBottom() && fitsTop() => AnchorSide.top,
      AnchorSide.left when !fitsLeft() && fitsRight() => AnchorSide.right,
      AnchorSide.right when !fitsRight() && fitsLeft() => AnchorSide.left,
      _ => side,
    };
  }

  @override
  bool shouldRelayout(AnchoredLayout old) =>
      old.anchor != anchor ||
      old.side != side ||
      old.align != align ||
      old.sideOffset != sideOffset ||
      old.alignOffset != alignOffset;
}

/// Softens a shadow set to the 5% tint a floating overlay wears, a fainter drop
/// than a surface at the same elevation.
List<BoxShadow> overlaySoftShadow(List<BoxShadow> base) => <BoxShadow>[
  for (final shadow in base)
    shadow.copyWith(color: shadow.color.withValues(alpha: 0.05)),
];

/// The raised-edge highlight inside an overlay surface border: a top line in
/// light mode, a bottom line in dark mode, derived from the foreground role at
/// low alpha. Fill a surface's clipped bounds with it via [Positioned.fill].
class OverlayInnerRing extends StatelessWidget {
  /// Creates the inner highlight ring for [colors].
  const OverlayInnerRing({required this.colors, super.key});

  /// The active color roles, read for the foreground tint and brightness.
  final FossColors colors;

  @override
  Widget build(BuildContext context) {
    final dark = colors.isDark;
    final highlight = colors.foreground.withValues(alpha: dark ? 0.06 : 0.04);
    final edge = BorderSide(color: highlight);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: dark ? BorderSide.none : edge,
          bottom: dark ? edge : BorderSide.none,
        ),
      ),
    );
  }
}
