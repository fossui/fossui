import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/button/foss_button.dart';
import 'package:fossui/src/components/dialog/foss_dialog.dart';
import 'package:fossui/src/foundation/foss_dialog_surface.dart'
    show FossDialogPresentation;
import 'package:fossui/src/foundation/foss_field_box.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_time_picker_style.dart';

const double _glyphSize = 16;
const double _triggerMinHeight = 36;
const double _darkFillOpacity = 0.32;

/// One wheel row, matched to the trigger height so the field and the sheet
/// share one rhythm.
const double _itemExtent = 36;
const int _visibleItemCount = 5;

/// Off-centre rows that cannot be picked fade to half their resting alpha, on
/// top of the wheel's own distance fade.
const double _blockedOpacity = 0.5;

/// How much a wheel dims its off-centre rows.
const double _overAndUnderOpacity = 0.45;

const double _wheelDiameterRatio = 1.6;

/// Width of one wheel column as a multiple of the row height. Sets how far
/// apart the values read; the cluster is centred, so the slack goes to the
/// margins rather than between the columns.
const double _columnWidthFactor = 1.75;

const int _minutesPerHour = 60;
const int _minutesPerDay = 24 * _minutesPerHour;

/// A wall-clock time of day, with no date and no time zone.
///
/// Stored on a 24-hour clock, so a 12-hour reading is purely a formatting
/// concern. Values are ordered by [compareTo], which makes bounds checks and
/// sorting one call.
///
/// ```dart
/// const opening = FossTimeOfDay(hour: 9, minute: 30);
/// const closing = FossTimeOfDay(hour: 17, minute: 0);
/// final isOpen = opening.compareTo(closing) < 0;
/// ```
@FossSince('0.1.2')
@immutable
class FossTimeOfDay implements Comparable<FossTimeOfDay> {
  /// Creates a time of day. [hour] is 0 to 23 and [minute] is 0 to 59.
  const FossTimeOfDay({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23, 'hour must be 0 to 23.'),
      assert(minute >= 0 && minute <= 59, 'minute must be 0 to 59.');

  /// Hour on a 24-hour clock, 0 to 23.
  final int hour;

  /// Minute past the hour, 0 to 59.
  final int minute;

  /// Minutes elapsed since midnight, 0 to 1439.
  int get _sinceMidnight => hour * _minutesPerHour + minute;

  /// Orders two times by their position in the day: negative when this one is
  /// earlier, zero when they match, positive when it is later.
  @override
  int compareTo(FossTimeOfDay other) =>
      _sinceMidnight.compareTo(other._sinceMidnight);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FossTimeOfDay && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'FossTimeOfDay($hour:$minute)';
}

/// Builds a time from [minutes] since midnight, which must be within the day.
FossTimeOfDay _fromMinutes(int minutes) => FossTimeOfDay(
  hour: minutes ~/ _minutesPerHour,
  minute: minutes % _minutesPerHour,
);

/// The built-in 24-hour label, as in `21:30`.
String _format24(FossTimeOfDay time) =>
    '${_pad2(time.hour)}:${_pad2(time.minute)}';

/// The built-in 12-hour label, as in `9:30 AM`. Midnight and noon read as 12.
String _format12(FossTimeOfDay time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$hour:${_pad2(time.minute)} ${time.hour < 12 ? 'AM' : 'PM'}';
}

String _pad2(int value) => value.toString().padLeft(2, '0');

/// The bounds a picker applies to a candidate time: the inclusive range plus
/// the caller's arbitrary predicate. Grouped so the trigger, the modal, and the
/// opening-position scan all test a time the same way.
@immutable
class _TimeBounds {
  const _TimeBounds({this.min, this.max, this.isEnabled});

  final FossTimeOfDay? min;
  final FossTimeOfDay? max;
  final bool Function(FossTimeOfDay)? isEnabled;

  /// Whether any bound is in play. An unbounded picker loops its wheels.
  bool get isBounded => min != null || max != null || isEnabled != null;

