import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_calendar_painters.dart';
part 'foss_calendar_style.dart';

// Grid geometry, mobile base. The cell is the one fixed metric the widget
// bakes; everything else resolves to a token.
const double _cellSize = 40;
const int _columns = 7;

const double _chevronSize = 18;
const double _chevronOpacity = 0.80;
const double _todayDotSize = 3;

const double _disabledOpacity = 0.64;
const double _outsideOpacity = 0.72;
const double _ringOpacity = 0.50;
const double _todayDisabledOpacity = 0.30;
const double _ringWidth = 3;

// English labels. The package takes no localization dependency; a locale hook
// is a later addition. Weekday labels are indexed by [DateTime.weekday] minus 1
// (Monday first), so the header can rotate to any [firstDayOfWeek].
const List<String> _weekdayAbbr = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// An inclusive span of two calendar days, the value a [FossCalendar.range]
/// selects. Both ends compare by calendar day (year, month, day), so a
/// time-of-day component never splits a match.
///
/// While a range is being picked, the first tap yields a one-day range
/// ([start] equal to [end]); the second tap sets the far end.
///
/// ```dart
/// final week = FossDateRange(
///   start: DateTime(2026, 3, 2),
///   end: DateTime(2026, 3, 8),
/// );
/// ```
@FossSince('0.1.1')
@immutable
class FossDateRange {
  /// Creates a range from [start] to [end], inclusive.
  const FossDateRange({required this.start, required this.end});

  /// The first day of the span.
  final DateTime start;

  /// The last day of the span, inclusive.
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is FossDateRange &&
      _isSameDay(other.start, start) &&
      _isSameDay(other.end, end);

  @override
  int get hashCode => Object.hash(_dayKey(start), _dayKey(end));
}

enum _SelectionMode { single, multiple, range }

