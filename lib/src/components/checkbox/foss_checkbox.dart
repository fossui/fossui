import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';
import 'package:fossui/src/icons/foss_glyph.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_checkbox_group.dart';
part 'foss_checkbox_style.dart';

const double _boxSize = 18;
const double _glyphSize = 14;
const double _boxRadius = 4;
const double _ringWidth = 2;
const double _ringOffset = 1;
const double _disabledOpacity = 0.64;
const double _minTapTarget = 48;

// Error border and ring alphas: the border deepens when the box is focused, the
// ring lifts in dark mode.
const double _errorBorderOpacity = 0.36;
const double _errorBorderFocusedOpacity = 0.64;
const double _errorRingOpacityLight = 0.48;
const double _errorRingOpacityDark = 0.24;

// Dark surfaces lift the resting fill by the input color at 32% of its alpha.
const double _darkFillOpacity = 0.32;

// Card variant: the checked or hovered card lifts its fill with the accent
// role, the checked card lifts its border to the primary role.
const double _cardCheckedBorderOpacity = 0.48;
const double _cardFillOpacity = 0.5;

// Inner top-lit rim at rest: a faint dark line in light mode, a faint white
// highlight in dark mode.
const Color _rimLight = Color(0x0A000000);
const Color _rimDark = Color(0x0FFFFFFF);

/// A checkbox: an independent on / off toggle that can also show an
/// indeterminate state.
///
/// [value] is tristate: `true` checked, `false` unchecked, `null` indeterminate
/// (the minus glyph). A tap reports the new definite state through [onChanged]:
/// unchecked and indeterminate go to `true`, checked goes to `false`. The
/// checkbox never produces `null` itself; set [value] to `null` to drive the
/// indeterminate state. `onChanged: null` (or `enabled: false`) disables it.
///
/// Renders a square box with an optional [label] and [description]. A non-null
/// [errorText] marks it invalid and shows a caption below. Colors, type, and
/// spacing come from `context.fossTheme`; pass a [FossCheckboxStyle] to [style]
/// for a one-off.
///
/// For a multi-select set of options, see [FossCheckboxGroup].
///
/// ```dart
/// FossCheckbox(
///   value: accepted,
///   label: 'Accept terms and conditions',
///   onChanged: (checked) => setState(() => accepted = checked),
/// );
/// ```
class FossCheckbox extends StatelessWidget {
  /// Creates a checkbox. [value] is `true`, `false`, or `null` (indeterminate).
  const FossCheckbox({
    this.value = false,
    this.onChanged,
    this.label,
    this.description,
    this.errorText,
    this.enabled = true,
    this.style,
    super.key,
  });

  /// The checked state: `true`, `false`, or `null` for indeterminate.
  final bool? value;

  /// Called with the new definite state on a tap. Null disables the checkbox.
  final ValueChanged<bool>? onChanged;

  /// Optional title beside the box.
  final String? label;

  /// Optional secondary line below the [label].
  final String? description;

  /// Error caption below the control. A non-null value marks it invalid.
  final String? errorText;

  /// Whether the checkbox accepts input. Disabled when false or when
  /// [onChanged] is null.
  final bool enabled;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossCheckboxStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final active = enabled && onChanged != null;
    final checked = value ?? false;
    final indeterminate = value == null;

    final control = _FossCheckboxControl(
      checked: checked,
      indeterminate: indeterminate,
      enabled: active,
      hasError: errorText != null,
      card: false,
      label: label,
      description: description,
      style: style,
      onToggle: active ? () => onChanged!(value != true) : null,
    );

    if (errorText case final text?) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: theme.spacing(2),
        children: [
          control,
          Semantics(
            liveRegion: true,
            child: Text(
              text,
              style: theme.typography.xs.copyWith(
                color: theme.colors.destructiveForeground,
              ),
            ),
          ),
        ],
      );
    }
    return control;
  }
}

/// The shared box, texts, gesture, focus, and semantics for one checkbox.
/// [FossCheckbox] and [FossCheckboxItem] both delegate their rendering here so
/// the control looks identical standalone or inside a group.
class _FossCheckboxControl extends StatefulWidget {
  const _FossCheckboxControl({
    required this.checked,
    required this.indeterminate,
    required this.enabled,
    required this.hasError,
    required this.card,
    required this.label,
    required this.description,
    required this.style,
    required this.onToggle,
  });

  final bool checked;
  final bool indeterminate;
  final bool enabled;
  final bool hasError;
  final bool card;
  final String? label;
  final String? description;
  final FossCheckboxStyle? style;
  final VoidCallback? onToggle;

  @override
  State<_FossCheckboxControl> createState() => _FossCheckboxControlState();
}

class _FossCheckboxControlState extends State<_FossCheckboxControl> {
  final WidgetStatesController _states = WidgetStatesController();

