import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_text_field_style.dart';

const double _iconSize = 18;
const double _disabledOpacity = 0.64;

// Leading and trailing icon glyphs sit at 80% of the text color so they read as
// quieter than the value.
const double _affixOpacity = 0.8;
const double _minTapTarget = 48;
const double _ringWidth = 3;

// Placeholder text sits at 72% of the muted-foreground alpha.
const double _placeholderOpacity = 0.72;

// Error border and ring alphas: the border deepens when the field is focused,
// the ring stays faint and lifts in dark mode.
const double _errorBorderOpacity = 0.36;
const double _errorBorderFocusedOpacity = 0.64;
const double _errorRingOpacityLight = 0.16;
const double _errorRingOpacityDark = 0.24;

// The focus ring is the ring color at a low alpha.
const double _focusRingOpacity = 0.24;

// Dark surfaces lift the fill by the input color at 32% of its alpha.
const double _darkFillOpacity = 0.32;

// The label tightens its line height to 18px against the 16px base.
const double _labelLineHeight = 18 / 16;

// Inner top-lit rim at rest: a faint dark line in light mode, a faint white
// highlight in dark mode.
const Color _rimLight = Color(0x0A000000);
const Color _rimDark = Color(0x0FFFFFFF);

/// The size of a [FossTextField].
enum FossTextFieldSize {
  /// Compact: 30 logical pixels tall.
  sm,

  /// Default: 34 logical pixels tall.
  md,

  /// Prominent: 38 logical pixels tall.
  lg,
}

/// A text field in the fossui style.
///
/// Pairs an editable box with an optional [label] above and a [helperText] or
/// [errorText] caption below. Colors, radius, type, and spacing come from
/// `context.fossTheme`, so a global retheme restyles every field. For a
/// one-off, pass a [FossTextFieldStyle] to [style].
///
/// Single line by default. Set [maxLines] to anything other than 1 (or null to
/// grow without bound) for a multiline textarea: it grows with content,
/// top-aligns its text, and takes no [leading] / [trailing] icons.
///
/// A non-null [errorText] puts the field in its invalid state and replaces the
/// helper caption. Passing `enabled: false` disables it. [leading] and
/// [trailing] take any widget (icon-agnostic) and are themed to match the text.
///
/// The [controller] and [focusNode] are optional; when omitted, the field
/// creates and disposes its own.
///
/// ```dart
/// FossTextField(
///   label: 'Email',
///   hintText: 'you@example.com',
///   helperText: 'We never share it.',
///   keyboardType: TextInputType.emailAddress,
///   leading: const Icon(LucideIcons.mail),
///   onChanged: (value) => setState(() => email = value),
/// );
/// ```
class FossTextField extends StatefulWidget {
  /// Creates a text field. All fields are optional; the most common pairing is
  /// a [label] with an [onChanged] callback or a [controller].
  const FossTextField({
    this.controller,
    this.focusNode,
    this.size = FossTextFieldSize.md,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.leading,
    this.trailing,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.minLines,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.style,
    super.key,
  }) : assert(
         maxLines == 1 || (leading == null && trailing == null),
         'leading and trailing are single-line only; a multiline field has no '
         'icon rail',
       );

  /// Holds the editable text. Created and disposed internally when null.
  final TextEditingController? controller;

  /// Manages keyboard focus. Created and disposed internally when null.
  final FocusNode? focusNode;

  /// The size. Defaults to [FossTextFieldSize.md].
  final FossTextFieldSize size;

  /// Optional label rendered above the box.
  final String? label;

  /// Placeholder shown while the field is empty.
  final String? hintText;

  /// Helper caption below the box. Hidden when [errorText] is set.
  final String? helperText;

  /// Error caption below the box. A non-null value marks the field invalid and
  /// replaces [helperText].
  final String? errorText;

  /// Whether the field accepts input. When false it dims and stops responding.
  final bool enabled;

  /// Optional widget before the editable content, themed as an icon.
  final Widget? leading;

  /// Optional widget after the editable content, themed as an icon.
  final Widget? trailing;

  /// Whether to hide the text, for passwords. Defaults to false.
  final bool obscureText;

  /// The keyboard layout to request.
  final TextInputType? keyboardType;

  /// The action button on the keyboard (next, done, search, ...).
  final TextInputAction? textInputAction;

  /// Starting line count for a multiline field. Ignored when [maxLines] is 1.
  final int? minLines;