/// {@category Inputs}
/// {@template foss.calendar.preview}
/// <img src="https://fossui.org/components/calendar/overview/light.png"
///   alt="FossCalendar, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/calendar/overview/dark.png"
///   alt="FossCalendar, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [calendar documentation ↗](https://fossui.org/docs/components/calendar)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/calendar/fosscalendar/playground).
/// {@endtemplate}
///
/// A month grid for viewing and picking dates: a seven-column day grid under a
/// month caption with previous and next navigation.
///
/// Pick one of three selection modes with the named constructors, each typing
/// its value so the selection is never `dynamic`:
///
/// - [FossCalendar.single] highlights one day; tapping another moves it.
/// - [FossCalendar.multiple] toggles independent days in and out of a set.
/// - [FossCalendar.range] sets a [FossDateRange] over two taps.
///
/// Bound the grid with [minDate] and [maxDate], and disable individual days
/// with [isDateEnabled]; disabled days dim and stop responding. Own the
/// displayed month with [focusedMonth] and [onMonthChanged], or leave it to the
/// widget by seeding [initialMonth]. Colors, type, and radius come from
/// `context.fossTheme`; pass a [FossCalendarStyle] to [style] for a one-off.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossCalendar.single(
///   selected: picked,
///   onSelected: (day) => setState(() => picked = day),
/// );
/// ```
@FossSince('0.1.1')
class FossCalendar extends StatefulWidget {
  const FossCalendar._({
    required _SelectionMode mode,
    DateTime? singleSelected,
    ValueChanged<DateTime>? onSingle,
    Set<DateTime>? multipleSelected,
    ValueChanged<Set<DateTime>>? onMultiple,
    FossDateRange? rangeSelected,
    ValueChanged<FossDateRange>? onRange,
    this.initialMonth,
    this.focusedMonth,
    this.onMonthChanged,
    this.firstDayOfWeek = DateTime.monday,
    this.showOutsideDays = true,
    this.minDate,
    this.maxDate,
    this.isDateEnabled,
    this.semanticsLabel,
    this.style,
    super.key,
  }) : assert(
         focusedMonth == null || initialMonth == null,
         'Pass focusedMonth (controlled) or initialMonth (uncontrolled), '
         'not both.',
       ),
       assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday (1 to 7).',
       ),
       _mode = mode,
       _singleSelected = singleSelected,
       _onSingle = onSingle,
       _multipleSelected = multipleSelected,
       _onMultiple = onMultiple,
       _rangeSelected = rangeSelected,
       _onRange = onRange;

  /// {@macro foss.calendar.preview}
  ///
  /// Creates a single-day calendar. [selected] is the highlighted day (null for
  /// none); [onSelected] fires with the tapped day.
  ///
  /// ```dart
  /// FossCalendar.single(
  ///   selected: picked,
  ///   onSelected: (day) => setState(() => picked = day),
  /// );
  /// ```
  const FossCalendar.single({
    required DateTime? selected,
    required ValueChanged<DateTime> onSelected,
    DateTime? initialMonth,
    DateTime? focusedMonth,
    ValueChanged<DateTime>? onMonthChanged,
    int firstDayOfWeek = DateTime.monday,
    bool showOutsideDays = true,
    DateTime? minDate,
    DateTime? maxDate,
    bool Function(DateTime)? isDateEnabled,
    String? semanticsLabel,
    FossCalendarStyle? style,
    Key? key,
  }) : this._(
         mode: _SelectionMode.single,
         singleSelected: selected,
         onSingle: onSelected,
         initialMonth: initialMonth,
         focusedMonth: focusedMonth,
         onMonthChanged: onMonthChanged,
         firstDayOfWeek: firstDayOfWeek,
         showOutsideDays: showOutsideDays,
         minDate: minDate,
         maxDate: maxDate,
         isDateEnabled: isDateEnabled,
         semanticsLabel: semanticsLabel,
         style: style,
         key: key,
       );

  /// Creates a multi-day calendar. [selected] is the set of highlighted days;
  /// [onSelected] fires with the next set as each day toggles.
  ///
  /// ```dart
  /// FossCalendar.multiple(
  ///   selected: picked,
  ///   onSelected: (days) => setState(() => picked = days),
  /// );
  /// ```
  const FossCalendar.multiple({
    required Set<DateTime> selected,
    required ValueChanged<Set<DateTime>> onSelected,
    DateTime? initialMonth,
    DateTime? focusedMonth,
    ValueChanged<DateTime>? onMonthChanged,
    int firstDayOfWeek = DateTime.monday,
    bool showOutsideDays = true,
    DateTime? minDate,
    DateTime? maxDate,
    bool Function(DateTime)? isDateEnabled,
    String? semanticsLabel,
    FossCalendarStyle? style,
    Key? key,
  }) : this._(
         mode: _SelectionMode.multiple,
         multipleSelected: selected,
         onMultiple: onSelected,
         initialMonth: initialMonth,
         focusedMonth: focusedMonth,
         onMonthChanged: onMonthChanged,
         firstDayOfWeek: firstDayOfWeek,
         showOutsideDays: showOutsideDays,
         minDate: minDate,
         maxDate: maxDate,
         isDateEnabled: isDateEnabled,
         semanticsLabel: semanticsLabel,
         style: style,
         key: key,
       );

  /// Creates a range calendar. [selected] is the chosen span (null for none);
  /// [onSelected] fires as the range is set over two taps.
  ///
  /// ```dart
  /// FossCalendar.range(
  ///   selected: picked,
  ///   onSelected: (range) => setState(() => picked = range),
  /// );
  /// ```
  const FossCalendar.range({
    required FossDateRange? selected,
    required ValueChanged<FossDateRange> onSelected,
    DateTime? initialMonth,
    DateTime? focusedMonth,
    ValueChanged<DateTime>? onMonthChanged,
    int firstDayOfWeek = DateTime.monday,
    bool showOutsideDays = true,
    DateTime? minDate,
    DateTime? maxDate,
    bool Function(DateTime)? isDateEnabled,
    String? semanticsLabel,
    FossCalendarStyle? style,
    Key? key,
  }) : this._(
         mode: _SelectionMode.range,
         rangeSelected: selected,
         onRange: onSelected,
         initialMonth: initialMonth,
         focusedMonth: focusedMonth,
         onMonthChanged: onMonthChanged,
         firstDayOfWeek: firstDayOfWeek,
         showOutsideDays: showOutsideDays,
         minDate: minDate,
         maxDate: maxDate,
         isDateEnabled: isDateEnabled,
         semanticsLabel: semanticsLabel,
         style: style,
         key: key,
       );

  final _SelectionMode _mode;
  final DateTime? _singleSelected;
  final ValueChanged<DateTime>? _onSingle;
  final Set<DateTime>? _multipleSelected;
  final ValueChanged<Set<DateTime>>? _onMultiple;
  final FossDateRange? _rangeSelected;
  final ValueChanged<FossDateRange>? _onRange;

  /// The month shown first when uncontrolled ([focusedMonth] is null). Defaults
  /// to the month of the selection, else the current month.
  final DateTime? initialMonth;

  /// The displayed month when controlled. Pass with [onMonthChanged] to own
  /// navigation; leave null to let the widget hold the month.
  final DateTime? focusedMonth;

  /// Called with the first day of the next month when navigation steps.
  final ValueChanged<DateTime>? onMonthChanged;

  /// The leading weekday column, as a [DateTime] weekday (1 = Monday). Defaults
  /// to [DateTime.monday].
  final int firstDayOfWeek;

  /// Whether adjacent-month days fill the leading and trailing grid cells.
  /// Defaults to true.
  final bool showOutsideDays;

  /// The earliest selectable and navigable day, inclusive. Null for no lower
  /// bound.
  final DateTime? minDate;

  /// The latest selectable and navigable day, inclusive. Null for no upper
  /// bound.
  final DateTime? maxDate;

  /// Disables individual days on top of [minDate] and [maxDate]. Returns false
  /// to disable the given day.
  final bool Function(DateTime)? isDateEnabled;

  /// Accessibility label for the grid as a whole.
  final String? semanticsLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossCalendarStyle? style;

  @override
  State<FossCalendar> createState() => _FossCalendarState();
}

