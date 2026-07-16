part of 'foss_meter.dart';

/// Visual overrides for a single [FossMeter]. Every field is optional; a null
/// field falls back to the value the theme resolves. Pass one via `style:` to
/// tweak a one-off without changing the theme for every other gauge.
///
/// ```dart
/// FossMeter(
///   value: 40,
///   style: const FossMeterStyle(fillColor: Color(0xFF16A34A)),
/// );
/// ```
@FossSince('0.1.1')
@immutable
class FossMeterStyle {
  /// Creates a set of meter overrides. All fields default to null (inherit).
  const FossMeterStyle({
    this.trackColor,
    this.fillColor,
    this.labelStyle,
    this.valueStyle,
  });

  /// Fill of the unfilled track.
  final Color? trackColor;

  /// Fill of the leading gauge band.
  final Color? fillColor;

  /// Style of the [FossMeter.label]. Merged over the token default.
  final TextStyle? labelStyle;

  /// Style of the value text. Merged over the token default.
  final TextStyle? valueStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossMeterStyle merge(FossMeterStyle? other) {
    if (other == null) return this;
    return FossMeterStyle(
      trackColor: other.trackColor ?? trackColor,
      fillColor: other.fillColor ?? fillColor,
      labelStyle: other.labelStyle ?? labelStyle,
      valueStyle: other.valueStyle ?? valueStyle,
    );
  }
}
