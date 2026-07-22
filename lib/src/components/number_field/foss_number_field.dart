import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/text_field/foss_text_field.dart'
    show FossTextField, FossTextFieldSize, fieldMetrics;
import 'package:fossui/src/foundation/foss_field_box.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_number_field_style.dart';

const double _iconSize = 18;
const double _disabledOpacity = 0.64;

// The painted glyph and placeholder sit quieter than the value: the glyph at
// 80% of the foreground alpha, the placeholder at 72% of the muted alpha.
const double _glyphOpacity = 0.8;
const double _placeholderOpacity = 0.72;

// The text selection highlight is the ring color at a low alpha.
const double _selectionOpacity = 0.24;

/// {@category Inputs}
/// {@template foss.number_field.preview}
/// <img src="https://fossui.org/components/number_field/overview/light.png"
///   alt="FossNumberField, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/number_field/overview/dark.png"
///   alt="FossNumberField, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [number field documentation ↗](https://fossui.org/docs/components/number-field)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/number_field/fossnumberfield/playground).
/// {@endtemplate}
///
/// A numeric input flanked by a decrement and an increment button.
///
/// Type a number, or step it with the buttons and the keyboard. The value is a
/// [num] held in `[min, max]`, moved by [step] (and [largeStep] on the page
/// keys). A stepper press moves the value one [step]; it does not auto-repeat
/// on a held press. Sizing, radius, fill, border, and state colors come from
/// the same tokens as [FossTextField] through `context.fossTheme`, so the two
/// controls line up pixel for pixel; a global retheme restyles both. For a
/// one-off, pass a [FossNumberFieldStyle] to [style].
///
/// Drive it controlled with [value] plus [onChanged], or uncontrolled with
/// [initialValue]. [onChanged] fires with the parsed value, or null when the
/// field is cleared or the text does not parse. A typed value out of range
/// snaps in on commit; the steppers stop at the bounds.
///
/// Display and typed entry route through [format] and [parse]; the defaults are
/// a plain decimal string and a permissive number parse, with no locale
/// dependency. Pass your own to render currency or a locale.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossNumberField(
///   value: quantity,
///   min: 0,
///   max: 10,
///   onChanged: (v) => setState(() => quantity = v),
/// );
/// ```
@FossSince('0.1.1')
class FossNumberField extends StatefulWidget {
  /// {@macro foss.number_field.preview}
  ///
  /// Creates a number field. All fields are optional; drive it with [value] +
  /// [onChanged] or seed it with [initialValue].
  const FossNumberField({
    this.value,
    this.onChanged,
    this.initialValue,
    this.min,
    this.max,
    this.step = 1,
    this.largeStep,
    this.size = FossTextFieldSize.md,
    this.format,
    this.parse,
    this.placeholder,
    this.error = false,
    this.enabled = true,
    this.semanticsLabel,
    this.style,
    super.key,
  });

  /// The controlled current value. Pair with [onChanged] and omit
  /// [initialValue]. Null shows an empty field.
  final num? value;

  /// Called with the new value whenever it changes, or null when the field is
  /// cleared or the text does not parse.
  final ValueChanged<num?>? onChanged;

  /// The uncontrolled seed value. Omit when [value] is set.
  final num? initialValue;

  /// Inclusive lower bound. Null leaves the value unbounded below.
  final num? min;

  /// Inclusive upper bound. Null leaves the value unbounded above.
  final num? max;

  /// The increment for the buttons and the arrow keys. Defaults to 1.
  final num step;

  /// The increment for the page keys. Defaults to ten times [step].
  final num? largeStep;

  /// The size. Shares [FossTextFieldSize] with [FossTextField]. Defaults to
  /// [FossTextFieldSize.md].
  final FossTextFieldSize size;

  /// Renders the value for display. Defaults to a plain decimal string.
  final String Function(num value)? format;

  /// Reads typed entry into a value. Returns null when the text is not a
  /// number. Defaults to a permissive number parse.
  final num? Function(String text)? parse;

  /// Placeholder shown while the field is empty.
  final String? placeholder;

  /// Whether the control shows its invalid state. Recolors the border and ring.
  final bool error;

  /// Whether the control accepts input. When false it dims and both steppers
  /// stop responding.
  final bool enabled;

  /// Accessibility name for the control.
  final String? semanticsLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossNumberFieldStyle? style;

  @override
  State<FossNumberField> createState() => _FossNumberFieldState();
}