class _FossCalendarState extends State<FossCalendar> {
  final FocusNode _gridFocus = FocusNode(debugLabel: 'FossCalendar grid');

  late DateTime _internalMonth;
  DateTime? _focusedDay;
  DateTime? _hoveredDay;
  DateTime? _rangeAnchor;
  bool _showRing = false;

  DateTime get _month => _firstOfMonth(widget.focusedMonth ?? _internalMonth);

  @override
  void initState() {
    super.initState();
    final seed =
        widget.focusedMonth ??
        widget.initialMonth ??
        _selectionMonth() ??
        DateTime.now();
    _internalMonth = _clampMonth(_firstOfMonth(seed));
  }

  @override
  void dispose() {
    _gridFocus.dispose();
    super.dispose();
  }

  DateTime? _selectionMonth() => switch (widget._mode) {
    _SelectionMode.single => widget._singleSelected,
    _SelectionMode.multiple =>
      widget._multipleSelected?.isEmpty ?? true
          ? null
          : widget._multipleSelected?.first,
    _SelectionMode.range => widget._rangeSelected?.start,
  };

  DateTime get _today => _dayOnly(DateTime.now());

  bool _isSelectable(DateTime day) {
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && day.isBefore(_dayOnly(min))) return false;
    if (max != null && day.isAfter(_dayOnly(max))) return false;
    return widget.isDateEnabled?.call(day) ?? true;
  }

  DateTime _clampMonth(DateTime month) {
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && month.isBefore(_firstOfMonth(min))) {
      return _firstOfMonth(min);
    }
    if (max != null && month.isAfter(_firstOfMonth(max))) {
      return _firstOfMonth(max);
    }
    return month;
  }

  bool get _canStepBack {
    final min = widget.minDate;
    return min == null || _month.isAfter(_firstOfMonth(min));
  }

  bool get _canStepForward {
    final max = widget.maxDate;
    return max == null || _month.isBefore(_firstOfMonth(max));
  }

  void _step(int months) {
    final target = _clampMonth(DateTime(_month.year, _month.month + months));
    if (target == _month) return;
    widget.onMonthChanged?.call(target);
    if (widget.focusedMonth == null) setState(() => _internalMonth = target);
  }

  // Moves the displayed month so [day] is visible, then points the roving focus
  // at it. Used by the keyboard grid when an arrow crosses a month edge.
  void _focusDay(DateTime day) {
    final clamped = _clampToBounds(day);
    final targetMonth = _firstOfMonth(clamped);
    setState(() => _focusedDay = clamped);
    if (targetMonth != _month) {
      widget.onMonthChanged?.call(targetMonth);
      if (widget.focusedMonth == null) _internalMonth = targetMonth;
    }
  }

  DateTime _clampToBounds(DateTime day) {
    final min = widget.minDate;
    final max = widget.maxDate;
    if (min != null && day.isBefore(_dayOnly(min))) return _dayOnly(min);
    if (max != null && day.isAfter(_dayOnly(max))) return _dayOnly(max);
    return day;
  }

  void _handleTap(DateTime day) {
    final d = _dayOnly(day);
    if (!_isSelectable(d)) return;
    setState(() => _focusedDay = d);
    _gridFocus.requestFocus();
    switch (widget._mode) {
      case _SelectionMode.single:
        widget._onSingle?.call(d);
      case _SelectionMode.multiple:
        final next = {
          for (final s in widget._multipleSelected ?? const <DateTime>{})
            _dayOnly(s),
        };
        if (!next.add(d)) next.remove(d);
        widget._onMultiple?.call(next);
      case _SelectionMode.range:
        _handleRangeTap(d);
    }
  }

  void _handleRangeTap(DateTime day) {
    final anchor = _rangeAnchor;
    if (anchor == null) {
      setState(() => _rangeAnchor = day);
      widget._onRange?.call(FossDateRange(start: day, end: day));
    } else {
      final start = anchor.isAfter(day) ? day : anchor;
      final end = anchor.isAfter(day) ? anchor : day;
      setState(() => _rangeAnchor = null);
      widget._onRange?.call(FossDateRange(start: start, end: end));
    }
  }

  DateTime _defaultFocusDay() {
    final selection = _selectionMonth();
    if (selection != null && _firstOfMonth(selection) == _month) {
      return _dayOnly(selection);
    }
    if (_firstOfMonth(_today) == _month) return _today;
    return _clampToBounds(_month);
  }

  void _moveFocusBy(int days) {
    final from = _focusedDay ?? _defaultFocusDay();
    _focusDay(DateTime(from.year, from.month, from.day + days));
  }

  void _moveFocusToWeekEdge({required bool end}) {
    final from = _focusedDay ?? _defaultFocusDay();
    final offset = _leadingOffset(from, widget.firstDayOfWeek);
    final start = DateTime(from.year, from.month, from.day - offset);
    _focusDay(end ? DateTime(start.year, start.month, start.day + 6) : start);
  }

  void _moveFocusByMonth(int months) {
    final from = _focusedDay ?? _defaultFocusDay();
    final targetMonth = DateTime(from.year, from.month + months);
    final dim = _daysInMonth(targetMonth);
    final day = from.day < dim ? from.day : dim;
    _focusDay(DateTime(targetMonth.year, targetMonth.month, day));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final visuals = _resolve(theme, widget.style);
    final ltr = Directionality.of(context) == TextDirection.ltr;

    return FocusableActionDetector(
      focusNode: _gridFocus,
      onShowFocusHighlight: (value) {
        setState(() {
          _showRing = value;
          if (value) _focusedDay ??= _defaultFocusDay();
        });
      },
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.arrowRight): _MoveDaysIntent(
          ltr ? 1 : -1,
        ),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveDaysIntent(
          ltr ? -1 : 1,
        ),
        const SingleActivator(
          LogicalKeyboardKey.arrowDown,
        ): const _MoveDaysIntent(
          _columns,
        ),
        const SingleActivator(
          LogicalKeyboardKey.arrowUp,
        ): const _MoveDaysIntent(
          -_columns,
        ),
        const SingleActivator(LogicalKeyboardKey.home): const _WeekEdgeIntent(
          end: false,
        ),
        const SingleActivator(LogicalKeyboardKey.end): const _WeekEdgeIntent(
          end: true,
        ),
        const SingleActivator(
          LogicalKeyboardKey.pageUp,
        ): const _MoveMonthsIntent(
          -1,
        ),
        const SingleActivator(LogicalKeyboardKey.pageDown):
            const _MoveMonthsIntent(1),
      },
      actions: <Type, Action<Intent>>{
        _MoveDaysIntent: CallbackAction<_MoveDaysIntent>(
          onInvoke: (intent) {
            _moveFocusBy(intent.days);
            return null;
          },
        ),
        _WeekEdgeIntent: CallbackAction<_WeekEdgeIntent>(
          onInvoke: (intent) {
            _moveFocusToWeekEdge(end: intent.end);
            return null;
          },
        ),
        _MoveMonthsIntent: CallbackAction<_MoveMonthsIntent>(
          onInvoke: (intent) {
            _moveFocusByMonth(intent.months);
            return null;
          },
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            final day = _focusedDay;
            if (day != null) _handleTap(day);
            return null;
          },
        ),
      },
      child: Semantics(
        container: true,
        label: widget.semanticsLabel,
        // Size to the grid width so the caption arrows align with the day
        // columns instead of stretching. Align passes loose constraints to the
        // fixed-width child, so the grid width holds even when the parent
        // forces a wider tight width (a full-width list, say); widthFactor
        // keeps the calendar shrink-wrapped when the parent leaves it loose.
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          child: SizedBox(
            width: _columns * visuals.cellSize,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _caption(theme, visuals, ltr),
                _weekdayHeader(visuals),
                _grid(visuals),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _caption(FossThemeData theme, _CalendarVisuals v, bool ltr) {
    final title = '${_monthNames[_month.month - 1]} ${_month.year}';
    return SizedBox(
      height: v.cellSize,
      child: Row(
        children: <Widget>[
          _NavButton(
            pointsLeft: ltr,
            color: v.chevronColor,
            ringColor: v.ringColor,
            size: v.cellSize,
            enabled: _canStepBack,
            semanticLabel: 'Previous month',
            onTap: () => _step(-1),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: v.captionStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _NavButton(
            pointsLeft: !ltr,
            color: v.chevronColor,
            ringColor: v.ringColor,
            size: v.cellSize,
            enabled: _canStepForward,
            semanticLabel: 'Next month',
            onTap: () => _step(1),
          ),
        ],
      ),
    );
  }

  Widget _weekdayHeader(_CalendarVisuals v) {
    return Row(
      children: <Widget>[
        for (var i = 0; i < _columns; i++)
          SizedBox(
            width: v.cellSize,
            child: Center(
              child: Text(
                _weekdayAbbr[(widget.firstDayOfWeek - 1 + i) % _columns],
                style: v.weekdayStyle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _grid(_CalendarVisuals v) {
    final days = _gridDays(_month, widget.firstDayOfWeek);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var row = 0; row < days.length ~/ _columns; row++)
          Row(
            children: <Widget>[
              for (var col = 0; col < _columns; col++)
                _dayCell(v, days[row * _columns + col]),
            ],
          ),
      ],
    );
  }

  Widget _dayCell(_CalendarVisuals v, DateTime day) {
    final outside = day.month != _month.month || day.year != _month.year;
    if (outside && !widget.showOutsideDays) {
      return SizedBox.square(dimension: v.cellSize);
    }

    final selectable = _isSelectable(day);
    final today = _isSameDay(day, _today);
    final fill = _fillState(day);
    final focused =
        _showRing && _focusedDay != null && _isSameDay(day, _focusedDay!);
    final hovered = _hoveredDay != null && _isSameDay(day, _hoveredDay!);

    final Color background;
    final Color foreground;
    final BorderRadiusGeometry radius;
    switch (fill) {
      case _DayFill.selected:
        background = v.selectedFill;
        foreground = v.selectedForeground;
        radius = BorderRadius.circular(v.dayRadius);
      case _DayFill.rangeStart:
        background = v.selectedFill;
        foreground = v.selectedForeground;
        radius = BorderRadiusDirectional.horizontal(
          start: Radius.circular(v.dayRadius),
        );
      case _DayFill.rangeEnd:
        background = v.selectedFill;
        foreground = v.selectedForeground;
        radius = BorderRadiusDirectional.horizontal(
          end: Radius.circular(v.dayRadius),
        );
      case _DayFill.rangeMiddle:
        background = v.rangeFill;
        foreground = v.foreground;
        radius = BorderRadius.zero;
      case _DayFill.none:
        background = hovered && selectable
            ? v.hoverFill
            : const Color(0x00000000);
        foreground = outside || !selectable ? v.mutedForeground : v.foreground;
        radius = BorderRadius.circular(v.dayRadius);
    }

    final dotColor = switch (fill) {
      _DayFill.none when !selectable => v.foreground.withValues(
        alpha: _todayDisabledOpacity,
      ),
      _DayFill.none => v.todayDotColor,
      _ => v.selectedTodayDotColor,
    };

    final Widget label = Text(
      '${day.day}',
      style: v.dayStyle.copyWith(
        color: foreground,
        decoration: selectable ? null : TextDecoration.lineThrough,
      ),
    );

    Widget content = DecoratedBox(
      decoration: ShapeDecoration(
        color: background,
        shape: RoundedSuperellipseBorder(borderRadius: radius),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          label,
          if (today)
            Positioned(
              bottom: v.cellSize * 0.14,
              child: _TodayDot(color: dotColor),
            ),
        ],
      ),
    );

    if (focused) {
      content = CustomPaint(
        foregroundPainter: _DayRingPainter(
          color: v.ringColor,
          radius: v.dayRadius,
        ),
        child: content,
      );
    }

    if (!selectable) {
      content = Opacity(opacity: _disabledOpacity, child: content);
    }

    return MouseRegion(
      onEnter: selectable ? (_) => setState(() => _hoveredDay = day) : null,
      onExit: selectable
          ? (_) {
              if (_hoveredDay != null && _isSameDay(_hoveredDay!, day)) {
                setState(() => _hoveredDay = null);
              }
            }
          : null,
      child: Semantics(
        button: true,
        selected: fill != _DayFill.none,
        enabled: selectable,
        label: _dayLabel(day, today: today),
        // The gesture is excluded from semantics, so the tap action lives on
        // the node itself for screen-reader activation.
        onTap: selectable ? () => _handleTap(day) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: selectable ? () => _handleTap(day) : null,
          child: ExcludeSemantics(
            child: SizedBox.square(dimension: v.cellSize, child: content),
          ),
        ),
      ),
    );
  }

  String _dayLabel(DateTime day, {required bool today}) {
    final base = '${_monthNames[day.month - 1]} ${day.day}, ${day.year}';
    return today ? '$base, today' : base;
  }

  _DayFill _fillState(DateTime day) {
    switch (widget._mode) {
      case _SelectionMode.single:
        final selected = widget._singleSelected;
        return selected != null && _isSameDay(day, selected)
            ? _DayFill.selected
            : _DayFill.none;
      case _SelectionMode.multiple:
        for (final s in widget._multipleSelected ?? const <DateTime>{}) {
          if (_isSameDay(day, s)) return _DayFill.selected;
        }
        return _DayFill.none;
      case _SelectionMode.range:
        final range = widget._rangeSelected;
        if (range == null) return _DayFill.none;
        final start = _dayOnly(range.start);
        final end = _dayOnly(range.end);
        if (_isSameDay(day, start) && _isSameDay(day, end)) {
          return _DayFill.selected;
        }
        if (_isSameDay(day, start)) return _DayFill.rangeStart;
        if (_isSameDay(day, end)) return _DayFill.rangeEnd;
        if (day.isAfter(start) && day.isBefore(end)) {
          return _DayFill.rangeMiddle;
        }
        return _DayFill.none;
    }
  }
}

/// The painted fill a day cell resolves to.
enum _DayFill { none, selected, rangeStart, rangeMiddle, rangeEnd }

/// Moves the roving day focus by [days], wrapping across month edges.
class _MoveDaysIntent extends Intent {
  const _MoveDaysIntent(this.days);

  final int days;
}

/// Moves the roving day focus to the first or last day of its week row.
class _WeekEdgeIntent extends Intent {
  const _WeekEdgeIntent({required this.end});

  final bool end;
}

/// Moves the roving day focus by [months], keeping the day of month.
class _MoveMonthsIntent extends Intent {
  const _MoveMonthsIntent(this.months);

  final int months;
}

/// The bottom-center today marker: a small filled dot.
class _TodayDot extends StatelessWidget {
  const _TodayDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: _todayDotSize,
    height: _todayDotSize,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// A ghost navigation button (previous / next month) with a painted chevron and
/// a focus ring. Disabled at the bound.
class _NavButton extends StatefulWidget {
  const _NavButton({
    required this.pointsLeft,
    required this.color,
    required this.ringColor,
    required this.size,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });

  final bool pointsLeft;
  final Color color;
  final Color ringColor;
  final double size;
  final bool enabled;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    Widget content = CustomPaint(
      size: const Size.square(_chevronSize),
      painter: _ChevronPainter(
        color: widget.color,
        pointsLeft: widget.pointsLeft,
      ),
    );

    if (_focused) {
      content = CustomPaint(
        foregroundPainter: _DayRingPainter(
          color: widget.ringColor,
          radius: _chevronSize / 2,
        ),
        child: SizedBox.square(
          dimension: widget.size,
          child: Center(child: content),
        ),
      );
    } else {
      content = SizedBox.square(
        dimension: widget.size,
        child: Center(child: content),
      );
    }

    if (!widget.enabled) {
      content = Opacity(opacity: _disabledOpacity, child: content);
    }

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      onTap: widget.enabled ? widget.onTap : null,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: widget.enabled ? widget.onTap : null,
          child: content,
        ),
      ),
    );
  }
}

