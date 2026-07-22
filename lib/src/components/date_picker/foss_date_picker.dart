import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/calendar/foss_calendar.dart';
import 'package:fossui/src/components/dialog/foss_dialog.dart';
import 'package:fossui/src/foundation/foss_dialog_surface.dart'
    show FossDialogPresentation;
import 'package:fossui/src/foundation/foss_field_box.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_date_picker_style.dart';

const double _glyphSize = 16;
const double _triggerMinHeight = 36;
const double _darkFillOpacity = 0.32;

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

/// Which selection shape the picker holds, and how its label formats.
enum _DatePickerMode { single, range }

/// The built-in single-date label: month name, ordinal day, and year, as in
/// `March 6th, 2026`.
String _defaultSingleFormat(DateTime date) =>
    '${_monthNames[date.month - 1]} ${_ordinalDay(date.day)}, ${date.year}';

/// The built-in range label: each end formatted as `Jul 09, 2026`, joined by a
/// dash. Collapses to a single end while the span covers one day.
String _defaultRangeFormat(FossDateRange range) {
  final start = _formatCompactDay(range.start);
  if (_isSameDay(range.start, range.end)) return start;
  return '$start - ${_formatCompactDay(range.end)}';
}

String _formatCompactDay(DateTime date) {
  final month = _monthNames[date.month - 1].substring(0, 3);
  final day = date.day.toString().padLeft(2, '0');
  return '$month $day, ${date.year}';
}

