part of 'foss_time_picker.dart';

/// Visual overrides for a single [FossTimePicker]. Every field is optional; a
/// null field falls back to the value the theme resolves. Pass one via `style:`
/// to tweak a one-off without retheming.
///
/// [placeholderColor] and [gap] mirror `FossDatePickerStyle` so the two field
/// triggers restyle together; the rest tune the wheels inside the modal. The
/// dialog surface and the footer buttons restyle through the theme or their own
/// styles, not through here.
///
/// ```dart
/// FossTimePicker(
///   value: picked,
///   onChanged: (time) => setState(() => picked = time),
///   style: const FossTimePickerStyle(visibleItemCount: 3),
/// );
/// ```
@FossSince('0.1.2')
@immutable
class FossTimePickerStyle {
  /// Creates a set of overrides. All fields default to null (inherit).
  ///
  /// [visibleItemCount] must be odd and at least 3, so a single row sits in the
  /// centre band with the same number of neighbours above and below.
  const FossTimePickerStyle({
    this.placeholderColor,
    this.gap,
    this.itemExtent,
    this.visibleItemCount,
    this.highlightColor,
  }) : assert(
         itemExtent == null || itemExtent > 0,
         'itemExtent must be positive.',
       ),
       assert(
         visibleItemCount == null ||
             (visibleItemCount >= 3 && visibleItemCount % 2 == 1),
         'visibleItemCount must be an odd number of 3 or more.',
       );

  /// Color of the placeholder label shown while nothing is selected.
  final Color? placeholderColor;

  /// Gap between the leading clock glyph and the trigger label, in logical
  /// pixels.
  final double? gap;

  /// Height of one wheel row in logical pixels, before text scaling. Defaults
  /// to 36, the trigger height, so the field and the sheet share one rhythm.
  final double? itemExtent;

  /// How many rows a wheel shows at once. Odd, 3 or more; defaults to 5.
  final int? visibleItemCount;

  /// Fill of the centre band behind the selected row. Defaults to the accent
  /// role.
  final Color? highlightColor;

  /// Returns a copy with every non-null field of [other] laid over this one.
  FossTimePickerStyle merge(FossTimePickerStyle? other) {
    if (other == null) return this;
    return FossTimePickerStyle(
      placeholderColor: other.placeholderColor ?? placeholderColor,
      gap: other.gap ?? gap,
      itemExtent: other.itemExtent ?? itemExtent,
      visibleItemCount: other.visibleItemCount ?? visibleItemCount,
      highlightColor: other.highlightColor ?? highlightColor,
    );
  }
}