  bool allows(FossTimeOfDay time) {
    if (min case final min? when time.compareTo(min) < 0) return false;
    if (max case final max? when time.compareTo(max) > 0) return false;
    return isEnabled?.call(time) ?? true;
  }

  /// The earliest time on the [step] grid at or after [min] that [allows]
  /// accepts, or the start of the scan when the whole day is blocked. Used to
  /// park the wheels when the picker opens with no value.
  FossTimeOfDay firstAllowed(int step) {
    final start = min ?? const FossTimeOfDay(hour: 0, minute: 0);
    final from = start._sinceMidnight;
    for (
      var minutes = ((from + step - 1) ~/ step) * step;
      minutes < _minutesPerDay;
      minutes += step
    ) {
      final candidate = _fromMinutes(minutes);
      if (allows(candidate)) return candidate;
    }
    return start;
  }
}

/// {@category Inputs}
/// {@template foss.time_picker.preview}
/// <img src="https://fossui.org/components/time-picker/overview/light.png"
///   alt="FossTimePicker, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/time-picker/overview/dark.png"
///   alt="FossTimePicker, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [time picker documentation ↗](https://fossui.org/docs/components/time-picker)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/time_picker/fosstimepicker/playground).
/// {@endtemplate}
///
/// A time field that opens scrolling wheels in a modal dialog and shows the
/// chosen time back in its trigger.
///
/// The trigger is a full-width field with a leading clock glyph and the
/// formatted time, or a [placeholder] while empty. Tapping it (or pressing
/// Enter, Space, or the down arrow) opens the wheels as a modal, presented as a
/// bottom sheet by default or a centered card via [presentation]. Drive the
/// open state yourself with [open] plus [onOpenChange], or leave it
/// uncontrolled.
///
/// Where a wheel stops scrolling is not the same as a choice, so the modal
/// keeps a draft and commits on the footer: [confirmLabel] reports through
/// [onChanged] and closes, while [cancelLabel] and the barrier discard. Bound
/// the selectable range with [minTime], [maxTime], and [isTimeEnabled]. A
/// blocked time stays on the wheel rather than leaving a hole in it, dimmed,
/// and the confirm action is disabled while the draft sits on one.
/// [minuteStep] coarsens the minute column, and [use24HourFormat] swaps the
/// period column for a 24-hour reading.
///
/// Colors, type, and metrics come from `context.fossTheme`; pass a
/// [FossTimePickerStyle] to [style] for a one-off.
///
/// {@macro foss.customize}
///
/// See also [FossTimeOfDay] for the value type.
///
/// ```dart
/// FossTimePicker(
///   value: picked,
///   onChanged: (time) => setState(() => picked = time),
/// );
/// ```
@FossSince('0.1.2')
class FossTimePicker extends StatefulWidget {
  /// {@macro foss.time_picker.preview}
  ///
  /// Creates a time picker. [value] is the committed time (null shows the
  /// [placeholder]) and [onChanged] fires when the footer confirms.
  ///
  /// ```dart
  /// FossTimePicker(
  ///   value: picked,
  ///   onChanged: (time) => setState(() => picked = time),
  ///   minuteStep: 15,
  /// );
  /// ```
  const FossTimePicker({
    required this.value,
    required this.onChanged,
    this.placeholder = 'Pick a time',
    this.format,
    this.use24HourFormat,
    this.minuteStep = 1,
    this.minTime,
    this.maxTime,
    this.isTimeEnabled,
    this.open,
    this.onOpenChange,
    this.presentation = FossDialogPresentation.bottomSheet,
    this.confirmLabel = 'Set',
    this.cancelLabel = 'Cancel',
    this.enabled = true,
    this.semanticsLabel,
    this.style,
    super.key,
  }) : assert(
         minuteStep >= 1 && minuteStep <= 60 && 60 % minuteStep == 0,
         'minuteStep must divide 60 evenly.',
       );

  /// The committed time, or null for none.
  final FossTimeOfDay? value;

  /// Called with the draft when the footer confirms. Never fires on a scroll.
  final ValueChanged<FossTimeOfDay> onChanged;

  /// Shown in the trigger while nothing is selected, and used as the modal
  /// title.
  final String placeholder;

