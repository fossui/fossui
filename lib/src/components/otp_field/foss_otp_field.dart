import 'dart:async' show unawaited;

import 'package:flutter/services.dart'
    show
        AutofillHints,
        FilteringTextInputFormatter,
        LengthLimitingTextInputFormatter,
        TextInputAction,
        TextInputFormatter,
        TextInputType;
import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_field_box.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_otp_field_style.dart';

// Dark surfaces lift the fill by the input color at 32% of its alpha, matching
// the shared field box.
const double _darkFillOpacity = 0.32;

/// The size of a [FossOtpField].
enum FossOtpFieldSize {
  /// Default: 36 x 36 slots with 16pt text.
  md,

  /// Prominent: 40 x 40 slots with 18pt text.
  lg,
}

/// The character set a [FossOtpField] slot accepts. A rejected character is
/// dropped, never shown.
enum FossOtpValidation {
  /// Digits only (`0`-`9`). The default, and the numeric keyboard.
  numeric,

  /// Latin letters only (`a`-`z`, `A`-`Z`).
  alphabetic,

  /// Latin letters and digits.
  alphanumeric,

  /// No filtering; every character is accepted.
  none,
}

/// {@category Inputs}
/// {@template foss.otp-field.preview}
/// <img src="https://fossui.org/components/otp-field/overview/light.png"
///   alt="FossOtpField, light theme" width="360"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/otp-field/overview/dark.png"
///   alt="FossOtpField, dark theme" width="360"
///   style="max-width:100%;height:auto" />
///
/// See the [otp field documentation ↗](https://fossui.org/docs/components/otp-field) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/otp_field/fossotpfield/playground).
/// {@endtemplate}
///
/// A segmented one-time-code field: a row of single-character slots over one
/// hidden input.
///
/// Typing places a character in the active slot and advances the caret;
/// backspace clears and retreats; arrow keys move the caret; a paste (or the
/// platform one-time-code autofill) fills the whole row at once, dropping any
/// character [validation] rejects. Colors, radius, and type come from
/// `context.fossTheme`, so a global retheme restyles every field. For a
/// one-off, pass a [FossOtpFieldStyle] to [style].
///
/// The code is a plain [String] of up to [length] characters. Use it controlled
/// with [value] and [onChanged], or uncontrolled; [onCompleted] fires each time
/// the row fills. Set [obscure] to mask each character with a dot, and [groups]
/// (summing to [length]) to split the row with a separator, for example
/// `groups: [3, 3]`. Passing `enabled: false` disables the whole field.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossOtpField(
///   length: 6,
///   groups: const [3, 3],
///   onCompleted: (code) => verify(code),
/// );
/// ```
@FossSince('0.1.1')
class FossOtpField extends StatefulWidget {
  /// {@macro foss.otp-field.preview}
  ///
  /// Creates a one-time-code field. Only [length] is required.
  const FossOtpField({
    required this.length,
    this.value,
    this.onChanged,
    this.onCompleted,
    this.size = FossOtpFieldSize.md,
    this.validation = FossOtpValidation.numeric,
    this.groups,
    this.obscure = false,
    this.autofocus = false,
    this.error = false,
    this.enabled = true,
    this.semanticsLabel,
    this.style,
    super.key,
  }) : assert(length > 0, 'length must be at least 1');

  /// The number of slots, and the maximum code length.
  final int length;

  /// The current code, for controlled use. Pair with [onChanged]. When null the
  /// field keeps its own value.
  final String? value;

  /// Called with the whole code on every edit.
  final ValueChanged<String>? onChanged;

  /// Called with the code each time the row fills to [length]. Fires on every
  /// transition into the full state, so deleting a digit and retyping it fires
  /// again.
  final ValueChanged<String>? onCompleted;

  /// The size. Defaults to [FossOtpFieldSize.md].
  final FossOtpFieldSize size;

  /// The accepted character set. Defaults to [FossOtpValidation.numeric].
  final FossOtpValidation validation;

  /// Optional group sizes that split the row with a separator pill, for example
  /// `[3, 3]`. Ignored unless the sizes sum to [length].
  final List<int>? groups;

  /// Whether to mask each character with a dot, for privacy. Defaults to false.
  final bool obscure;

  /// Whether to focus the field on first build. Defaults to false.
  final bool autofocus;

  /// Whether to show the invalid state. Defaults to false.
  final bool error;

  /// Whether the field accepts input. When false it dims and stops responding.
  final bool enabled;

  /// The accessible name for the field. Defaults to a generic code label.
  final String? semanticsLabel;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossOtpFieldStyle? style;

  @override
  State<FossOtpField> createState() => _FossOtpFieldState();
}