  /// Maximum visible lines. The default 1 is a single-line input; any other
  /// value (including null, which grows without bound) makes the field a
  /// multiline textarea: it grows with content, top-aligns its text, and drops
  /// the [leading] / [trailing] slots.
  final int? maxLines;

  /// Called whenever the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits from the keyboard action button.
  final ValueChanged<String>? onSubmitted;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossTextFieldStyle? style;

  @override
  State<FossTextField> createState() => _FossTextFieldState();
}

class _FossTextFieldState extends State<FossTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  final GlobalKey<EditableTextState> _editableKey =
      GlobalKey<EditableTextState>();

  late final TextSelectionGestureDetectorBuilder _gestureBuilder =
      TextSelectionGestureDetectorBuilder(delegate: this);

  // The active controller and focus node, always resolved to a non-null value:
  // the supplied one when given, otherwise an internally created one. The
  // `_owned` references hold only what this state created, so dispose touches
  // exactly those and never a caller's instance.
  late TextEditingController _controller;
  late FocusNode _focusNode;
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;

  @override
  GlobalKey<EditableTextState> get editableTextKey => _editableKey;

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => widget.enabled;

  @override
  void initState() {
    super.initState();
    final controller = widget.controller;
    _controller = controller ?? (_ownedController = TextEditingController());
    final focusNode = widget.focusNode;
    _focusNode = focusNode ?? (_ownedFocusNode = FocusNode());
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(FossTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _ownedController?.dispose();
      final controller = widget.controller;
      if (controller != null) {
        _ownedController = null;
        _controller = controller;
      } else {
        _controller = _ownedController = TextEditingController(
          text: oldWidget.controller?.text,
        );
      }
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      _ownedFocusNode?.dispose();
      final focusNode = widget.focusNode;
      if (focusNode != null) {
        _ownedFocusNode = null;
        _focusNode = focusNode;
      } else {
        _focusNode = _ownedFocusNode = FocusNode();
      }
      _focusNode.addListener(_onFocusChanged);
    }
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _ownedController?.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _apply(_resolve(theme, widget.size), widget.style);

    final hasError = widget.errorText != null;
    final focused = _focusNode.hasFocus && widget.enabled;

    final box = _buildBox(theme, v, hasError: hasError, focused: focused);

    final caption = widget.errorText ?? widget.helperText;
    final captionColor = hasError
        ? theme.colors.destructiveForeground
        : v.helperColor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: theme.spacing(2),
      children: [
        // The editable carries the field's accessible name, so the visible
        // label is excluded from semantics to avoid announcing it twice.
        if (widget.label case final label?)
          ExcludeSemantics(
            child: Opacity(
              opacity: widget.enabled ? 1 : _disabledOpacity,
              child: Text(
                label,
                style: v.labelStyle.copyWith(color: v.labelColor),
              ),
            ),
          ),
        box,
        if (caption case final text?)
          Semantics(
            liveRegion: hasError,
            child: Text(
              text,
              style: v.helperStyle.copyWith(color: captionColor),
            ),
          ),
      ],
    );
  }

  Widget _buildBox(
    FossThemeData theme,
    _FieldVisuals v, {
    required bool hasError,
    required bool focused,
  }) {
    final colors = theme.colors;

    // Border, ring, and shadow are derived from the field state. The resting
    // shadow drops whenever the field is focused, invalid, or disabled.
    final Color borderColor;
    final Color? ringColor;
    if (hasError) {
      borderColor = colors.destructive.withValues(
        alpha: focused ? _errorBorderFocusedOpacity : _errorBorderOpacity,
      );
      final errorRingAlpha = colors.isDark
          ? _errorRingOpacityDark
          : _errorRingOpacityLight;
      ringColor = focused
          ? colors.destructive.withValues(alpha: errorRingAlpha)
          : null;
    } else if (focused) {
      borderColor = colors.ring;
      ringColor = colors.ring.withValues(alpha: _focusRingOpacity);
    } else {
      borderColor = v.borderColor;
      ringColor = null;
    }

    final showShadow = widget.enabled && !focused && !hasError;

    // A multiline field grows with its text: top-align the content, add
    // vertical padding, size the min height to the starting line count, and
    // drop the single-line icon rail.
    final multiline = widget.maxLines != 1;
    // Vertical inset trims 1px against the border, matching the horizontal
    // inset.
    final padding = multiline
        ? v.padding.add(EdgeInsets.symmetric(vertical: theme.spacing(1.5) - 1))
        : v.padding;

    Widget content = Padding(
      padding: padding,
      child: Row(
        spacing: v.gap,
        crossAxisAlignment: multiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (widget.leading case final leading? when !multiline)
            IconTheme.merge(data: v.iconTheme, child: leading),
          Expanded(child: _buildEditable(theme, v)),
          if (widget.trailing case final trailing? when !multiline)
            IconTheme.merge(data: v.iconTheme, child: trailing),
        ],
      ),
    );

    content = DecoratedBox(
      decoration: ShapeDecoration(
        color: v.background,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: borderColor),
          borderRadius: BorderRadius.circular(v.borderRadius),
        ),
        shadows: showShadow ? v.shadow : const [],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: multiline ? _multilineMinHeight(theme, v) : v.minHeight,
        ),
        child: content,
      ),
    );

    if (ringColor != null) {
      content = CustomPaint(
        foregroundPainter: _RingPainter(
          color: ringColor,
          radius: v.borderRadius,
        ),
        child: content,
      );
    }

    // At rest, a 1px inner rim; dropped under the same states as the shadow.
    // Dark lights the top edge with a white highlight, light darkens the bottom
    // edge. Rim radius is the inner edge (radius - 1).
    if (showShadow) {
      final dark = colors.isDark;
      content = CustomPaint(
        foregroundPainter: _RimPainter(
          color: dark ? _rimDark : _rimLight,
          radius: v.borderRadius - 1,
          topLit: dark,
        ),
        child: content,
      );
    }

    if (!widget.enabled) {
      content = Opacity(opacity: _disabledOpacity, child: content);
      return _withMinTapTarget(content);
    }

    // The selection gesture detector requests focus on tap and positions the
    // caret; translucent so taps anywhere in the box reach it.
    return _gestureBuilder.buildGestureDetector(
      behavior: HitTestBehavior.translucent,
      child: _withMinTapTarget(content),
    );
  }

  Widget _buildEditable(FossThemeData theme, _FieldVisuals v) {
    final colors = theme.colors;
    final multiline = widget.maxLines != 1;
    final editable = EditableText(
      key: _editableKey,
      controller: _controller,
      focusNode: _focusNode,
      readOnly: !widget.enabled,
      rendererIgnoresPointer: true,
      style: v.textStyle.copyWith(color: v.textColor),
      // The base type's line-height adds leading; distributed proportionally
      // (the default) most of it lands above the glyph and drops it below
      // center, so it is split evenly to center the text in the box.
      textHeightBehavior: const TextHeightBehavior(
        leadingDistribution: TextLeadingDistribution.even,
      ),
      cursorColor: colors.foreground,
      backgroundCursorColor: colors.mutedForeground,
      selectionColor: colors.ring.withValues(alpha: _focusRingOpacity),
      cursorOpacityAnimates: true,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      enableInteractiveSelection: widget.enabled,
    );

    final hint = widget.hintText;
    return MergeSemantics(
      child: Semantics(
        label: widget.label,
        textField: true,
        multiline: multiline,
        enabled: widget.enabled,
        child: Stack(
          children: [
            if (hint != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? IgnorePointer(
                        child: Text(
                          hint,
                          maxLines: widget.maxLines,
                          overflow: multiline
                              ? TextOverflow.clip
                              : TextOverflow.ellipsis,
                          style: v.textStyle.copyWith(color: v.hintColor),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            editable,
          ],
        ),
      ),
    );
  }

  // Minimum box height for a multiline field: the starting line count times the
  // resolved line height, plus the vertical padding. Defaults to 3 lines when
  // [minLines] is unset, matching the reference textarea's resting size.
  double _multilineMinHeight(FossThemeData theme, _FieldVisuals v) {
    final lines = widget.minLines ?? 3;
    final style = v.textStyle;
    final lineHeight = (style.height ?? 1.5) * (style.fontSize ?? 16);
    return lines * lineHeight + (theme.spacing(1.5) - 1) * 2;
  }

  // Centers the box in a region at least [_minTapTarget] tall so the field
  // meets the minimum touch-target guideline without inflating its height.
  Widget _withMinTapTarget(Widget box) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: _minTapTarget),
    child: Center(heightFactor: 1, child: box),
  );
}

