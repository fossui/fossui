part of 'foss_slider.dart';

/// Visual overrides for a single [FossSlider]. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other slider.
///
/// State-derived colors (the focus ring) stay token-driven. To restyle those
/// globally, retheme `FossColors`.
///
/// A taller track with a custom filled range:
///
/// ```dart
/// FossSlider(
///   value: 40,
///   onChanged: (v) {},
///   style: const FossSliderStyle(
///     trackHeight: 6,
///     rangeColor: Color(0xFF8A38F5),
///   ),
/// );
/// ```
@immutable
class FossSliderStyle {
  /// Creates a set of slider overrides. All fields default to null (inherit).
  const FossSliderStyle({
    this.trackColor,
    this.rangeColor,
    this.thumbColor,
    this.borderColor,
    this.shadow,
    this.trackHeight,
    this.thumbSize,
  });

  /// Color of the unfilled track.
  final Color? trackColor;

  /// Color of the filled range from the start to the thumb.
  final Color? rangeColor;

  /// Fill color of the thumb knob.
  final Color? thumbColor;

  /// Border color of the thumb.
  final Color? borderColor;

  /// Drop shadow layers on the resting thumb; empty for none.
  final List<BoxShadow>? shadow;

  /// Height of the track in logical pixels.
  final double? trackHeight;

  /// Diameter of the thumb in logical pixels.
  final double? thumbSize;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossSliderStyle(trackHeight: 4, thumbSize: 20);
  /// const override = FossSliderStyle(thumbSize: 24);
  /// base.merge(override); // trackHeight 4 kept, thumbSize becomes 24
  /// ```
  FossSliderStyle merge(FossSliderStyle? other) {
    if (other == null) return this;
    return FossSliderStyle(
      trackColor: other.trackColor ?? trackColor,
      rangeColor: other.rangeColor ?? rangeColor,
      thumbColor: other.thumbColor ?? thumbColor,
      borderColor: other.borderColor ?? borderColor,
      shadow: other.shadow ?? shadow,
      trackHeight: other.trackHeight ?? trackHeight,
      thumbSize: other.thumbSize ?? thumbSize,
    );
  }
}
