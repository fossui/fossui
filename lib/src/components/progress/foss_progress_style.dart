part of 'foss_progress.dart';

/// Visual overrides for a single [FossProgress]. Every field is optional; a
/// null field falls back to the value the theme resolves. Pass one via `style:`
/// to tweak a one-off without changing the theme for every other bar.
///
/// ```dart
/// FossProgress(
///   value: 0.4,
///   style: const FossProgressStyle(fillColor: Color(0xFF16A34A)),
/// );
/// ```
@immutable
class FossProgressStyle {
  /// Creates a set of progress overrides. All fields default to null (inherit).
  const FossProgressStyle({
    this.trackColor,
    this.fillColor,
    this.labelStyle,
    this.valueLabelStyle,
  });

  /// Fill of the unfilled track.
  final Color? trackColor;

  /// Fill of the leading progress band.
  final Color? fillColor;

  /// Style of the [FossProgress.label]. Merged over the token default.
  final TextStyle? labelStyle;

  /// Style of the [FossProgress.valueLabel]. Merged over the token default.
  final TextStyle? valueLabelStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossProgressStyle merge(FossProgressStyle? other) {
    if (other == null) return this;
    return FossProgressStyle(
      trackColor: other.trackColor ?? trackColor,
      fillColor: other.fillColor ?? fillColor,
      labelStyle: other.labelStyle ?? labelStyle,
      valueLabelStyle: other.valueLabelStyle ?? valueLabelStyle,
    );
  }
}