/// Builds the default appearance from the theme tokens, then lays a
/// per-instance [override] over it field by field.
_CalendarVisuals _resolve(FossThemeData theme, FossCalendarStyle? override) {
  final c = theme.colors;
  final t = theme.typography;
  final muted = c.mutedForeground.withValues(alpha: _outsideOpacity);
  return _CalendarVisuals(
    dayStyle: override?.dayTextStyle ?? t.base.copyWith(color: c.foreground),
    weekdayStyle:
        override?.weekdayTextStyle ?? t.xs.medium.copyWith(color: muted),
    captionStyle:
        override?.captionTextStyle ??
        t.base.medium.copyWith(color: c.foreground),
    foreground: override?.dayForegroundColor ?? c.foreground,
    mutedForeground: override?.mutedForegroundColor ?? muted,
    selectedFill: override?.selectedColor ?? c.primary,
    selectedForeground:
        override?.selectedForegroundColor ?? c.primaryForeground,
    rangeFill: override?.rangeColor ?? c.accent,
    hoverFill: override?.hoverColor ?? c.accent,
    todayDotColor: override?.todayIndicatorColor ?? c.primary,
    selectedTodayDotColor:
        override?.selectedTodayIndicatorColor ?? c.background,
    ringColor:
        override?.focusRingColor ?? c.ring.withValues(alpha: _ringOpacity),
    chevronColor:
        override?.chevronColor ??
        c.foreground.withValues(alpha: _chevronOpacity),
    dayRadius: override?.dayRadius ?? theme.radii.lg,
    cellSize: override?.cellSize ?? _cellSize,
  );
}