  /// Overrides the built-in trigger label, which is `9:30 AM` or `21:30`
  /// depending on the resolved hour format.
  final String Function(FossTimeOfDay)? format;

  /// Whether to read and pick on a 24-hour clock, which drops the period
  /// column. Null follows the platform setting through `MediaQuery`, falling
  /// back to 12-hour.
  final bool? use24HourFormat;

  /// The minute increment the wheel offers. Must divide 60 evenly; defaults to
  /// 1. An incoming [value] off the grid shows as-is and snaps on the first
  /// minute scroll.
  final int minuteStep;

  /// The earliest selectable time, inclusive.
  final FossTimeOfDay? minTime;

  /// The latest selectable time, inclusive.
  final FossTimeOfDay? maxTime;

  /// Blocks individual times on top of [minTime] and [maxTime]. Returning false
  /// dims the entry and disables the confirm action while the draft rests on
  /// it.
  final bool Function(FossTimeOfDay)? isTimeEnabled;

  /// The controlled open state. Non-null puts the dialog in controlled mode:
  /// pair it with [onOpenChange] and rebuild on change. Null is uncontrolled.
  final bool? open;

  /// Called with the requested open state on every open or close, including
  /// dismissals. Required to observe changes in controlled mode.
  final ValueChanged<bool>? onOpenChange;

  /// How the modal presents: a bottom sheet (default) or a centered card.
  final FossDialogPresentation presentation;

  /// Label of the footer action that commits the draft.
  final String confirmLabel;

  /// Label of the footer action that discards the draft.
  final String cancelLabel;

  /// Whether the trigger accepts input. When false it dims and never opens.
  final bool enabled;

  /// Accessibility name for the trigger.
  final String? semanticsLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossTimePickerStyle? style;

  @override
  State<FossTimePicker> createState() => _FossTimePickerState();
}

class _FossTimePickerState extends State<FossTimePicker> {
  final FocusNode _triggerFocus = FocusNode(
    debugLabel: 'FossTimePicker trigger',
  );

  bool _open = false;
  bool _focused = false;

  // Whether the modal route is currently on the navigator. Guards double push
  // and reconciles the open state when the route closes on its own (barrier,
  // system back).
  bool _routeShowing = false;

  bool get _isOpen => widget.open ?? _open;

