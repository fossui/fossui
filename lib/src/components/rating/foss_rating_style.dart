part of 'foss_rating.dart';

/// Visual overrides for a single [FossRating]. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other rating.
///
/// State-derived colors (the focus ring) stay token-driven. To restyle those
/// globally, retheme `FossColors`.
///
/// An amber rating with larger marks:
///
/// ```dart
/// FossRating(
///   value: 4,
///   style: const FossRatingStyle(
///     filledColor: Color(0xFFF59E0B),
///     glyphSize: 28,
///   ),
/// );
/// ```
@immutable
@FossSince('0.1.3')
class FossRatingStyle {
  /// Creates a set of rating overrides. All fields default to null (inherit).
  const FossRatingStyle({
    this.filledColor,
    this.emptyColor,
    this.glyphSize,
    this.gap,
  });

  /// Color of a filled mark.
  final Color? filledColor;

  /// Color of an unfilled mark.
  final Color? emptyColor;

  /// Square extent of each mark in logical pixels.
  final double? glyphSize;

  /// Space between marks in logical pixels. Ignored on an interactive row,
  /// where the gap sits inside each mark's tap target.
  final double? gap;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossRatingStyle(glyphSize: 20, gap: 4);
  /// const override = FossRatingStyle(glyphSize: 28);
  /// base.merge(override); // gap 4 kept, glyphSize becomes 28
  /// ```
  FossRatingStyle merge(FossRatingStyle? other) {
    if (other == null) return this;
    return FossRatingStyle(
      filledColor: other.filledColor ?? filledColor,
      emptyColor: other.emptyColor ?? emptyColor,
      glyphSize: other.glyphSize ?? glyphSize,
      gap: other.gap ?? gap,
    );
  }
}