/// The fully resolved, non-null appearance for the calendar. A
/// [FossCalendarStyle] override is laid over it by [_resolve], so the widget
/// reads only non-null fields.
@immutable
class _CalendarVisuals {
  const _CalendarVisuals({
    required this.dayStyle,
    required this.weekdayStyle,
    required this.captionStyle,
    required this.foreground,
    required this.mutedForeground,
    required this.selectedFill,
    required this.selectedForeground,
    required this.rangeFill,
    required this.hoverFill,
    required this.todayDotColor,
    required this.selectedTodayDotColor,
    required this.ringColor,
    required this.chevronColor,
    required this.dayRadius,
    required this.cellSize,
  });

  final TextStyle dayStyle;
  final TextStyle weekdayStyle;
  final TextStyle captionStyle;
  final Color foreground;
  final Color mutedForeground;
  final Color selectedFill;
  final Color selectedForeground;
  final Color rangeFill;
  final Color hoverFill;
  final Color todayDotColor;
  final Color selectedTodayDotColor;
  final Color ringColor;
  final Color chevronColor;
  final double dayRadius;
  final double cellSize;
}

// Month math. Pure helpers over calendar days, shared by the state and tested
// through the rendered grid.

DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _firstOfMonth(DateTime d) => DateTime(d.year, d.month);

int _daysInMonth(DateTime month) =>
    DateTime(month.year, month.month + 1, 0).day;

int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// Days from [firstDayOfWeek] back to the week start containing [day].
int _leadingOffset(DateTime day, int firstDayOfWeek) =>
    (day.weekday - firstDayOfWeek + _columns) % _columns;

// The grid days for [month]: the weeks it spans (four to six rows of seven),
// padded at the ends with adjacent-month days so every row is full.
List<DateTime> _gridDays(DateTime month, int firstDayOfWeek) {
  final first = _firstOfMonth(month);
  final lead = _leadingOffset(first, firstDayOfWeek);
  final total = lead + _daysInMonth(month);
  final rows = (total + _columns - 1) ~/ _columns;
  final start = DateTime(first.year, first.month, first.day - lead);
  return <DateTime>[
    for (var i = 0; i < rows * _columns; i++)
      DateTime(start.year, start.month, start.day + i),
  ];
}