String _ordinalDay(int day) {
  final suffix = day >= 11 && day <= 13
      ? 'th'
      : switch (day % 10) {
          1 => 'st',
          2 => 'nd',
          3 => 'rd',
          _ => 'th',
        };
  return '$day$suffix';
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// {@category Inputs}
/// {@template foss.date_picker.preview}
/// <img src="https://fossui.org/components/date_picker/overview/light.png"
///   alt="FossDatePicker, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/date_picker/overview/dark.png"
///   alt="FossDatePicker, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [date picker documentation ↗](https://fossui.org/docs/components/date-picker)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/date_picker/fossdatepicker/playground).
/// {@endtemplate}
///
/// A date field that opens a calendar in a modal dialog and shows the chosen
/// date back in its trigger.
///
/// Pick a mode with the named constructors, each typing its selection so the
/// value is never `dynamic`:
///
/// - [FossDatePicker.single] holds one [DateTime].
/// - [FossDatePicker.range] holds a [FossDateRange] over two taps.
///
/// The trigger is a full-width field with a leading calendar glyph and the
/// formatted date, or a [placeholder] while empty. Tapping it (or pressing
/// Enter, Space, or the down arrow) opens the calendar as a modal, presented as
/// a bottom sheet by default or a centered card via [presentation]. Picking a
/// date reports it through `onSelected`; a single pick closes the dialog, a
/// range closes once both ends are set, both governed by [closeOnSelect]. Drive
/// the open state yourself with [open] plus [onOpenChange], or leave it
/// uncontrolled.
///
/// Bound and navigate the calendar through [minDate], [maxDate],
/// [isDateEnabled], and [firstDayOfWeek]. Supply a `format` callback for a
/// locale-aware label; the built-in default takes no date-library dependency.
/// Colors, type, and metrics come from `context.fossTheme`; pass a
/// [FossDatePickerStyle] to [style] for a one-off.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossDatePicker.single(
///   selected: picked,
///   onSelected: (day) => setState(() => picked = day),
/// );
/// ```
@FossSince('0.1.1')
class FossDatePicker extends StatefulWidget {
  const FossDatePicker._({
    required _DatePickerMode mode,
    required this.placeholder,
    DateTime? singleSelected,
    ValueChanged<DateTime>? onSingle,
    String Function(DateTime)? singleFormat,
    FossDateRange? rangeSelected,
    ValueChanged<FossDateRange>? onRange,
    String Function(FossDateRange)? rangeFormat,
    this.open,
    this.onOpenChange,
    this.closeOnSelect = true,
    this.presentation = FossDialogPresentation.bottomSheet,
    this.firstDayOfWeek = DateTime.monday,
    this.minDate,
    this.maxDate,
    this.isDateEnabled,
    this.enabled = true,
    this.semanticsLabel,
    this.style,
    super.key,
  }) : assert(
         firstDayOfWeek >= DateTime.monday && firstDayOfWeek <= DateTime.sunday,
         'firstDayOfWeek must be a DateTime weekday (1 to 7).',
       ),
       _mode = mode,
       _singleSelected = singleSelected,
       _onSingle = onSingle,
       _singleFormat = singleFormat,
       _rangeSelected = rangeSelected,
       _onRange = onRange,
       _rangeFormat = rangeFormat;

  /// {@macro foss.date_picker.preview}
  ///
  /// Creates a single-date picker. [selected] is the chosen day (null for
  /// none); [onSelected] fires with the picked day. [format] overrides the
  /// built-in `March 6th, 2026` label.
  ///
  /// ```dart
  /// FossDatePicker.single(
  ///   selected: picked,
  ///   onSelected: (day) => setState(() => picked = day),
  /// );
  /// ```
  const FossDatePicker.single({
    required DateTime? selected,
    required ValueChanged<DateTime> onSelected,
    String Function(DateTime)? format,
    String placeholder = 'Pick a date',
    bool? open,
    ValueChanged<bool>? onOpenChange,
    bool closeOnSelect = true,
    FossDialogPresentation presentation = FossDialogPresentation.bottomSheet,
    int firstDayOfWeek = DateTime.monday,
    DateTime? minDate,
    DateTime? maxDate,
    bool Function(DateTime)? isDateEnabled,
    bool enabled = true,
    String? semanticsLabel,
    FossDatePickerStyle? style,
    Key? key,
  }) : this._(
         mode: _DatePickerMode.single,
         singleSelected: selected,
         onSingle: onSelected,
         singleFormat: format,
         placeholder: placeholder,
         open: open,
         onOpenChange: onOpenChange,
         closeOnSelect: closeOnSelect,
         presentation: presentation,
         firstDayOfWeek: firstDayOfWeek,
         minDate: minDate,
         maxDate: maxDate,
         isDateEnabled: isDateEnabled,
         enabled: enabled,
         semanticsLabel: semanticsLabel,
         style: style,
         key: key,
       );

  /// Creates a range picker. [selected] is the chosen span (null for none);
  /// [onSelected] fires as the range is set over two taps. [format] overrides
  /// the built-in `Jul 09, 2026 - Jul 16, 2026` label.
  ///
  /// ```dart
  /// FossDatePicker.range(
  ///   selected: span,
  ///   onSelected: (range) => setState(() => span = range),
  /// );
  /// ```
  const FossDatePicker.range({
    required FossDateRange? selected,
    required ValueChanged<FossDateRange> onSelected,
    String Function(FossDateRange)? format,
    String placeholder = 'Pick a date range',
    bool? open,
    ValueChanged<bool>? onOpenChange,
    bool closeOnSelect = true,
    FossDialogPresentation presentation = FossDialogPresentation.bottomSheet,
    int firstDayOfWeek = DateTime.monday,
    DateTime? minDate,
    DateTime? maxDate,
    bool Function(DateTime)? isDateEnabled,
    bool enabled = true,
    String? semanticsLabel,
    FossDatePickerStyle? style,
    Key? key,
  }) : this._(
         mode: _DatePickerMode.range,
         rangeSelected: selected,
         onRange: onSelected,
         rangeFormat: format,
         placeholder: placeholder,
         open: open,
         onOpenChange: onOpenChange,
         closeOnSelect: closeOnSelect,
         presentation: presentation,
         firstDayOfWeek: firstDayOfWeek,
         minDate: minDate,
         maxDate: maxDate,
         isDateEnabled: isDateEnabled,
         enabled: enabled,
         semanticsLabel: semanticsLabel,
         style: style,
         key: key,
       );

  final _DatePickerMode _mode;
  final DateTime? _singleSelected;
  final ValueChanged<DateTime>? _onSingle;
  final String Function(DateTime)? _singleFormat;
  final FossDateRange? _rangeSelected;
  final ValueChanged<FossDateRange>? _onRange;
  final String Function(FossDateRange)? _rangeFormat;

  /// Shown in the trigger while nothing is selected.
  final String placeholder;

  /// The controlled open state. Non-null puts the dialog in controlled mode:
  /// pair it with [onOpenChange] and rebuild on change. Null is uncontrolled.
  final bool? open;

  /// Called with the requested open state on every open or close, including
  /// dismissals. Required to observe changes in controlled mode.
  final ValueChanged<bool>? onOpenChange;

  /// Whether a completed pick closes the dialog: a single pick, or the second
  /// tap of a range. Defaults to true. Set false to keep it open.
  final bool closeOnSelect;

  /// How the calendar dialog presents: a bottom sheet (default) or a centered
  /// card.
  final FossDialogPresentation presentation;

  /// The leading weekday column, as a [DateTime] weekday (1 = Monday), passed
  /// to the calendar.
  final int firstDayOfWeek;

  /// The earliest selectable and navigable day, inclusive. Passed to the
  /// calendar.
  final DateTime? minDate;

  /// The latest selectable and navigable day, inclusive. Passed to the
  /// calendar.
  final DateTime? maxDate;

  /// Disables individual days on top of [minDate] and [maxDate]. Passed to the
  /// calendar.
  final bool Function(DateTime)? isDateEnabled;

  /// Whether the trigger accepts input. When false it dims and never opens.
  final bool enabled;

  /// Accessibility name for the trigger.
  final String? semanticsLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossDatePickerStyle? style;

  @override
  State<FossDatePicker> createState() => _FossDatePickerState();
}

class _FossDatePickerState extends State<FossDatePicker> {
  final FocusNode _triggerFocus = FocusNode(
    debugLabel: 'FossDatePicker trigger',
  );

  bool _open = false;
  bool _focused = false;

  // Whether the modal route is currently on the navigator. Guards double push
  // and reconciles the open state when the route closes on its own (barrier,
  // system back).
  bool _routeShowing = false;

  bool get _isOpen => widget.open ?? _open;

  @override
  void initState() {
    super.initState();
    if (widget.open ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isOpen) _showDialog();
      });
    }
  }

  @override
  void didUpdateWidget(FossDatePicker old) {
    super.didUpdateWidget(old);
    // Controlled mode: sync the route to the parent-owned open value after the
    // frame, since pushing a route during a build is unsafe.
    final target = widget.open;
    if (target != null && target != old.open) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (target && !_routeShowing) _showDialog();
        if (!target && _routeShowing) _dismissDialog();
      });
    }
  }

  @override
  void dispose() {
    _triggerFocus.dispose();
    super.dispose();
  }

  /// The single intent entry point. Fires [FossDatePicker.onOpenChange]; in
  /// controlled mode the parent drives the route through [didUpdateWidget],
  /// otherwise this owns it.
  void _setOpen(bool next) {
    if (next == _isOpen) return;
    widget.onOpenChange?.call(next);
    if (widget.open != null) return;
    setState(() => _open = next);
    next ? _showDialog() : _dismissDialog();
  }

  void _openFromTrigger() {
    if (widget.enabled) _setOpen(true);
  }

  void _showDialog() {
    if (_routeShowing) return;
    _routeShowing = true;
    unawaited(
      showFossDialog<void>(
        context: context,
        presentation: widget.presentation,
        builder: (_) => FossDialog(
          showCloseButton: false,
          presentation: widget.presentation,
          semanticLabel: widget.semanticsLabel,
          content: _CalendarDialog(
            mode: widget._mode,
            singleInitial: widget._singleSelected,
            onSingle: widget._onSingle,
            rangeInitial: widget._rangeSelected,
            onRange: widget._onRange,
            closeOnSelect: widget.closeOnSelect,
            firstDayOfWeek: widget.firstDayOfWeek,
            minDate: widget.minDate,
            maxDate: widget.maxDate,
            isDateEnabled: widget.isDateEnabled,
          ),
        ),
      ).whenComplete(() {
        if (!mounted) return;
        _routeShowing = false;
        // The route closed on its own (a pick, a barrier tap, system back).
        // Reconcile the open state; harmless if it was already lowered.
        if (_isOpen) _setOpen(false);
      }),
    );
  }

  void _dismissDialog() {
    if (_routeShowing) {
      unawaited(Navigator.of(context, rootNavigator: true).maybePop());
    }
  }

  bool get _hasValue => switch (widget._mode) {
    _DatePickerMode.single => widget._singleSelected != null,
    _DatePickerMode.range => widget._rangeSelected != null,
  };

  String _resolveLabel() {
    switch (widget._mode) {
      case _DatePickerMode.single:
        final value = widget._singleSelected;
        if (value == null) return widget.placeholder;
        return (widget._singleFormat ?? _defaultSingleFormat)(value);
      case _DatePickerMode.range:
        final value = widget._rangeSelected;
        if (value == null) return widget.placeholder;
        return (widget._rangeFormat ?? _defaultRangeFormat)(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _resolve(theme, widget.style);
    final hasValue = _hasValue;
    final text = _resolveLabel();
    final textColor = hasValue ? v.foreground : v.placeholderColor;

    final box = FossFieldBox(
      enabled: widget.enabled,
      hasError: false,
      focused: _focused || _isOpen,
      background: v.background,
      borderColor: v.borderColor,
      ringColor: v.ringColor,
      destructiveColor: v.destructiveColor,
      borderRadius: v.borderRadius,
      minHeight: _triggerMinHeight,
      shadow: v.shadow,
      isDark: v.isDark,
      // The trigger node below carries the label as its value, so the painted
      // glyph and text stay out of the semantics tree.
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: v.horizontalPadding),
          child: Row(
            children: [
              FossGlyphIcon(CalendarGlyph(textColor), size: _glyphSize),
              SizedBox(width: v.gap),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: v.textStyle.copyWith(color: textColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel,
      value: text,
      expanded: _isOpen,
      child: FocusableActionDetector(
        focusNode: _triggerFocus,
        enabled: widget.enabled,
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        // Arrow Down opens the trigger, alongside the Enter and Space that
        // FocusableActionDetector maps to ActivateIntent by default.
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowDown): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _openFromTrigger();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _openFromTrigger : null,
          child: box,
        ),
      ),
    );
  }
}

/// The calendar shown inside the modal. Holds a working copy of the selection
/// so the grid updates live while the picker's parent stays controlled: each
/// pick rebuilds the calendar, reports through the picker's callback, and pops
/// the route when the pick completes under [closeOnSelect].
class _CalendarDialog extends StatefulWidget {
  const _CalendarDialog({
    required this.mode,
    required this.closeOnSelect,
    required this.firstDayOfWeek,
    this.singleInitial,
    this.onSingle,
    this.rangeInitial,
    this.onRange,
    this.minDate,
    this.maxDate,
    this.isDateEnabled,
  });

  final _DatePickerMode mode;
  final DateTime? singleInitial;
  final ValueChanged<DateTime>? onSingle;
  final FossDateRange? rangeInitial;
  final ValueChanged<FossDateRange>? onRange;
  final bool closeOnSelect;
  final int firstDayOfWeek;
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool Function(DateTime)? isDateEnabled;

  @override
  State<_CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<_CalendarDialog> {
  DateTime? _single;
  FossDateRange? _range;

  // Range picks arrive over two taps; this flips on each pick so a completed
  // range can close.
  bool _awaitingRangeEnd = false;

  @override
  void initState() {
    super.initState();
    _single = widget.singleInitial;
    _range = widget.rangeInitial;
  }

  void _handleSingle(DateTime day) {
    setState(() => _single = day);
    widget.onSingle?.call(day);
    if (widget.closeOnSelect) {
      unawaited(Navigator.of(context).maybePop());
    }
  }

  void _handleRange(FossDateRange range) {
    setState(() => _range = range);
    widget.onRange?.call(range);
    _awaitingRangeEnd = !_awaitingRangeEnd;
    if (widget.closeOnSelect && !_awaitingRangeEnd) {
      unawaited(Navigator.of(context).maybePop());
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendar = switch (widget.mode) {
      _DatePickerMode.single => FossCalendar.single(
        selected: _single,
        onSelected: _handleSingle,
        firstDayOfWeek: widget.firstDayOfWeek,
        minDate: widget.minDate,
        maxDate: widget.maxDate,
        isDateEnabled: widget.isDateEnabled,
      ),
      _DatePickerMode.range => FossCalendar.range(
        selected: _range,
        onSelected: _handleRange,
        firstDayOfWeek: widget.firstDayOfWeek,
        minDate: widget.minDate,
        maxDate: widget.maxDate,
        isDateEnabled: widget.isDateEnabled,
      ),
    };
    return Center(child: calendar);
  }
}

/// Builds the default trigger appearance from the theme tokens, then lays the
/// date-picker-specific fields of [override] over it.
_DatePickerVisuals _resolve(
  FossThemeData theme,
  FossDatePickerStyle? override,
) {
  final c = theme.colors;
  // Dark lifts the resting trigger fill by the input color, matching the field
  // family; light is the bare surface.
  final background = c.isDark
      ? Color.alphaBlend(
          c.input.withValues(alpha: c.input.a * _darkFillOpacity),
          c.background,
        )
      : c.background;
  return _DatePickerVisuals(
    background: background,
    foreground: c.foreground,
    placeholderColor: override?.placeholderColor ?? c.mutedForeground,
    borderColor: c.input,
    ringColor: c.ring,
    destructiveColor: c.destructive,
    borderRadius: theme.radii.lg,
    horizontalPadding: theme.spacing(3),
    textStyle: theme.typography.sm,
    shadow: theme.shadows.xs,
    gap: override?.gap ?? theme.spacing(1),
    isDark: c.isDark,
  );
}

/// The fully resolved, non-null trigger appearance.
@immutable
class _DatePickerVisuals {
  const _DatePickerVisuals({
    required this.background,
    required this.foreground,
    required this.placeholderColor,
    required this.borderColor,
    required this.ringColor,
    required this.destructiveColor,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.textStyle,
    required this.shadow,
    required this.gap,
    required this.isDark,
  });

  final Color background;
  final Color foreground;
  final Color placeholderColor;
  final Color borderColor;
  final Color ringColor;
  final Color destructiveColor;
  final double borderRadius;
  final double horizontalPadding;
  final TextStyle textStyle;
  final List<BoxShadow> shadow;
  final double gap;
  final bool isDark;
}