/// Builds the default appearance for a [size] from the theme tokens.
_FieldVisuals _resolve(FossThemeData theme, FossTextFieldSize size) {
  final c = theme.colors;

  // Horizontal inset from the spacing scale: sm sits tighter than md and lg.
  // The border paints over the edge without consuming layout, so the inset is
  // the padding alone and needs no border compensation.
  final (minHeight, padX) = switch (size) {
    FossTextFieldSize.sm => (30.0, theme.spacing(2.5)),
    FossTextFieldSize.md => (34.0, theme.spacing(3)),
    FossTextFieldSize.lg => (38.0, theme.spacing(3)),
  };

  // Dark adds a faint lift over the surface: the input color at 32% of its
  // alpha, composited to opaque. Light is the bare surface.
  final fill = c.isDark
      ? Color.alphaBlend(
          c.input.withValues(alpha: c.input.a * _darkFillOpacity),
          c.background,
        )
      : c.background;

  return _FieldVisuals(
    background: fill,
    borderColor: c.input,
    textColor: c.foreground,
    hintColor: c.mutedForeground.withValues(alpha: _placeholderOpacity),
    labelColor: c.foreground,
    helperColor: c.mutedForeground,
    borderRadius: theme.radii.lg,
    padding: EdgeInsets.symmetric(horizontal: padX),
    minHeight: minHeight,
    textStyle: theme.typography.base,
    // The label uses the tightened 18px line height.
    labelStyle: theme.typography.base.medium.copyWith(height: _labelLineHeight),
    helperStyle: theme.typography.xs,
    iconSize: _iconSize,
    gap: theme.spacing(2),
    shadow: theme.shadows.xs,
  );
}

