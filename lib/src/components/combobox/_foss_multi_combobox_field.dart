part of 'foss_combobox.dart';

/// The chips input, anchored popup, filtering, and dismiss handling behind
/// [FossMultiCombobox]. Reuses the single field's popup, rows, and layout; only
/// the anchor differs (a wrapping chips field instead of a `FossTextField`).
class _FossMultiComboboxField<T> extends StatefulWidget {
  const _FossMultiComboboxField({
    required this.options,
    required this.values,
    required this.size,
    required this.enabled,
    required this.emptyText,
    required this.removeLabel,
    required this.filter,
    required this.onChanged,
    this.focusNode,
    this.label,
    this.hintText,
    this.errorText,
    this.startAddon,
    this.style,
    super.key,
  });

  final List<FossComboboxItem<T>> options;
  final Set<T> values;
  final FossTextFieldSize size;
  final bool enabled;
  final String emptyText;
  final String removeLabel;
  final bool Function(String label, String query) filter;
  final ValueChanged<Set<T>> onChanged;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? errorText;
  final Widget? startAddon;
  final FossComboboxStyle? style;

  @override
  State<_FossMultiComboboxField<T>> createState() =>
      _FossMultiComboboxFieldState<T>();
}

class _FossMultiComboboxFieldState<T> extends State<_FossMultiComboboxField<T>>
    with
        SingleTickerProviderStateMixin,
        _ComboboxPopup<T, _FossMultiComboboxField<T>> {
  final TextEditingController _controller = TextEditingController();

  late FocusNode _focusNode;
  FocusNode? _ownedFocusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? (_ownedFocusNode = FocusNode());
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(_FossMultiComboboxField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode == oldWidget.focusNode) return;
    (oldWidget.focusNode ?? _ownedFocusNode)?.removeListener(_onFocusChanged);
    _ownedFocusNode?.dispose();
    final provided = widget.focusNode;
    if (provided != null) {
      _ownedFocusNode = null;
      _focusNode = provided;
    } else {
      _focusNode = _ownedFocusNode = FocusNode();
    }
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  @override
  bool get popupEnabled => widget.enabled;

  @override
  List<FossComboboxItem<T>> get filteredOptions {
    final query = _controller.text;
    if (query.isEmpty) return widget.options;
    return [
      for (final o in widget.options)
        if (widget.filter(o.label, query)) o,
    ];
  }

  @override
  int initialHighlight() => _firstEnabled(filteredOptions);

  @override
  void onActivate(FossComboboxItem<T> item) => _toggle(item);

  List<FossComboboxItem<T>> get _chips => [
    for (final o in widget.options)
      if (widget.values.contains(o.value)) o,
  ];

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _openPopup();
    } else {
      _closePopup();
    }
  }

  void _onTextChanged() => _resetHighlight();

  void _toggle(FossComboboxItem<T> item) {
    if (!item.enabled) return;
    final next = Set<T>.of(widget.values);
    if (!next.remove(item.value)) next.add(item.value);
    _controller.clear();
    widget.onChanged(next);
    _focusNode.requestFocus();
  }

  void _removeLast() {
    final chips = _chips;
    if (chips.isEmpty) return;
    widget.onChanged(Set<T>.of(widget.values)..remove(chips.last.value));
  }

  // The shared popup keys plus Backspace, which removes the last chip when the
  // input is empty.
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final result = _handlePopupKey(event);
    if (result != KeyEventResult.ignored) return result;
    if (event is! KeyUpEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controller.text.isEmpty) {
      _removeLast();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _apply(_resolve(theme, widget.size), widget.style);

    final field = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label case final label?) ...[
          Opacity(
            opacity: widget.enabled ? 1 : _disabledOpacity,
            child: Text(
              label,
              style: theme.typography.base.medium.copyWith(
                color: theme.colors.foreground,
                height: _labelLineHeight,
              ),
            ),
          ),
          SizedBox(height: theme.spacing(2)),
        ],
        OverlayPortal(
          controller: _portal,
          overlayChildBuilder: _buildOverlay,
          child: TextFieldTapRegion(
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onKey,
              child: Semantics(
                expanded: _open,
                child: KeyedSubtree(
                  key: _anchorKey,
                  child: _shell(theme, v),
                ),
              ),
            ),
          ),
        ),
        if (widget.errorText case final error?) ...[
          SizedBox(height: theme.spacing(2)),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: theme.typography.xs.copyWith(
                color: theme.colors.destructiveForeground,
              ),
            ),
          ),
        ],
      ],
    );

    return field;
  }

  Widget _shell(FossThemeData theme, _ComboboxVisuals v) {
    final colors = theme.colors;
    final m = fieldMetrics(theme, widget.size);
    final style = widget.style;
    final hasError = widget.errorText != null;

    return ListenableBuilder(
      listenable: Listenable.merge([_focusNode, _controller]),
      builder: (context, _) {
        final box = FossFieldBox(
          enabled: widget.enabled,
          hasError: hasError,
          focused: _focusNode.hasFocus && widget.enabled,
          background: style?.backgroundColor ?? m.fill,
          borderColor: style?.borderColor ?? colors.input,
          ringColor: colors.ring,
          destructiveColor: colors.destructive,
          borderRadius: style?.borderRadius ?? m.radius,
          minHeight: m.minHeight,
          shadow: style?.shadow ?? theme.shadows.xs,
          isDark: colors.isDark,
          // Fill the available width like the single-line field, whose editable
          // expands. The chips carry their own height, so a small vertical
          // inset keeps them off the border once the field grows past one run.
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: m.padX,
                vertical: theme.spacing(1),
              ),
              child: _wrap(theme, v),
            ),
          ),
        );

        if (!widget.enabled) return box;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focusNode.requestFocus,
          child: box,
        );
      },
    );
  }

  Widget _wrap(FossThemeData theme, _ComboboxVisuals v) {
    final colors = theme.colors;
    final chips = _chips;
    final showPlaceholder =
        chips.isEmpty && _controller.text.isEmpty && widget.hintText != null;

    return Wrap(
      spacing: theme.spacing(1),
      runSpacing: theme.spacing(1),
      crossAxisAlignment: WrapCrossAlignment.center,
      runAlignment: WrapAlignment.center,
      children: [
        if (widget.startAddon case final addon?)
          IconTheme.merge(
            data: IconThemeData(
              size: v.iconSize,
              color: v.foreground.withValues(alpha: v.foreground.a * 0.8),
            ),
            child: addon,
          ),
        for (final item in chips)
          _Chip(
            label: item.label,
            removeLabel: widget.removeLabel,
            theme: theme,
            enabled: widget.enabled,
            onRemove: () => _toggle(item),
          ),
        SizedBox(
          width: 140,
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              if (showPlaceholder)
                IgnorePointer(
                  child: Text(
                    widget.hintText ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textHeightBehavior: const TextHeightBehavior(
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                    style: v.textStyle.copyWith(
                      color: colors.mutedForeground.withValues(
                        alpha: colors.mutedForeground.a * _placeholderOpacity,
                      ),
                    ),
                  ),
                ),
              EditableText(
                controller: _controller,
                focusNode: _focusNode,
                readOnly: !widget.enabled,
                style: v.textStyle.copyWith(color: v.foreground),
                cursorColor: colors.foreground,
                backgroundCursorColor: colors.mutedForeground,
                selectionColor: colors.ring.withValues(
                  alpha: _focusRingOpacity,
                ),
                cursorOpacityAnimates: true,
                onSubmitted: (_) => _activateHighlighted(),
                textHeightBehavior: const TextHeightBehavior(
                  leadingDistribution: TextLeadingDistribution.even,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget buildPopupSurface(BuildContext context) {
    final theme = context.fossTheme;
    final v = _apply(_resolve(theme, widget.size), widget.style);
    final options = filteredOptions;
    final Widget body;
    if (options.isEmpty) {
      body = Padding(
        padding: EdgeInsets.all(theme.spacing(2)),
        child: Text(
          widget.emptyText,
          textAlign: TextAlign.center,
          style: v.textStyle.copyWith(color: v.mutedForeground),
        ),
      );
    } else {
      body = ListView(
        shrinkWrap: true,
        padding: EdgeInsets.all(theme.spacing(1)),
        children: [
          for (var i = 0; i < options.length; i++)
            _ComboRow<T>(
              item: options[i],
              theme: theme,
              visuals: v,
              showIndicator: true,
              selected: widget.values.contains(options[i].value),
              highlighted: i == _highlight,
              onEnter: () => _highlightRow(i),
              onTap: () => _toggle(options[i]),
            ),
        ],
      );
    }

    return _popupChrome(v, body);
  }
}

/// A removable chip in the chips field: a label plus a trailing remove button.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.removeLabel,
    required this.theme,
    required this.enabled,
    required this.onRemove,
  });

  final String label;
  final String removeLabel;
  final FossThemeData theme;
  final bool enabled;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    return Semantics(
      label: label,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: colors.accent,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(theme.radii.md),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(start: theme.spacing(2)),
              child: Text(
                label,
                style: theme.typography.sm.medium.copyWith(
                  color: colors.accentForeground,
                ),
              ),
            ),
            Semantics(
              button: true,
              label: removeLabel,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: enabled ? onRemove : null,
                child: MouseRegion(
                  cursor: enabled
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.basic,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: theme.spacing(1.5),
                      vertical: theme.spacing(1),
                    ),
                    // Compact glyph footprint, hit region grown to the minimum
                    // touch target so the small X is comfortably tappable.
                    child: SizedBox.square(
                      dimension: _removeGlyphSize,
                      child: OverflowBox(
                        maxWidth: _minHitTarget,
                        maxHeight: _minHitTarget,
                        child: Center(
                          child: CustomPaint(
                            size: const Size.square(_removeGlyphSize),
                            painter: CloseGlyph(
                              colors.accentForeground.withValues(
                                alpha:
                                    colors.accentForeground.a * _affixOpacity,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