class _FossOtpFieldState extends State<FossOtpField>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final AnimationController _blink;

  // The last text seen, so [onChanged] fires only on a real value change, not
  // on a caret move, and a controlled write does not echo back.
  String _lastText = '';
  bool _wasComplete = false;

  // A programmatic controller write skips the input formatters, so a controlled
  // value is clamped to [length] here to keep it inside the slot row.
  String _clamped(String? value) {
    final text = value ?? '';
    return text.length > widget.length
        ? text.substring(0, widget.length)
        : text;
  }

  @override
  void initState() {
    super.initState();
    _lastText = _clamped(widget.value);
    _wasComplete = _lastText.length == widget.length;
    _controller = TextEditingController(text: _lastText);
    _focusNode = FocusNode();
    _controller.addListener(_onChanged);
    _focusNode.addListener(_onFocusChanged);
    // Duration is set from the theme in build, where the inherited lookup is
    // safe; a resting default keeps the controller valid until then.
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(FossOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value case final incoming?) {
      final v = _clamped(incoming);
      if (v != _controller.text) {
        // Suppress the echo: mark this write seen before it fires the listener.
        // Resync completeness too, so a later user edit still fires onCompleted
        // exactly once against the true prior state.
        _lastText = v;
        _wasComplete = v.length == widget.length;
        _controller.value = TextEditingValue(
          text: v,
          selection: TextSelection.collapsed(offset: v.length),
        );
      }
    }
    if (oldWidget.enabled && !widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChanged)
      ..dispose();
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _blink.dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  void _onChanged() {
    final text = _controller.text;
    if (text != _lastText) {
      _lastText = text;
      widget.onChanged?.call(text);
      final complete = text.length == widget.length;
      if (complete && !_wasComplete) widget.onCompleted?.call(text);
      _wasComplete = complete;
    }
    // Rebuild for a caret move too, so the active slot tracks the selection.
    setState(() {});
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _focusNode.requestFocus();
    // Drop the caret past the entered digits: the row fills left to right, so
    // end-of-text is the next empty slot regardless of where the tap landed.
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
  }

  List<TextInputFormatter> get _formatters {
    final allow = switch (widget.validation) {
      FossOtpValidation.numeric => RegExp('[0-9]'),
      FossOtpValidation.alphabetic => RegExp('[A-Za-z]'),
      FossOtpValidation.alphanumeric => RegExp('[A-Za-z0-9]'),
      FossOtpValidation.none => null,
    };
    return [
      LengthLimitingTextInputFormatter(widget.length),
      if (allow != null) FilteringTextInputFormatter.allow(allow),
    ];
  }

  // The slot the caret sits in, or null when unfocused or the selection spans a
  // range. A collapsed selection at offset i means the next character lands in
  // slot i; a caret past the last slot (a full row) clamps to it, so a focused
  // field always shows exactly one active slot.
  int? _activeIndex() {
    if (!_focusNode.hasFocus || !widget.enabled) return null;
    final selection = _controller.selection;
    if (!selection.isCollapsed) return null;
    final offset = selection.baseOffset;
    if (offset < 0) return null;
    return offset.clamp(0, widget.length - 1);
  }

  // The boundary slot indices a separator follows, when [groups] sums to
  // [length]; empty otherwise (a bad grouping is a silent no-op).
  Set<int> _separatorAfter() {
    final groups = widget.groups;
    if (groups == null) return const {};
    var sum = 0;
    for (final g in groups) {
      sum += g;
    }
    if (sum != widget.length) return const {};
    final boundaries = <int>{};
    var running = 0;
    for (var i = 0; i < groups.length - 1; i++) {
      running += groups[i];
      boundaries.add(running - 1);
    }
    return boundaries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _apply(_resolve(theme, widget.size), widget.style);
    final colors = theme.colors;

    _blink.duration = theme.motion.caretBlink;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final baseFont = v.textStyle.fontSize ?? 16;
    final scaler = MediaQuery.textScalerOf(context);
    final scale = scaler.scale(baseFont) / baseFont;

    final text = _controller.text;
    final active = _activeIndex();
    final separators = _separatorAfter();

    // The caret blinks only while a slot is active; an idle field schedules no
    // frames, and reduced motion holds the caret steady.
    if (active != null && !reduceMotion) {
      if (!_blink.isAnimating) unawaited(_blink.repeat(reverse: true));
    } else {
      if (_blink.isAnimating) _blink.stop();
      _blink.value = 1;
    }

    final row = <Widget>[];
    for (var i = 0; i < widget.length; i++) {
      row.add(
        _OtpSlot(
          character: i < text.length ? text[i] : null,
          active: i == active,
          error: widget.error,
          enabled: widget.enabled,
          obscure: widget.obscure,
          scale: scale,
          blink: _blink,
          visuals: v,
          colors: colors,
        ),
      );
      if (separators.contains(i)) {
        row.add(_OtpSeparator(visuals: v, scale: scale));
      }
    }

    final editable = EditableText(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: !widget.enabled,
      rendererIgnoresPointer: true,
      showCursor: false,
      cursorWidth: 0,
      style: v.textStyle.copyWith(color: const Color(0x00000000)),
      cursorColor: const Color(0x00000000),
      backgroundCursorColor: const Color(0x00000000),
      selectionColor: const Color(0x00000000),
      keyboardType: widget.validation == FossOtpValidation.numeric
          ? TextInputType.number
          : TextInputType.text,
      textInputAction: TextInputAction.done,
      inputFormatters: _formatters,
      autofocus: widget.autofocus,
      autofillHints: const [AutofillHints.oneTimeCode],
      textAlign: TextAlign.center,
      enableInteractiveSelection: widget.enabled,
    );

    return MergeSemantics(
      child: Semantics(
        label: widget.semanticsLabel ?? 'Verification code',
        textField: true,
        enabled: widget.enabled,
        // Read back progress: masked as dots when obscured, else the digits.
        value: widget.obscure
            ? '•' * _controller.text.length
            : _controller.text,
        // A tap outside releases focus and dismisses the keyboard, as touch
        // users expect.
        child: TapRegion(
          onTapOutside: (_) {
            if (_focusNode.hasFocus) _focusNode.unfocus();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _handleTap,
            child: Stack(
              children: [
                Positioned.fill(child: editable),
                ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: v.gap * scale,
                    children: row,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single OTP slot: the shared field box chrome around a centered character,
/// masked dot, or blinking caret.
class _OtpSlot extends StatelessWidget {
  const _OtpSlot({
    required this.character,
    required this.active,
    required this.error,
    required this.enabled,
    required this.obscure,
    required this.scale,
    required this.blink,
    required this.visuals,
    required this.colors,
  });

  final String? character;
  final bool active;
  final bool error;
  final bool enabled;
  final bool obscure;
  final double scale;
  final Animation<double> blink;
  final _OtpVisuals visuals;
  final FossColors colors;

  @override
  Widget build(BuildContext context) {
    final size = visuals.slotSize * scale;
    final font = (visuals.textStyle.fontSize ?? 16) * scale;

    final Widget content;
    final char = character;
    if (char != null) {
      content = obscure
          ? _dot(font)
          : Text(
              char,
              textAlign: TextAlign.center,
              textHeightBehavior: const TextHeightBehavior(
                leadingDistribution: TextLeadingDistribution.even,
              ),
              style: visuals.textStyle.copyWith(color: visuals.textColor),
            );
    } else if (active) {
      content = _caret(font);
    } else {
      content = const SizedBox.shrink();
    }

    return FossFieldBox(
      enabled: enabled,
      hasError: error,
      focused: active,
      background: visuals.background,
      borderColor: visuals.borderColor,
      ringColor: colors.ring,
      destructiveColor: colors.destructive,
      borderRadius: visuals.borderRadius,
      minHeight: size,
      shadow: visuals.shadow,
      isDark: colors.isDark,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: content),
      ),
    );
  }

  Widget _dot(double font) => SizedBox(
    width: font * 0.5,
    height: font * 0.5,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.textColor,
        shape: BoxShape.circle,
      ),
    ),
  );

  Widget _caret(double font) => FadeTransition(
    opacity: blink,
    child: SizedBox(
      width: 2 * scale,
      height: font,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: visuals.textColor,
          borderRadius: BorderRadius.circular(FossRadii.full),
        ),
      ),
    ),
  );
}

/// The pill divider between two groups: a full-radius bar in the border color.
class _OtpSeparator extends StatelessWidget {
  const _OtpSeparator({required this.visuals, required this.scale});

  final _OtpVisuals visuals;
  final double scale;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: visuals.separatorSize.width * scale,
    height: visuals.separatorSize.height * scale,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: visuals.separatorColor,
        borderRadius: BorderRadius.circular(FossRadii.full),
      ),
    ),
  );
}

