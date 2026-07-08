part of 'foss_text_field.dart';

// The text selection highlight is the ring color at a low alpha.
const double _focusRingOpacity = 0.24;

/// The editable core: the [EditableText], the placeholder shown while it is
/// empty, and the field semantics. Selection, cursor, and hint colors resolve
/// from [colors] and [visuals]; the owning state passes its [controller],
/// [focusNode], and [editableKey] in so the gesture detector keeps driving it.
class _FieldEditable extends StatelessWidget {
  const _FieldEditable({
    required this.editableKey,
    required this.controller,
    required this.focusNode,
    required this.colors,
    required this.visuals,
    required this.enabled,
    required this.obscureText,
    required this.keyboardType,
    required this.textInputAction,
    required this.minLines,
    required this.maxLines,
    required this.label,
    required this.hintText,
    required this.onChanged,
    required this.onSubmitted,
  });

  final GlobalKey<EditableTextState> editableKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final FossColors colors;
  final _FieldVisuals visuals;
  final bool enabled;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? minLines;
  final int? maxLines;
  final String? label;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final multiline = maxLines != 1;
    final editable = EditableText(
      key: editableKey,
      controller: controller,
      focusNode: focusNode,
      readOnly: !enabled,
      rendererIgnoresPointer: true,
      style: visuals.textStyle.copyWith(color: visuals.textColor),
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
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      // An obscured field must not feed the keyboard's autocorrect or
      // suggestion engines with password characters.
      autocorrect: !obscureText,
      enableSuggestions: !obscureText,
      keyboardAppearance: colors.isDark ? Brightness.dark : Brightness.light,
      minLines: minLines,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      enableInteractiveSelection: enabled,
    );

    final hint = hintText;
    return MergeSemantics(
      // The hint is exposed through [Semantics.hint], not as a child, so an
      // empty labelled field does not announce label and placeholder as one.
      child: Semantics(
        label: label,
        hint: hint,
        textField: true,
        multiline: multiline,
        enabled: enabled,
        child: Stack(
          children: [
            if (hint != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? IgnorePointer(
                        child: ExcludeSemantics(
                          child: Text(
                            hint,
                            maxLines: maxLines,
                            overflow: multiline
                                ? TextOverflow.clip
                                : TextOverflow.ellipsis,
                            // Match the editable's even leading so the hint and
                            // the typed value share a baseline, with no jump on
                            // the first keystroke.
                            textHeightBehavior: const TextHeightBehavior(
                              leadingDistribution: TextLeadingDistribution.even,
                            ),
                            style: visuals.textStyle.copyWith(
                              color: visuals.hintColor,
                            ),
                          ),
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
}