  @override
  void dispose() {
    _states.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _resolve(theme, widget.style);
    final hasText = widget.label != null || widget.description != null;

    Widget option = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: widget.card ? MainAxisSize.max : MainAxisSize.min,
      spacing: v.gap,
      children: [
        _boxSlot(theme, v, hasText: hasText),
        if (hasText) Flexible(child: _texts(theme, v)),
      ],
    );

    if (widget.card) {
      option = _cardSurface(theme, child: option);
    }
    if (!widget.enabled) {
      option = Opacity(opacity: _disabledOpacity, child: option);
    }

    // One merged node carries the checkbox role plus the label and description
    // so assistive tech announces the option once, not twice.
    return MergeSemantics(
      child: Semantics(
        checked: widget.checked,
        mixed: widget.indeterminate ? true : null,
        enabled: widget.enabled,
        child: FocusableActionDetector(
          enabled: widget.enabled,
          mouseCursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onShowFocusHighlight: (value) =>
              _states.update(WidgetState.focused, value),
          // Only the card surface reacts to hover; the bare box does not, so
          // skip the hover state (and its rebuild) outside the card variant.
          onShowHoverHighlight: widget.card
              ? (value) => _states.update(WidgetState.hovered, value)
              : null,
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onToggle?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onToggle,
            // The card supplies its own padded hit area; the plain option is
            // floored to the minimum tap target around its content.
            child: widget.card
                ? option
                : ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: _minTapTarget,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      heightFactor: 1,
                      child: option,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // The box, aligned to the first text line when a label or description is
  // present so it centers on the title rather than the whole text block.
  Widget _boxSlot(
    FossThemeData theme,
    _CheckboxVisuals v, {
    required bool hasText,
  }) {
    final box = ListenableBuilder(
      listenable: _states,
      builder: (_, _) => _box(theme, v),
    );
    if (!hasText) return box;
    final firstLine = widget.label != null ? v.labelStyle : v.descriptionStyle;
    final line = (firstLine.fontSize ?? 16) * (firstLine.height ?? 1);
    return SizedBox(
      height: line,
      child: Center(widthFactor: 1, child: box),
    );
  }

  Widget _box(FossThemeData theme, _CheckboxVisuals v) {
    final colors = theme.colors;
    final dark = colors.isDark;
    final focused = _states.value.contains(WidgetState.focused);
    final checked = widget.checked;
    final showBorder = !checked;

    // Border stays the resting input color except when invalid, where it
    // deepens and the focus ring switches to the destructive role.
    var borderColor = v.borderColor;
    var ringColor = focused ? colors.ring : null;
    if (widget.hasError) {
      if (showBorder) {
        borderColor = colors.destructive.withValues(
          alpha: focused ? _errorBorderFocusedOpacity : _errorBorderOpacity,
        );
      }
      if (focused) {
        ringColor = colors.destructive.withValues(
          alpha: dark ? _errorRingOpacityDark : _errorRingOpacityLight,
        );
      }
    }

    // The resting shadow and inner rim sit on the unchecked and indeterminate
    // box; they drop when checked, invalid, or disabled.
    final atRest = !checked && !widget.hasError && widget.enabled;

    Widget box = SizedBox.square(
      dimension: v.boxSize,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: checked ? v.checkedColor : v.uncheckedFill,
          shape: RoundedSuperellipseBorder(
            side: showBorder ? BorderSide(color: borderColor) : BorderSide.none,
            borderRadius: BorderRadius.circular(_boxRadius),
          ),
          shadows: atRest ? v.shadow : const [],
        ),
        child: _glyph(v),
      ),
    );

    if (atRest) {
      box = CustomPaint(
        foregroundPainter: _RimPainter(
          color: dark ? _rimDark : _rimLight,
          topLit: dark,
        ),
        child: box,
      );
    }

    if (ringColor != null) {
      box = CustomPaint(
        foregroundPainter: _RingPainter(
          color: ringColor,
          offsetColor: colors.background,
        ),
        child: box,
      );
    }

    return box;
  }

  // The centered glyph: a checkmark when checked, a minus when indeterminate,
  // nothing when unchecked. Painted in-package, so no icon dependency.
  Widget? _glyph(_CheckboxVisuals v) {
    if (!widget.checked && !widget.indeterminate) return null;
    return Center(
      child: FossGlyphIcon(
        widget.checked ? CheckGlyph(v.checkColor) : MinusGlyph(v.minusColor),
        size: v.glyphSize,
      ),
    );
  }

  Widget _texts(FossThemeData theme, _CheckboxVisuals v) {
    final colors = theme.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing(1.5),
      children: [
        if (widget.label case final label?)
          Text(label, style: v.labelStyle.copyWith(color: colors.foreground)),
        if (widget.description case final description?)
          Text(
            description,
            style: v.descriptionStyle.copyWith(color: colors.mutedForeground),
          ),
      ],
    );
  }

