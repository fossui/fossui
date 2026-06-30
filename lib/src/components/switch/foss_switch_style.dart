part of 'foss_switch.dart';

/// Visual overrides for a single switch. Every field is optional; a null field
/// falls back to the value the theme resolves. Pass one via `style:` to tweak a
/// one-off without changing the theme for every other switch.
///
/// The focus ring stays token-driven (the `ring` role); to restyle it globally,
/// retheme [FossColors].
///
/// A wider track with a custom on color:
///
/// ```dart
/// FossSwitch(
///   value: true,
///   style: const FossSwitchStyle(
///     trackWidth: 44,
///     activeTrackColor: Color(0xFF16A34A),
///   ),
/// );
/// ```
@immutable
class FossSwitchStyle {
  /// Creates a set of switch overrides. All fields default to null (inherit).
  const FossSwitchStyle({
    this.activeTrackColor,
    this.inactiveTrackColor,
    this.thumbColor,
    this.shadow,
    this.trackWidth,
    this.trackHeight,
    this.thumbSize,
  });

  /// Track fill when on.
  final Color? activeTrackColor;

  /// Track fill when off.
  final Color? inactiveTrackColor;

  /// Fill of the sliding thumb.
  final Color? thumbColor;

  /// Drop shadow layers under the thumb; empty for none.
  final List<BoxShadow>? shadow;

  /// Track width in logical pixels. The thumb travel is the inner width minus
  /// the thumb, so a wider track lengthens the travel.
  final double? trackWidth;

  /// Track height in logical pixels. The thumb inset is half the difference
  /// between this and [thumbSize].
  final double? trackHeight;

  /// Diameter of the thumb in logical pixels.
  final double? thumbSize;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossSwitchStyle(trackWidth: 38, thumbSize: 20);
  /// const override = FossSwitchStyle(thumbSize: 18);
  /// base.merge(override); // trackWidth 38 kept, thumbSize becomes 18
  /// ```
  FossSwitchStyle merge(FossSwitchStyle? other) {
    if (other == null) return this;
    return FossSwitchStyle(
      activeTrackColor: other.activeTrackColor ?? activeTrackColor,
      inactiveTrackColor: other.inactiveTrackColor ?? inactiveTrackColor,
      thumbColor: other.thumbColor ?? thumbColor,
      shadow: other.shadow ?? shadow,
      trackWidth: other.trackWidth ?? trackWidth,
      trackHeight: other.trackHeight ?? trackHeight,
      thumbSize: other.thumbSize ?? thumbSize,
    );
  }
}
