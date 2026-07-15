import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/combobox/foss_combobox.dart';
import 'package:fossui/src/foundation/foss_field_box.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_text_field_style.dart';
part 'foss_text_field_view.dart';
part 'foss_text_field_visuals.dart';

const double _disabledOpacity = 0.64;

/// The size of a [FossTextField].
enum FossTextFieldSize {
  /// Compact: 30 logical pixels tall.
  sm,

  /// Default: 34 logical pixels tall.
  md,

  /// Prominent: 38 logical pixels tall.
  lg,
}

/// {@category Inputs}
/// {@template foss.text-field.preview}
/// <img src="https://fossui.org/components/text-field/overview/light.png"
///   alt="FossTextField, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/text-field/overview/dark.png"
///   alt="FossTextField, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [text field documentation ↗](https://fossui.org/docs/components/text-field) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/#/?path=components/text_field/fosstextfield/playground).
/// {@endtemplate}
///
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
/// Text can be selected and edited, but the field shows no copy and paste
/// selection toolbar: it builds on the widgets layer and takes no platform
/// selection controls.
///
/// {@macro foss.customize}
///
/// See also [FossAutocomplete] for a field with a filtered dropdown.
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
  /// {@macro foss.text-field.preview}
  ///
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
  ///
  /// Swapping a provided controller for null carries the text over, but not the
  /// selection or the listeners on the old controller.
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
    // A field disabled mid-edit must not keep focus, or traversal sits on a
    // dead field and the keyboard stays up.
    if (oldWidget.enabled && !widget.enabled && _focusNode.hasFocus) {
      _focusNode.unfocus();
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

    // A multiline field grows with its text: top-align the content, add
    // vertical padding, size the min height to the starting line count, and
    // drop the single-line icon rail.
    final multiline = widget.maxLines != 1;
    // Vertical inset trims 1px against the border, matching the horizontal
    // inset.
    final padding = multiline
        ? v.padding.add(EdgeInsets.symmetric(vertical: theme.spacing(1.5) - 1))
        : v.padding;

    final box = FossFieldBox(
      enabled: widget.enabled,
      hasError: hasError,
      focused: focused,
      background: v.background,
      borderColor: v.borderColor,
      ringColor: colors.ring,
      destructiveColor: colors.destructive,
      borderRadius: v.borderRadius,
      minHeight: multiline ? _multilineMinHeight(theme, v) : v.minHeight,
      shadow: v.shadow,
      isDark: colors.isDark,
      child: Padding(
        padding: padding,
        child: Row(
          spacing: v.gap,
          crossAxisAlignment: multiline
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: [
            if (widget.leading case final leading? when !multiline)
              IconTheme.merge(data: v.iconTheme, child: leading),
            Expanded(
              child: _FieldEditable(
                editableKey: _editableKey,
                controller: _controller,
                focusNode: _focusNode,
                colors: colors,
                visuals: v,
                enabled: widget.enabled,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                minLines: widget.minLines,
                maxLines: widget.maxLines,
                label: widget.label,
                hintText: widget.hintText,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
              ),
            ),
            if (widget.trailing case final trailing? when !multiline)
              IconTheme.merge(data: v.iconTheme, child: trailing),
          ],
        ),
      ),
    );

    if (!widget.enabled) return box;

    // The selection gesture detector requests focus on tap and positions the
    // caret; translucent so taps anywhere in the box reach it. A tap outside
    // releases focus and dismisses the keyboard, as touch users expect.
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

  // Minimum box height for a multiline field: the starting line count times the
  // resolved line height, plus the vertical padding. Defaults to 3 lines when
  // [minLines] is unset, matching the reference textarea's resting size.
  double _multilineMinHeight(FossThemeData theme, _FieldVisuals v) {
    final lines = widget.minLines ?? 3;
    final style = v.textStyle;
    // Scale the line by the ambient text scaler so the resting textarea keeps
    // its [lines]-line height as the user's font size grows.
    final scaler = MediaQuery.textScalerOf(context);
    final lineHeight =
        (style.height ?? 1.5) * scaler.scale(style.fontSize ?? 16);
    return lines * lineHeight + (theme.spacing(1.5) - 1) * 2;
  }
}