  // Wraps an option in the card surface: a bordered, padded box that lifts its
  // border when checked and tints its fill when checked or hovered. A min
  // content height keeps the card past the tap-target floor.
  Widget _cardSurface(FossThemeData theme, {required Widget child}) {
    final colors = theme.colors;
    return ListenableBuilder(
      listenable: _states,
      builder: (_, _) {
        final hovered = _states.value.contains(WidgetState.hovered);
        final tinted = widget.checked || hovered;
        return DecoratedBox(
          decoration: ShapeDecoration(
            // accent at 50% of its own alpha: the accent
            // role is already a faint translucent tint, so this is a
            // barely-there wash, not a half-opaque fill.
            color: tinted
                ? colors.accent.withValues(
                    alpha: colors.accent.a * _cardFillOpacity,
                  )
                : null,
            shape: RoundedSuperellipseBorder(
              side: BorderSide(
                color: widget.checked
                    ? colors.primary.withValues(
                        alpha: _cardCheckedBorderOpacity,
                      )
                    : colors.border,
              ),
              borderRadius: BorderRadius.circular(theme.radii.lg),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(theme.spacing(3)),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: theme.spacing(6)),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Builds the default appearance from the theme tokens, then lays a
/// per-instance [override] over it field by field.
_CheckboxVisuals _resolve(FossThemeData theme, FossCheckboxStyle? override) {
  final c = theme.colors;

  // Dark adds a faint lift to the resting box: the input color at 32% of its
  // alpha, composited to opaque. Light is the bare surface.
  final uncheckedFill = c.isDark
      ? Color.alphaBlend(
          c.input.withValues(alpha: c.input.a * _darkFillOpacity),
          c.background,
        )
      : c.background;

  return _CheckboxVisuals(
    uncheckedFill: override?.backgroundColor ?? uncheckedFill,
    checkedColor: override?.checkedColor ?? c.primary,
    checkColor: override?.checkColor ?? c.primaryForeground,
    minusColor: c.foreground,
    borderColor: override?.borderColor ?? c.input,
    shadow: override?.shadow ?? theme.shadows.xs,
    boxSize: override?.boxSize ?? _boxSize,
    glyphSize: override?.glyphSize ?? _glyphSize,
    gap: override?.gap ?? theme.spacing(2),
    labelStyle: override?.labelStyle ?? theme.typography.base,
    descriptionStyle: override?.descriptionStyle ?? theme.typography.xs,
  );
}

/// The fully resolved, non-null appearance. The widget reads only non-null
/// fields and never needs the null-assertion operator.
@immutable
class _CheckboxVisuals {
  const _CheckboxVisuals({
    required this.uncheckedFill,
    required this.checkedColor,
    required this.checkColor,
    required this.minusColor,
    required this.borderColor,
    required this.shadow,
    required this.boxSize,
    required this.glyphSize,
    required this.gap,
    required this.labelStyle,
    required this.descriptionStyle,
  });

  final Color uncheckedFill;
  final Color checkedColor;
  final Color checkColor;
  final Color minusColor;
  final Color borderColor;
  final List<BoxShadow> shadow;
  final double boxSize;
  final double glyphSize;
  final double gap;
  final TextStyle labelStyle;
  final TextStyle descriptionStyle;
}

/// Builds the superellipse outline of a box [rect] with corner [radius].
Path _boxPath(Rect rect, double radius) => RoundedSuperellipseBorder(
  borderRadius: BorderRadius.circular(radius),
).getOuterPath(rect);

/// Paints a 1px rim inside the box: brightest along one edge, fading to nothing
/// by the center. [topLit] lights the top edge; otherwise the bottom.
class _RimPainter extends CustomPainter {
  const _RimPainter({required this.color, required this.topLit});

  final Color color;
  final bool topLit;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final shader = LinearGradient(
      begin: topLit ? Alignment.topCenter : Alignment.bottomCenter,
      end: Alignment.center,
      colors: [color, color.withValues(alpha: 0)],
    ).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(_boxPath(rect, _boxRadius), paint);
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.color != color || old.topLit != topLit;
}

/// Paints the focus ring: a superellipse outset just past the box edge, with a
/// 1px gap (the offset). The gap is filled with [offsetColor] (the surface) so
/// the ring reads as detached even over a tinted card.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.offsetColor});

  final Color color;
  final Color offsetColor;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas
      ..drawPath(
        _boxPath(box.inflate(_ringOffset / 2), _boxRadius + _ringOffset / 2),
        Paint()
          ..color = offsetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringOffset,
      )
      ..drawPath(
        _boxPath(
          box.inflate(_ringOffset + _ringWidth / 2),
          _boxRadius + _ringOffset + _ringWidth / 2,
        ),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.offsetColor != offsetColor;
}