  _TimeBounds get _bounds => _TimeBounds(
    min: widget.minTime,
    max: widget.maxTime,
    isEnabled: widget.isTimeEnabled,
  );

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
  void didUpdateWidget(FossTimePicker old) {
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

  /// The single intent entry point. Fires [FossTimePicker.onOpenChange]; in
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
    final use24Hour = _resolveUse24Hour(context);
    unawaited(
      showFossDialog<void>(
        context: context,
        presentation: widget.presentation,
        builder: (_) => _TimeDialog(
          initial: widget.value,
          onConfirmed: widget.onChanged,
          title: widget.placeholder,
          semanticsLabel: widget.semanticsLabel,
          presentation: widget.presentation,
          use24HourFormat: use24Hour,
          minuteStep: widget.minuteStep,
          bounds: _bounds,
          confirmLabel: widget.confirmLabel,
          cancelLabel: widget.cancelLabel,
          style: widget.style,
        ),
      ).whenComplete(() {
        if (!mounted) return;
        _routeShowing = false;
        // The route closed on its own (a confirm, a barrier tap, system back).
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

  /// The explicit flag when the caller set one, otherwise the platform setting,
  /// otherwise 12-hour.
  bool _resolveUse24Hour(BuildContext context) =>
      widget.use24HourFormat ??
      MediaQuery.maybeAlwaysUse24HourFormatOf(context) ??
      false;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _resolve(theme, widget.style);
    final value = widget.value;
    final format =
        widget.format ?? (_resolveUse24Hour(context) ? _format24 : _format12);
    final text = value == null ? widget.placeholder : format(value);
    final textColor = value == null ? v.placeholderColor : v.foreground;

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
              FossGlyphIcon(ClockGlyph(textColor), size: _glyphSize),
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

/// The wheels shown inside the modal. Holds the draft so the columns update
/// live while the picker's parent stays controlled; nothing reaches the
/// picker's callback until the confirm action fires.
class _TimeDialog extends StatefulWidget {
  const _TimeDialog({
    required this.initial,
    required this.onConfirmed,
    required this.title,
    required this.semanticsLabel,
    required this.presentation,
    required this.use24HourFormat,
    required this.minuteStep,
    required this.bounds,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.style,
  });

  final FossTimeOfDay? initial;
  final ValueChanged<FossTimeOfDay> onConfirmed;
  final String title;
  final String? semanticsLabel;
  final FossDialogPresentation presentation;
  final bool use24HourFormat;
  final int minuteStep;
  final _TimeBounds bounds;
  final String confirmLabel;
  final String cancelLabel;
  final FossTimePickerStyle? style;

  @override
  State<_TimeDialog> createState() => _TimeDialogState();
}

class _TimeDialogState extends State<_TimeDialog> {
  late int _hourIndex;
  late int _minuteIndex;
  late bool _isPm;

  // The hour column's unwrapped position. A looping wheel counts past its ends,
  // so the number of laps it has travelled is what tells the period column to
  // roll over: on a 12-hour clock, stepping off 11 lands on noon, not midnight.
  late int _hourRaw;

  // An incoming value off the minute grid is reported back unchanged until the
  // user touches a wheel, so opening and confirming never rewrites the caller's
  // time behind its back. Any wheel clears it, not just the minute: the minute
  // column is parked on the nearest step, so holding the off-grid value past an
  // hour change would commit a time the wheels never showed.
  int? _offGridMinute;

  int get _minuteCount => _minutesPerHour ~/ widget.minuteStep;

  int get _hourCount => widget.use24HourFormat ? 24 : 12;

  @override
  void initState() {
    super.initState();
    final start =
        widget.initial ?? widget.bounds.firstAllowed(widget.minuteStep);
    _isPm = start.hour >= 12;
    _hourIndex = widget.use24HourFormat ? start.hour : start.hour % 12;
    _hourRaw = _hourIndex;
    _minuteIndex = math.min(
      (start.minute / widget.minuteStep).round(),
      _minuteCount - 1,
    );
    if (start.minute % widget.minuteStep != 0) _offGridMinute = start.minute;
  }

  /// The hour the [_hourIndex] row stands for, read through the period column
  /// in 12-hour mode where index 0 is the 12 o'clock row.
  int _hourAt(int index, {required bool pm}) =>
      widget.use24HourFormat ? index : index + (pm ? 12 : 0);

  int get _draftMinute => _offGridMinute ?? _minuteIndex * widget.minuteStep;

  FossTimeOfDay get _draft => FossTimeOfDay(
    hour: _hourAt(_hourIndex, pm: _isPm),
    minute: _draftMinute,
  );

  void _confirm() {
    widget.onConfirmed(_draft);
    unawaited(Navigator.of(context).maybePop());
  }

  /// Takes the hour column's unwrapped position. Each lap it completes on a
  /// 12-hour clock crosses noon or midnight, so an odd number of laps since the
  /// last report flips the period.
  void _setHourRaw(int raw) {
    setState(() {
      if (!widget.use24HourFormat) {
        final laps =
            (raw / _hourCount).floor() - (_hourRaw / _hourCount).floor();
        if (laps.isOdd) _isPm = !_isPm;
      }
      _hourRaw = raw;
      _hourIndex = raw % _hourCount;
      _offGridMinute = null;
    });
  }

  /// The hour column: `00` to `23`, or the clock order `12, 1 ... 11`. Each row
  /// is tested with the draft's own minute, so the dimming answers "can I pick
  /// this hour" rather than "does this hour exist".
  List<_WheelCell> _hourCells() => [
    for (var i = 0; i < _hourCount; i++)
      _WheelCell(
        label: widget.use24HourFormat ? _pad2(i) : (i == 0 ? 12 : i).toString(),
        allowed: widget.bounds.allows(
          FossTimeOfDay(
            hour: _hourAt(i, pm: _isPm),
            minute: _draftMinute,
          ),
        ),
      ),
  ];

  List<_WheelCell> _minuteCells() => [
    for (var i = 0; i < _minuteCount; i++)
      _WheelCell(
        label: _pad2(i * widget.minuteStep),
        allowed: widget.bounds.allows(
          FossTimeOfDay(
            hour: _hourAt(_hourIndex, pm: _isPm),
            minute: i * widget.minuteStep,
          ),
        ),
      ),
  ];

  List<_WheelCell> _periodCells() => [
    for (final pm in const [false, true])
      _WheelCell(
        label: pm ? 'PM' : 'AM',
        allowed: widget.bounds.allows(
          FossTimeOfDay(
            hour: _hourAt(_hourIndex, pm: pm),
            minute: _draftMinute,
          ),
        ),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _resolve(theme, widget.style);
    final extent = MediaQuery.textScalerOf(context).scale(v.itemExtent);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // A bounded picker cannot loop: an infinite column has no ends, so the
    // first and last allowed entries would be unreachable by scrolling. A
    // column too short to fill the window cannot loop either, or the same value
    // appears twice on screen and reads as a rendering fault: a 30-minute step
    // leaves two rows for five slots.
    bool loops(int count) =>
        !widget.bounds.isBounded && count > v.visibleItemCount;

    final columns = [
      _WheelColumn(
        label: 'Hour',
        cells: _hourCells(),
        selectedIndex: _hourIndex,
        onRawIndexChanged: _setHourRaw,
        looping: loops(_hourCount),
        itemExtent: extent,
        visibleItemCount: v.visibleItemCount,
        reduceMotion: reduceMotion,
        visuals: v,
      ),
      _WheelColumn(
        label: 'Minute',
        cells: _minuteCells(),
        selectedIndex: _minuteIndex,
        onRawIndexChanged: (raw) => setState(() {
          _minuteIndex = raw % _minuteCount;
          _offGridMinute = null;
        }),
        looping: loops(_minuteCount),
        itemExtent: extent,
        visibleItemCount: v.visibleItemCount,
        reduceMotion: reduceMotion,
        visuals: v,
      ),
      if (!widget.use24HourFormat)
        _WheelColumn(
          label: 'Period',
          cells: _periodCells(),
          selectedIndex: _isPm ? 1 : 0,
          onRawIndexChanged: (raw) => setState(() {
            _isPm = raw == 1;
            _offGridMinute = null;
          }),
          looping: false,
          itemExtent: extent,
          visibleItemCount: v.visibleItemCount,
          reduceMotion: reduceMotion,
          visuals: v,
        ),
    ];

    final height = extent * v.visibleItemCount;

    return FossDialog(
      showCloseButton: false,
      presentation: widget.presentation,
      title: Text(widget.title),
      semanticLabel: widget.semanticsLabel ?? widget.title,
      content: SizedBox(
        height: height,
        // The wheels read as one control, so the columns sit in a centred
        // cluster sized to the rows rather than splitting the sheet three ways,
        // which would strand each value in its own third. A narrow sheet
        // reclaims the margin instead of overflowing, since the cluster width
        // is a maximum.
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth:
                  extent * _columnWidthFactor * columns.length +
                  v.bandPadding * 2,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: (height - extent) / 2,
                  height: extent,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: v.highlightColor,
                        shape: RoundedSuperellipseBorder(
                          borderRadius: BorderRadius.circular(
                            v.highlightRadius,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Inset from the band so the first and last values are not
                // flush against its corners.
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: v.bandPadding),
                  child: Row(
                    children: [for (final c in columns) Expanded(child: c)],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        FossButton(
          variant: FossButtonVariant.ghost,
          size: FossButtonSize.sm,
          onPressed: () => unawaited(Navigator.of(context).maybePop()),
          child: Text(widget.cancelLabel),
        ),
        FossButton(
          size: FossButtonSize.sm,
          onPressed: widget.bounds.allows(_draft) ? _confirm : null,
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

/// One row of a wheel: what it reads and whether the bounds accept it.
@immutable
class _WheelCell {
  const _WheelCell({required this.label, required this.allowed});

  final String label;
  final bool allowed;
}

/// A single scrolling column.
///
/// `ListWheelScrollView` exposes no semantics node and handles no key events,
/// so this wraps it in an adjustable node and maps the arrow keys to a one-row
/// step itself.
class _WheelColumn extends StatefulWidget {
  const _WheelColumn({
    required this.label,
    required this.cells,
    required this.selectedIndex,
    required this.onRawIndexChanged,
    required this.looping,
    required this.itemExtent,
    required this.visibleItemCount,
    required this.reduceMotion,
    required this.visuals,
  });

  final String label;
  final List<_WheelCell> cells;

  /// The row currently in the centre band, already wrapped into [cells].
  final int selectedIndex;

  /// Reports the wheel's unwrapped position, which counts past the ends of a
  /// looping column so the caller can see how far it has travelled.
  final ValueChanged<int> onRawIndexChanged;

  final bool looping;
  final double itemExtent;
  final int visibleItemCount;
  final bool reduceMotion;
  final _TimePickerVisuals visuals;

  @override
  State<_WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<_WheelColumn> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.selectedIndex);

  bool _focused = false;

  @override
  void didUpdateWidget(_WheelColumn old) {
    super.didUpdateWidget(old);
    // Another column moved this one: the hour wheel rolling past noon drives
    // the period. Catch the wheel up after the frame, since scrolling during a
    // build dispatches notifications the tree is not ready for.
    if (widget.selectedIndex == old.selectedIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // A wheel reports each row it passes, so a fling rebuilds this column
      // while it is still travelling. Correcting it then would fight the
      // gesture; only a wheel at rest is out of step with the draft.
      final position = _controller.position;
      if (position.isScrollingNotifier.value) return;
      _syncToSelected();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Moves the wheel onto [_WheelColumn.selectedIndex], leaving it alone when
  /// it is already there. A wheel that reported its own position is always
  /// already there, so in practice this only carries the period column across
  /// when the hour column rolls it.
  void _syncToSelected() {
    final current = _controller.selectedItem % widget.cells.length;
    if (current == widget.selectedIndex) return;
    _moveTo(_controller.selectedItem + widget.selectedIndex - current);
  }

  /// Moves the wheel [delta] rows, wrapping when the column loops and clamping
  /// when it does not. Jumps rather than animates under reduced motion.
  void _step(int delta) {
    final count = widget.cells.length;
    final raw = _controller.selectedItem + delta;
    _moveTo(widget.looping ? raw : raw.clamp(0, count - 1));
  }

  /// Scrolls onto the row at [target], jumping rather than animating under
  /// reduced motion.
  void _moveTo(int target) {
    if (target == _controller.selectedItem) return;
    if (widget.reduceMotion) {
      _controller.jumpToItem(target);
    } else {
      unawaited(
        _controller.animateToItem(
          target,
          duration: widget.visuals.stepDuration,
          curve: Curves.easeOut,
        ),
      );
    }
  }

  /// The row a step of [delta] lands on, wrapping when the column loops and
  /// clamping when it does not. Names the announced increase and decrease.
  int _neighbour(int delta) {
    final count = widget.cells.length;
    final raw = widget.selectedIndex + delta;
    return widget.looping ? raw % count : raw.clamp(0, count - 1);
  }

  Color _colorFor(int index) {
    final cell = widget.cells[index];
    final colors = widget.visuals;
    if (!cell.allowed) {
      return index == widget.selectedIndex
          ? colors.mutedForeground
          : colors.mutedForeground.withValues(
              alpha: colors.mutedForeground.a * _blockedOpacity,
            );
    }
    return index == widget.selectedIndex
        ? colors.foreground
        : colors.mutedForeground;
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.visuals;
    final cells = widget.cells;

    final rows = [
      for (var i = 0; i < cells.length; i++)
        Center(
          child: Text(
            cells[i].label,
            maxLines: 1,
            style: v.wheelTextStyle.copyWith(color: _colorFor(i)),
          ),
        ),
    ];

    final wheel = ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: widget.itemExtent,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: _wheelDiameterRatio,
      overAndUnderCenterOpacity: _overAndUnderOpacity,
      // The callback wraps its index back into the child list, which hides how
      // many laps a looping wheel has turned. The controller keeps the count.
      onSelectedItemChanged: (_) =>
          widget.onRawIndexChanged(_controller.selectedItem),
      childDelegate: widget.looping
          ? ListWheelChildLoopingListDelegate(children: rows)
          : ListWheelChildListDelegate(children: rows),
    );

    return Semantics(
      container: true,
      label: widget.label,
      value: cells[widget.selectedIndex].label,
      increasedValue: cells[_neighbour(1)].label,
      decreasedValue: cells[_neighbour(-1)].label,
      onIncrease: () => _step(1),
      onDecrease: () => _step(-1),
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(-1),
          SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(1),
        },
        actions: <Type, Action<Intent>>{
          _StepIntent: CallbackAction<_StepIntent>(
            onInvoke: (intent) {
              _step(intent.delta);
              return null;
            },
          ),
        },
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: ShapeDecoration(
            shape: RoundedSuperellipseBorder(
              side: _focused
                  ? BorderSide(color: v.ringColor, width: 2)
                  : BorderSide.none,
              borderRadius: BorderRadius.circular(v.highlightRadius),
            ),
          ),
          // The adjustable node above speaks for the column, so the wheel's own
          // scrollable node stays out of the tree.
          child: ExcludeSemantics(child: wheel),
        ),
      ),
    );
  }
}

/// Moves a wheel column by [delta] rows.
class _StepIntent extends Intent {
  const _StepIntent(this.delta);

  final int delta;
}

/// Builds the default appearance from the theme tokens, then lays the
/// time-picker-specific fields of [override] over it.
_TimePickerVisuals _resolve(
  FossThemeData theme,
  FossTimePickerStyle? override,
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
  return _TimePickerVisuals(
    background: background,
    foreground: c.foreground,
    mutedForeground: c.mutedForeground,
    placeholderColor: override?.placeholderColor ?? c.mutedForeground,
    borderColor: c.input,
    ringColor: c.ring,
    destructiveColor: c.destructive,
    borderRadius: theme.radii.lg,
    horizontalPadding: theme.spacing(3),
    textStyle: theme.typography.sm,
    wheelTextStyle: theme.typography.base.medium,
    shadow: theme.shadows.xs,
    gap: override?.gap ?? theme.spacing(1),
    itemExtent: override?.itemExtent ?? _itemExtent,
    visibleItemCount: override?.visibleItemCount ?? _visibleItemCount,
    highlightColor: override?.highlightColor ?? c.accent,
    highlightRadius: theme.radii.md,
    bandPadding: theme.spacing(3),
    stepDuration: theme.motion.overlay,
    isDark: c.isDark,
  );
}

/// The fully resolved, non-null appearance of the trigger and the wheels.
@immutable
class _TimePickerVisuals {
  const _TimePickerVisuals({
    required this.background,
    required this.foreground,
    required this.mutedForeground,
    required this.placeholderColor,
    required this.borderColor,
    required this.ringColor,
    required this.destructiveColor,
    required this.borderRadius,
    required this.horizontalPadding,
    required this.textStyle,
    required this.wheelTextStyle,
    required this.shadow,
    required this.gap,
    required this.itemExtent,
    required this.visibleItemCount,
    required this.highlightColor,
    required this.highlightRadius,
    required this.bandPadding,
    required this.stepDuration,
    required this.isDark,
  });

  final Color background;
  final Color foreground;
  final Color mutedForeground;
  final Color placeholderColor;
  final Color borderColor;
  final Color ringColor;
  final Color destructiveColor;
  final double borderRadius;
  final double horizontalPadding;
  final TextStyle textStyle;
  final TextStyle wheelTextStyle;
  final List<BoxShadow> shadow;
  final double gap;
  final double itemExtent;
  final int visibleItemCount;
  final Color highlightColor;
  final double highlightRadius;
  final double bandPadding;
  final Duration stepDuration;
  final bool isDark;
}