/// Lays a per-instance [override] over the resolved [base], field by field.
_FieldVisuals _apply(_FieldVisuals base, FossTextFieldStyle? override) {
  if (override == null) return base;
  return _FieldVisuals(
    background: override.backgroundColor ?? base.background,
    borderColor: override.borderColor ?? base.borderColor,
    textColor: base.textColor,
    hintColor: base.hintColor,
    labelColor: base.labelColor,
    helperColor: base.helperColor,
    borderRadius: override.borderRadius ?? base.borderRadius,
    padding: override.contentPadding ?? base.padding,
    minHeight: override.minHeight ?? base.minHeight,
    textStyle: override.textStyle ?? base.textStyle,
    labelStyle: override.labelStyle ?? base.labelStyle,
    helperStyle: override.helperStyle ?? base.helperStyle,
    iconSize: override.iconSize ?? base.iconSize,
    gap: override.gap ?? base.gap,
    shadow: override.shadow ?? base.shadow,
  );
}

/// The fully resolved, non-null appearance for one size. A [FossTextFieldStyle]
/// override is laid over it by [_apply], so the widget reads only non-null
/// fields and never needs the null-assertion operator.
@immutable
class _FieldVisuals {
  const _FieldVisuals({
    required this.background,
    required this.borderColor,
    required this.textColor,
    required this.hintColor,
    required this.labelColor,
    required this.helperColor,
    required this.borderRadius,
    required this.padding,
    required this.minHeight,
    required this.textStyle,
    required this.labelStyle,
    required this.helperStyle,
    required this.iconSize,
    required this.gap,
    required this.shadow,
  });

  final Color background;
  final Color borderColor;
  final Color textColor;
  final Color hintColor;
  final Color labelColor;
  final Color helperColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final TextStyle textStyle;
  final TextStyle labelStyle;
  final TextStyle helperStyle;
  final double iconSize;
  final double gap;
  final List<BoxShadow> shadow;

  IconThemeData get iconTheme => IconThemeData(
    size: iconSize,
    color: textColor.withValues(alpha: textColor.a * _affixOpacity),
  );
}

/// Paints a 1px rim inside the field: brightest along one edge, fading to
/// nothing by the middle. [topLit] lights the top edge; otherwise the bottom.
class _RimPainter extends CustomPainter {
  const _RimPainter({
    required this.color,
    required this.radius,
    required this.topLit,
  });

  final Color color;
  final double radius;
  final bool topLit;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    final shape = RSuperellipse.fromRectAndRadius(
      rect,
      Radius.circular(radius),
    );
    final shader = LinearGradient(
      begin: topLit ? Alignment.topCenter : Alignment.bottomCenter,
      end: Alignment.center,
      colors: [color, color.withValues(alpha: 0)],
    ).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRSuperellipse(shape, paint);
  }

  @override
  bool shouldRepaint(_RimPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.radius != radius ||
      oldDelegate.topLit != topLit;
}

/// Paints the focus ring: a superellipse outset just past the field edge,
/// matching its corner shape so it reads smooth, not circular.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).inflate(_ringWidth);
    final shape = RSuperellipse.fromRectAndRadius(
      rect,
      Radius.circular(radius + _ringWidth),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _ringWidth;
    canvas.drawRSuperellipse(shape, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
