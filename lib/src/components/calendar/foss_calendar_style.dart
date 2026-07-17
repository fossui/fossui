part of 'foss_calendar.dart';

/// Visual overrides for a [FossCalendar]. Every field is optional; a null field
/// falls back to the value the theme resolves. Pass one via `style:` to tweak a
/// single calendar without retheming every other one.
///
/// A softer selected fill and tighter day corners:
///
/// ```dart
/// FossCalendar.single(
///   selected: picked,
///   onSelected: onPick,
///   style: const FossCalendarStyle(
///     selectedColor: Color(0xFF6D28D9),
///     dayRadius: 6,
///   ),
/// );
/// ```
@FossSince('0.1.1')
@immutable
class FossCalendarStyle {
  /// Creates a set of calendar overrides. All fields default to null (inherit).
  const FossCalendarStyle({
    this.dayTextStyle,
    this.weekdayTextStyle,
    this.captionTextStyle,
    this.dayForegroundColor,
    this.mutedForegroundColor,
    this.selectedColor,
    this.selectedForegroundColor,
    this.rangeColor,
    this.hoverColor,
    this.todayIndicatorColor,
    this.selectedTodayIndicatorColor,
    this.focusRingColor,
    this.chevronColor,
    this.dayRadius,
    this.cellSize,
  });

  /// Text style for the day numbers.
  final TextStyle? dayTextStyle;

  /// Text style for the weekday header labels.
  final TextStyle? weekdayTextStyle;

  /// Text style for the month and year caption.
  final TextStyle? captionTextStyle;

  /// Color of an ordinary day number.
  final Color? dayForegroundColor;

  /// Color of outside-month and disabled day numbers, and the weekday header.
  final Color? mutedForegroundColor;

  /// Fill of a selected day and the range edges.
  final Color? selectedColor;

  /// Number color on a selected day and the range edges.
  final Color? selectedForegroundColor;

  /// Fill of the days between the range edges.
  final Color? rangeColor;

  /// Fill of a day under the pointer.
  final Color? hoverColor;

  /// Color of the today dot.
  final Color? todayIndicatorColor;

  /// Color of the today dot when today is selected.
  final Color? selectedTodayIndicatorColor;

  /// Color of the keyboard focus ring.
  final Color? focusRingColor;

  /// Color of the navigation chevrons.
  final Color? chevronColor;

  /// Corner radius of a day cell in logical pixels.
  final double? dayRadius;

  /// Edge length of a day cell in logical pixels.
  final double? cellSize;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossCalendarStyle(dayRadius: 10);
  /// const override = FossCalendarStyle(dayRadius: 6);
  /// base.merge(override); // dayRadius becomes 6
  /// ```
  FossCalendarStyle merge(FossCalendarStyle? other) {
    if (other == null) return this;
    return FossCalendarStyle(
      dayTextStyle: other.dayTextStyle ?? dayTextStyle,
      weekdayTextStyle: other.weekdayTextStyle ?? weekdayTextStyle,
      captionTextStyle: other.captionTextStyle ?? captionTextStyle,
      dayForegroundColor: other.dayForegroundColor ?? dayForegroundColor,
      mutedForegroundColor: other.mutedForegroundColor ?? mutedForegroundColor,
      selectedColor: other.selectedColor ?? selectedColor,
      selectedForegroundColor:
          other.selectedForegroundColor ?? selectedForegroundColor,
      rangeColor: other.rangeColor ?? rangeColor,
      hoverColor: other.hoverColor ?? hoverColor,
      todayIndicatorColor: other.todayIndicatorColor ?? todayIndicatorColor,
      selectedTodayIndicatorColor:
          other.selectedTodayIndicatorColor ?? selectedTodayIndicatorColor,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      chevronColor: other.chevronColor ?? chevronColor,
      dayRadius: other.dayRadius ?? dayRadius,
      cellSize: other.cellSize ?? cellSize,
    );
  }
}