/// Builds the default slot appearance for a [size] from the theme tokens.
_OtpVisuals _resolve(FossThemeData theme, FossOtpFieldSize size) {
  final c = theme.colors;
  final (slotSize, textStyle) = switch (size) {
    FossOtpFieldSize.md => (36.0, theme.typography.base),
    FossOtpFieldSize.lg => (40.0, theme.typography.lg),
  };

  // Dark adds a faint lift over the surface: the input color at 32% of its
  // alpha, composited to opaque. Light is the bare surface.
  final fill = c.isDark
      ? Color.alphaBlend(
          c.input.withValues(alpha: c.input.a * _darkFillOpacity),
          c.background,
        )
      : c.background;

  return _OtpVisuals(
    background: fill,
    borderColor: c.input,
    textColor: c.foreground,
    borderRadius: theme.radii.lg,
    slotSize: slotSize,
    textStyle: textStyle,
    gap: theme.spacing(2),
    shadow: theme.shadows.xs,
    separatorColor: c.input,
    separatorSize: const Size(12, 2),
  );
}

/// Lays a per-instance [override] over the resolved [base], field by field.
_OtpVisuals _apply(_OtpVisuals base, FossOtpFieldStyle? override) {
  if (override == null) return base;
  return _OtpVisuals(
    background: override.backgroundColor ?? base.background,
    borderColor: override.borderColor ?? base.borderColor,
    textColor: base.textColor,
    borderRadius: override.borderRadius ?? base.borderRadius,
    slotSize: override.slotSize ?? base.slotSize,
    textStyle: override.textStyle ?? base.textStyle,
    gap: override.gap ?? base.gap,
    shadow: override.shadow ?? base.shadow,
    separatorColor: override.separatorColor ?? base.separatorColor,
    separatorSize: override.separatorSize ?? base.separatorSize,
  );
}