class _FossNumberFieldState extends State<FossNumberField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();

  late final TextSelectionGestureDetectorBuilder _gestureBuilder =
      TextSelectionGestureDetectorBuilder(delegate: this);

  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  // The source of truth for the value. Seeded from [value] or [initialValue],
  // synced from [value] on a controlled update, and updated on edit or step.
  num? _value;

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled;

  num get _largeStep => widget.largeStep ?? widget.step * 10;

  @override
  void initState() {
    super.initState();
    _value = _clamp(widget.value ?? widget.initialValue);
    _controller = TextEditingController(text: _displayText(_value));
    _focusNode = FocusNode(onKeyEvent: _handleKey)
      ..addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FossNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A controlled update from the parent is authoritative: clamp it in and
    // reformat the field, unless the user is mid-edit and would fight the text.
    if (widget.value != oldWidget.value) {
      final clamped = _clamp(widget.value);
      _value = clamped;
      if (!_focusNode.hasFocus) _syncText();
      // The parent handed us a value outside the bounds. Report the clamped
      // value back so a controlled parent converges instead of holding a value
      // the field can never show. Deferred to avoid notifying mid-build; the
      // correction clamps to itself, so it settles in one extra frame.
      if (clamped != widget.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onChanged?.call(clamped);
        });
      }
    }
    if (oldWidget.enabled && !widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  String _format(num value) => (widget.format ?? _defaultFormat)(value);

  num? _parse(String text) => (widget.parse ?? _defaultParse)(text);

  String _displayText(num? value) => value == null ? '' : _format(value);

  num? _clamp(num? value) {
    if (value == null) return null;
    var result = value;
    final min = widget.min;
    final max = widget.max;
    if (min != null && result < min) result = min;
    if (max != null && result > max) result = max;
    return result;
  }

  // Writes the formatted value into the controller with the caret at the end,
  // used after a step, a commit, or a controlled update, never while typing.
  void _syncText() {
    final text = _displayText(_value);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _emit(num? next, {required bool syncText}) {
    final changed = next != _value;
    setState(() => _value = next);
    if (syncText) _syncText();
    if (changed) widget.onChanged?.call(next);
  }

  // Steps from the current value, or from the lower bound (or zero) when empty,
  // and clamps into range.
  void _step(num delta) {
    if (!widget.enabled) return;
    final base = _value ?? widget.min ?? 0;
    _emit(_clamp(_addStep(base, delta)), syncText: true);
  }

  void _onTextChanged(String text) => _emit(_parse(text), syncText: false);

  void _onFocusChanged() {
    setState(() {});
    // Committing on blur snaps a typed out-of-range value into the bounds and
    // normalizes the text to the formatted value.
    if (!_focusNode.hasFocus) _emit(_clamp(_value), syncText: true);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is KeyUpEvent) return KeyEventResult.ignored;
    return switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => _stepped(widget.step),
      LogicalKeyboardKey.arrowDown => _stepped(-widget.step),
      LogicalKeyboardKey.pageUp => _stepped(_largeStep),
      LogicalKeyboardKey.pageDown => _stepped(-_largeStep),
      _ => KeyEventResult.ignored,
    };
  }

  KeyEventResult _stepped(num delta) {
    _step(delta);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _apply(_resolve(theme, widget.size), widget.style);
    final colors = theme.colors;

    final value = _value;
    final min = widget.min;
    final max = widget.max;
    final canDecrement =
        widget.enabled && !(min != null && value != null && value <= min);
    final canIncrement =
        widget.enabled && !(max != null && value != null && value >= max);

    final box = FossFieldBox(
      enabled: widget.enabled,
      hasError: widget.error,
      focused: _focusNode.hasFocus && widget.enabled,
      background: v.background,
      borderColor: v.borderColor,
      ringColor: colors.ring,
      destructiveColor: colors.destructive,
      borderRadius: v.borderRadius,
      minHeight: v.minHeight,
      shadow: v.shadow,
      isDark: colors.isDark,
      child: Row(
        children: [
          _Stepper(
            plus: false,
            interactive: canDecrement,
            dim: widget.enabled && !canDecrement,
            visuals: v,
            semanticsLabel: 'Decrement',
            onStep: () => _step(-widget.step),
          ),
          Expanded(
            child: _buildEditable(colors, v, canDecrement, canIncrement),
          ),
          _Stepper(
            plus: true,
            interactive: canIncrement,
            dim: widget.enabled && !canIncrement,
            visuals: v,
            semanticsLabel: 'Increment',
            onStep: () => _step(widget.step),
          ),
        ],
      ),
    );

    if (!widget.enabled) return box;

    return TapRegion(
      onTapOutside: (_) {
        if (_focusNode.hasFocus) _focusNode.unfocus();
      },
      child: _gestureBuilder.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: box,
      ),
    );
  }

  Widget _buildEditable(
    FossColors colors,
    _NumberFieldVisuals v,
    bool canDecrement,
    bool canIncrement,
  ) {
    final textStyle = v.textStyle.copyWith(
      color: v.textColor,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final editable = EditableText(
      key: _editableKey,
      controller: _controller,
      focusNode: _focusNode,
      readOnly: !widget.enabled,
      rendererIgnoresPointer: true,
      textAlign: TextAlign.center,
      style: textStyle,
      // Even leading centers the value vertically against the base type's line
      // height, matching the placeholder so the first keystroke does not jump.
      textHeightBehavior: const TextHeightBehavior(
        leadingDistribution: TextLeadingDistribution.even,
      ),
      cursorColor: colors.foreground,
      backgroundCursorColor: colors.mutedForeground,
      selectionColor: colors.ring.withValues(alpha: _selectionOpacity),
      cursorOpacityAnimates: true,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      keyboardAppearance: colors.isDark ? Brightness.dark : Brightness.light,
      inputFormatters: const [_NumericFormatter()],
      onChanged: _onTextChanged,
      enableInteractiveSelection: widget.enabled,
    );

    final placeholder = widget.placeholder;
    // The adjustable value and its stepped previews must agree on emptiness:
    // when the field is empty the previews stay empty too.
    final valueText = _displayText(_value);
    final base = _value ?? widget.min ?? 0;
    final increased = valueText.isEmpty
        ? ''
        : _displayText(_clamp(_addStep(base, widget.step)));
    final decreased = valueText.isEmpty
        ? ''
        : _displayText(_clamp(_addStep(base, -widget.step)));

    return Semantics(
      label: widget.semanticsLabel,
      value: valueText,
      increasedValue: increased,
      decreasedValue: decreased,
      textField: true,
      enabled: widget.enabled,
      onIncrease: canIncrement ? () => _step(widget.step) : null,
      onDecrease: canDecrement ? () => _step(-widget.step) : null,
      child: Stack(
        children: [
          if (placeholder != null)
            Positioned.fill(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? IgnorePointer(
                        child: ExcludeSemantics(
                          child: Text(
                            placeholder,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textHeightBehavior: const TextHeightBehavior(
                              leadingDistribution: TextLeadingDistribution.even,
                            ),
                            style: v.textStyle.copyWith(color: v.hintColor),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          editable,
        ],
      ),
    );
  }
}

/// The default display: a plain decimal string with no trailing zeros.
String _defaultFormat(num value) {
  if (value is int) return value.toString();
  final d = value.toDouble();
  return d == d.truncateToDouble() ? d.toStringAsFixed(0) : d.toString();
}

// Adds a step without accumulating IEEE-754 drift: quantizes the sum to the
// decimal precision of its operands, so 0.1 + 0.1 + 0.1 lands on 0.3, not
// 0.30000000000000004. Integer arithmetic passes through exactly.
num _addStep(num base, num delta) {
  if (base is int && delta is int) return base + delta;
  final places = math.max(_decimals(base), _decimals(delta));
  final factor = math.pow(10, places).toDouble();
  return ((base + delta) * factor).roundToDouble() / factor;
}

int _decimals(num value) {
  if (value is int) return 0;
  final text = value.toString();
  final dot = text.indexOf('.');
  return dot < 0 ? 0 : text.length - dot - 1;
}

/// The default parse: a permissive number read, null when the text is not a
/// number.
num? _defaultParse(String text) => num.tryParse(text.trim());

/// Rejects any edit that would leave the text a non-numeric shape, allowing a
/// partial entry (empty, a lone sign, a trailing separator) while typing.
class _NumericFormatter extends TextInputFormatter {
  const _NumericFormatter();

  static final _pattern = RegExp(r'^[+-]?\d*\.?\d*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _pattern.hasMatch(newValue.text) ? newValue : oldValue;
}

/// One end of the control: a shrink-0 button with a painted plus or minus
/// glyph. Fills with the hover color on pointer hover; dims its glyph when it
/// is at a bound. Shares the input's focus stop, so it carries no focus ring.
class _Stepper extends StatefulWidget {
  const _Stepper({
    required this.plus,
    required this.interactive,
    required this.dim,
    required this.visuals,
    required this.semanticsLabel,
    required this.onStep,
  });

  final bool plus;
  final bool interactive;
  final bool dim;
  final _NumberFieldVisuals visuals;
  final String semanticsLabel;
  final VoidCallback onStep;

  @override
  State<_Stepper> createState() => _StepperState();
}

class _StepperState extends State<_Stepper> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.visuals;
    final glyphColor = widget.dim
        ? v.glyphColor.withValues(alpha: v.glyphColor.a * _disabledOpacity)
        : v.glyphColor;

    // The hover fill rounds the inner corner so it sits within the box radius.
    final innerRadius = Radius.circular(math.max(0, v.borderRadius - 1));
    final fill = _hovered && widget.interactive
        ? DecoratedBox(
            decoration: ShapeDecoration(
              color: v.stepperHoverColor,
              shape: RoundedSuperellipseBorder(
                borderRadius: widget.plus
                    ? BorderRadiusDirectional.horizontal(end: innerRadius)
                    : BorderRadiusDirectional.horizontal(start: innerRadius),
              ),
            ),
          )
        : const SizedBox.shrink();

    final glyph = Padding(
      padding: EdgeInsets.symmetric(horizontal: v.stepperPadX),
      child: SizedBox.square(
        dimension: v.iconSize,
        child: CustomPaint(
          painter: _GlyphPainter(color: glyphColor, plus: widget.plus),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: widget.interactive,
      label: widget.semanticsLabel,
      child: MouseRegion(
        cursor: widget.interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.interactive ? widget.onStep : null,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: fill),
              glyph,
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a centered minus, or a plus when [plus], as 1.5px rounded strokes.
class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({required this.color, required this.plus});

  final Color color;
  final bool plus;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final arm = size.width / 2 * 0.55;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center - Offset(arm, 0),
      center + Offset(arm, 0),
      paint,
    );
    if (plus) {
      canvas.drawLine(
        center - Offset(0, arm),
        center + Offset(0, arm),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.plus != plus;
}

/// Builds the default appearance for a [size] from the theme tokens, reusing
/// the text field's shared field metrics so the two controls resolve one box.
_NumberFieldVisuals _resolve(FossThemeData theme, FossTextFieldSize size) {
  final c = theme.colors;
  final m = fieldMetrics(theme, size);
  return _NumberFieldVisuals(
    background: m.fill,
    borderColor: c.input,
    textColor: c.foreground,
    hintColor: c.mutedForeground.withValues(alpha: _placeholderOpacity),
    glyphColor: c.foreground.withValues(alpha: c.foreground.a * _glyphOpacity),
    stepperHoverColor: c.accent,
    borderRadius: m.radius,
    stepperPadX: m.padX - 1,
    minHeight: m.minHeight,
    textStyle: theme.typography.base,
    iconSize: _iconSize,
    shadow: theme.shadows.xs,
  );
}

/// Lays a per-instance [override] over the resolved [base], field by field.
_NumberFieldVisuals _apply(
  _NumberFieldVisuals base,
  FossNumberFieldStyle? override,
) {
  if (override == null) return base;
  return _NumberFieldVisuals(
    background: override.backgroundColor ?? base.background,
    borderColor: override.borderColor ?? base.borderColor,
    textColor: base.textColor,
    hintColor: base.hintColor,
    glyphColor: base.glyphColor,
    stepperHoverColor: override.stepperHoverColor ?? base.stepperHoverColor,
    borderRadius: override.borderRadius ?? base.borderRadius,
    stepperPadX: base.stepperPadX,
    minHeight: override.minHeight ?? base.minHeight,
    textStyle: override.textStyle ?? base.textStyle,
    iconSize: override.iconSize ?? base.iconSize,
    shadow: override.shadow ?? base.shadow,
  );
}

/// The fully resolved, non-null appearance for one size. A
/// [FossNumberFieldStyle] override is laid over it by [_apply], so the widget
/// reads only non-null fields and never needs the null-assertion operator.
@immutable
class _NumberFieldVisuals {
  const _NumberFieldVisuals({
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.hintColor,
    required this.glyphColor,
    required this.stepperHoverColor,
    required this.borderRadius,
    required this.stepperPadX,
    required this.minHeight,
    required this.textStyle,
    required this.iconSize,
    required this.shadow,
  });

  final Color background;
  final Color borderColor;
  final Color textColor;
  final Color hintColor;
  final Color glyphColor;
  final Color stepperHoverColor;
  final double borderRadius;
  final double stepperPadX;
  final double minHeight;
  final TextStyle textStyle;
  final double iconSize;
  final List<BoxShadow> shadow;
}
