part of 'foss_pagination.dart';

/// Visual overrides for a [FossPagination]. Every field is optional; a null
/// field falls back to the theme-resolved default. Pass one via `style:` to
/// tweak a single row without changing the theme. The button colors, radius,
/// and type resolve through [FossButton]; this carries only the row knobs.
///
/// ```dart
/// FossPagination(
///   page: page,
///   pageCount: 20,
///   onPageChanged: (p) => setState(() => page = p),
///   style: const FossPaginationStyle(gap: 6),
/// );
/// ```
@immutable
class FossPaginationStyle {
  /// Creates a set of row overrides. All fields default to null (inherit).
  const FossPaginationStyle({
    this.gap,
    this.buttonSize,
    this.activeVariant,
    this.inactiveVariant,
    this.ellipsisColor,
    this.ellipsisWidth,
  });

  /// Gap between controls, in logical pixels.
  final double? gap;

  /// Size of every control in the row.
  final FossButtonSize? buttonSize;

  /// Treatment of the current page button.
  final FossButtonVariant? activeVariant;

  /// Treatment of the other page buttons and of previous and next.
  final FossButtonVariant? inactiveVariant;

  /// Color of the ellipsis glyph.
  final Color? ellipsisColor;

  /// Width of an ellipsis slot, in logical pixels. Defaults to the width a page
  /// button occupies, which keeps the row's pitch even; narrowing it makes the
  /// row change width as ellipses come and go.
  final double? ellipsisWidth;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossPaginationStyle(gap: 2);
  /// const override = FossPaginationStyle(gap: 6);
  /// base.merge(override); // gap becomes 6
  /// ```
  FossPaginationStyle merge(FossPaginationStyle? other) {
    if (other == null) return this;
    return FossPaginationStyle(
      gap: other.gap ?? gap,
      buttonSize: other.buttonSize ?? buttonSize,
      activeVariant: other.activeVariant ?? activeVariant,
      inactiveVariant: other.inactiveVariant ?? inactiveVariant,
      ellipsisColor: other.ellipsisColor ?? ellipsisColor,
      ellipsisWidth: other.ellipsisWidth ?? ellipsisWidth,
    );
  }
}
