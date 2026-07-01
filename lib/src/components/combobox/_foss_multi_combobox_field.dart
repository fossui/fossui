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
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _anchorKey = GlobalKey();
  final TextEditingController _controller = TextEditingController();

  late FocusNode _focusNode;
  FocusNode? _ownedFocusNode;

  late final AnimationController _animation;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;

  bool _open = false;
  int _highlight = -1;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? (_ownedFocusNode = FocusNode());
    _focusNode.addListener(_onFocusChanged);
    _controller.addListener(_onTextChanged);
    _animation = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _animation, curve: Curves.easeOut);
    _scale = Tween<double>(begin: _openScale, end: 1).animate(_curve);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _ownedFocusNode?.dispose();
    _animation.dispose();
    _curve.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Duration get _duration => context.fossTheme.motion.overlay;

  List<FossComboboxItem<T>> get _filtered {
    final query = _controller.text;
    if (query.isEmpty) return widget.options;
    return [
      for (final o in widget.options)
        if (widget.filter(o.label, query)) o,
    ];
  }

  List<FossComboboxItem<T>> get _chips => [
    for (final o in widget.options)
      if (widget.values.contains(o.value)) o,
  ];

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _openPopup();
    } else {
      _close();
    }
  }

  void _onTextChanged() {
    if (_open) {
      setState(() => _highlight = _filtered.indexWhere((o) => o.enabled));
    }
  }

  void _openPopup() {
    if (!widget.enabled || _open) return;
    setState(() {
      _open = true;
      _highlight = _filtered.indexWhere((o) => o.enabled);
    });
    _portal.show();
    _animation.duration = _reduceMotion ? Duration.zero : _duration;
    unawaited(_animation.forward(from: _reduceMotion ? 1 : 0));
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    if (_reduceMotion) {
      _animation.value = 0;
      _portal.hide();
      return;
    }
    _animation.duration = _duration;
    unawaited(
      _animation.reverse().whenComplete(() {
        if (mounted && _animation.status == AnimationStatus.dismissed) {
          _portal.hide();
        }
      }),
    );
  }

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

  void _moveHighlight(int delta) {
    final options = _filtered;
    final count = options.length;
    if (count == 0) return;
    var next = _highlight;
    for (var step = 0; step < count; step++) {
      next = (next + delta) % count;
      if (next < 0) next += count;
      if (options[next].enabled) {
        setState(() => _highlight = next);
        return;
      }
    }
  }

  void _pickHighlighted() {
    final options = _filtered;
    if (_highlight >= 0 && _highlight < options.length) {
      _toggle(options[_highlight]);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && _open) {
      _close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _open ? _moveHighlight(1) : _openPopup();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      if (_open) _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.backspace && _controller.text.isEmpty) {
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
              ),
            ),
          ),
          SizedBox(height: theme.spacing(2)),
        ],
        OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => _buildOverlay(context, theme, v),
          child: TextFieldTapRegion(
            child: Focus(
              canRequestFocus: false,
              skipTraversal: true,
              onKeyEvent: _onKey,
              child: KeyedSubtree(
                key: _anchorKey,
                child: _shell(theme, v),
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
    final dark = _isDark(colors);
    final hasError = widget.errorText != null;
    final minHeight = switch (widget.size) {
      FossTextFieldSize.sm => 32.0,
      FossTextFieldSize.md => 36.0,
      FossTextFieldSize.lg => 40.0,
    };
    final fill = dark
        ? Color.alphaBlend(
            colors.input.withValues(alpha: colors.input.a * _darkFillOpacity),
            colors.background,
          )
        : colors.background;

    return ListenableBuilder(
      listenable: Listenable.merge([_focusNode, _controller]),
      builder: (context, _) {
        final focused = _focusNode.hasFocus && widget.enabled;
        var borderColor = colors.input;
        Color? ringColor;
        if (hasError) {
          borderColor = colors.destructive.withValues(
            alpha: focused ? _errorBorderFocusedOpacity : _errorBorderOpacity,
          );
          if (focused) {
            ringColor = colors.destructive.withValues(
              alpha: dark ? _errorRingOpacityDark : _errorRingOpacityLight,
            );
          }
        } else if (focused) {
          borderColor = colors.ring;
          ringColor = colors.ring.withValues(alpha: _focusRingOpacity);
        }

        Widget content = Padding(
          padding: EdgeInsets.all(theme.spacing(1) - 1),
          child: _wrap(theme, v),
        );

        content = ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: fill,
              shape: RoundedSuperellipseBorder(
                side: BorderSide(color: borderColor),
                borderRadius: BorderRadius.circular(v.borderRadius),
              ),
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

        if (!widget.enabled) {
          content = Opacity(opacity: _disabledOpacity, child: content);
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _focusNode.requestFocus : null,
          child: content,
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
            theme: theme,
            enabled: widget.enabled,
            onRemove: () => _toggle(item),
          ),
        SizedBox(
          width: 140,
          child: Stack(
            children: [
              if (showPlaceholder)
                IgnorePointer(
                  child: Text(
                    widget.hintText ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                onSubmitted: (_) => _pickHighlighted(),
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

  Widget _buildOverlay(
    BuildContext context,
    FossThemeData theme,
    _ComboboxVisuals v,
  ) {
    final anchor = _anchorRect(context);
    if (anchor == null) return const SizedBox.shrink();
    return TextFieldTapRegion(
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomSingleChildLayout(
              delegate: _PopupLayout(anchor: anchor),
              child: FadeTransition(
                opacity: _curve,
                child: ScaleTransition(
                  scale: _scale,
                  alignment: Alignment.topCenter,
                  child: _popup(theme, v, anchor.width),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popup(FossThemeData theme, _ComboboxVisuals v, double anchorWidth) {
    final options = _filtered;
    final Widget body;
    if (options.isEmpty) {
      body = Padding(
        padding: EdgeInsets.all(theme.spacing(2)),
        child: Text(
          'No items found.',
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
              onEnter: () {
                if (_highlight != i) setState(() => _highlight = i);
              },
              onTap: () => _toggle(options[i]),
            ),
        ],
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: anchorWidth),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: v.popupColor,
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: v.popupBorderColor),
            borderRadius: BorderRadius.circular(v.borderRadius),
          ),
          shadows: v.popupShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(v.borderRadius),
          child: body,
        ),
      ),
    );
  }

  Rect? _anchorRect(BuildContext overlayContext) {
    final anchor = _anchorKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(overlayContext).context.findRenderObject();
    if (anchor is! RenderBox || overlay is! RenderBox || !anchor.attached) {
      return null;
    }
    return anchor.localToGlobal(Offset.zero, ancestor: overlay) & anchor.size;
  }
}

/// A removable chip in the chips field: a label plus a trailing remove button.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.theme,
    required this.enabled,
    required this.onRemove,
  });

  final String label;
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
              label: 'Remove',
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
                    child: CustomPaint(
                      size: const Size.square(14),
                      painter: _CrossPainter(
                        color: colors.accentForeground.withValues(
                          alpha: colors.accentForeground.a * _affixOpacity,
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

/// Paints the chips-field focus ring: a superellipse outset past the edge,
/// matching the corner shape.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas.drawPath(
      RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius + _ringWidth / 2),
      ).getOuterPath(box.inflate(_ringWidth / 2)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _ringWidth,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color || old.radius != radius;
}
