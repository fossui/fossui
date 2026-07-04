part of 'foss_select.dart';

/// How a row marks selection: a lone check on the picked row (single-select) or
/// a checkbox on every row (multi-select).
enum _SelectIndicator { checkmark, checkbox }

/// The shared trigger, anchored popup, roving highlight, type-ahead, and
/// dismiss handling for both [FossSelect] and [FossMultiSelect]. The two faces
/// differ only in the config they pass: the selection predicate, the pick
/// handler, whether a pick closes the popup, and the row indicator.
class _FossSelectField<T> extends StatefulWidget {
  const _FossSelectField({
    required this.items,
    required this.size,
    required this.enabled,
    required this.triggerLabel,
    required this.indicator,
    required this.isSelected,
    required this.onPick,
    required this.closeOnPick,
    this.style,
    this.label,
    this.placeholder,
    this.errorText,
    super.key,
  });

  final List<FossSelectItem<T>> items;
  final FossSelectSize size;
  final bool enabled;
  final String? triggerLabel;
  final _SelectIndicator indicator;
  final bool Function(T value) isSelected;
  final void Function(T value) onPick;
  final bool closeOnPick;
  final FossSelectStyle? style;
  final String? label;
  final String? placeholder;
  final String? errorText;

  @override
  State<_FossSelectField<T>> createState() => _FossSelectFieldState<T>();
}

class _FossSelectFieldState<T> extends State<_FossSelectField<T>>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final WidgetStatesController _states = WidgetStatesController();
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _anchorKey = GlobalKey();
  final FocusNode _triggerFocus = FocusNode(debugLabel: 'FossSelect trigger');
  final FocusNode _popupFocus = FocusNode(debugLabel: 'FossSelect popup');

  late final AnimationController _animation;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;

  bool _open = false;
  int _highlight = -1;
  String _typed = '';
  DateTime _lastKeystroke = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animation = AnimationController(vsync: this);
    _curve = CurvedAnimation(parent: _animation, curve: Curves.easeOut);
    _scale = Tween<double>(begin: _openScale, end: 1).animate(_curve);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animation.dispose();
    _curve.dispose();
    _states.dispose();
    _triggerFocus.dispose();
    _popupFocus.dispose();
    super.dispose();
  }

  // The Android system back closes the popup rather than popping the route.
  @override
  Future<bool> didPopRoute() async {
    if (!_open) return false;
    _close();
    return true;
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  Duration get _duration => context.fossTheme.motion.overlay;

  void _toggle() => _open ? _close() : _openPopup();

  void _openPopup() {
    if (!widget.enabled || _open) return;
    setState(() {
      _open = true;
      _highlight = _initialHighlight();
      _typed = '';
    });
    _portal.show();
    _popupFocus.requestFocus();
    _animation.duration = _reduceMotion ? Duration.zero : _duration;
    unawaited(_animation.forward(from: _reduceMotion ? 1 : 0));
  }

  void _close() {
    if (!_open) return;
    setState(() => _open = false);
    _triggerFocus.requestFocus();
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

  int _initialHighlight() {
    final selected = widget.items.indexWhere(
      (i) => i.enabled && widget.isSelected(i.value),
    );
    if (selected != -1) return selected;
    return widget.items.indexWhere((i) => i.enabled);
  }

  void _pick(FossSelectItem<T> item) {
    if (!item.enabled) return;
    widget.onPick(item.value);
    if (widget.closeOnPick) {
      _close();
    } else {
      setState(() => _highlight = widget.items.indexOf(item));
    }
  }

  void _moveHighlight(int delta) {
    final count = widget.items.length;
    if (count == 0) return;
    var next = _highlight;
    for (var step = 0; step < count; step++) {
      next = (next + delta) % count;
      if (next < 0) next += count;
      if (widget.items[next].enabled) {
        setState(() => _highlight = next);
        return;
      }
    }
  }

  void _typeahead(String char) {
    final now = DateTime.now();
    _typed = now.difference(_lastKeystroke).inMilliseconds > 700
        ? char
        : _typed + char;
    _lastKeystroke = now;
    final query = _typed.toLowerCase();
    final match = widget.items.indexWhere(
      (i) => i.enabled && i.label.toLowerCase().startsWith(query),
    );
    if (match != -1) setState(() => _highlight = match);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_highlight >= 0 && _highlight < widget.items.length) {
        _pick(widget.items[_highlight]);
      }
      return KeyEventResult.handled;
    }
    final char = event.character;
    if (char != null && char.trim().isNotEmpty && char.length == 1) {
      _typeahead(char);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _apply(_resolve(theme, widget.size), widget.style);
    final hasError = widget.errorText != null;

    final trigger = _trigger(theme, v, hasError: hasError);

    final field = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label case final label?) ...[
          Text(
            label,
            style: theme.typography.base.medium.copyWith(
              color: theme.colors.foreground,
            ),
          ),
          SizedBox(height: theme.spacing(2)),
        ],
        OverlayPortal(
          controller: _portal,
          overlayChildBuilder: (context) => _buildOverlay(context, theme, v),
          child: trigger,
        ),
      ],
    );

    return field;
  }

  Widget _trigger(
    FossThemeData theme,
    _SelectVisuals v, {
    required bool hasError,
  }) {
    final label = widget.triggerLabel;
    final text = label ?? widget.placeholder ?? '';
    final textColor = label != null ? v.foreground : v.placeholderColor;

    Widget box = ListenableBuilder(
      listenable: _states,
      builder: (_, _) => _triggerBox(
        theme,
        v,
        text: text,
        textColor: textColor,
        hasError: hasError,
      ),
    );

    box = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: _minTapTarget,
        minWidth: _minWidth,
      ),
      child: Align(heightFactor: 1, child: box),
    );

    if (!widget.enabled) {
      box = Opacity(opacity: _disabledOpacity, child: box);
    }

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      value: label ?? widget.placeholder,
      hint: widget.errorText,
      expanded: _open,
      child: FocusableActionDetector(
        focusNode: _triggerFocus,
        enabled: widget.enabled,
        mouseCursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) =>
            _states.update(WidgetState.focused, value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _openPopup();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? _toggle : null,
          child: KeyedSubtree(key: _anchorKey, child: box),
        ),
      ),
    );
  }

  Widget _triggerBox(
    FossThemeData theme,
    _SelectVisuals v, {
    required String text,
    required Color textColor,
    required bool hasError,
  }) {
    final colors = theme.colors;
    final dark = colors.isDark;
    final focused = _states.value.contains(WidgetState.focused);
    final atRest = !focused && !_open && !hasError;

    var borderColor = v.borderColor;
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
      padding: v.padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: v.textStyle.copyWith(color: textColor),
            ),
          ),
          SizedBox(width: v.gap),
          FossGlyphIcon(
            ChevronUpDownGlyph(
              v.foreground.withValues(alpha: v.foreground.a * 0.8),
            ),
            size: v.iconSize,
          ),
        ],
      ),
    );

    content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: v.minHeight),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: v.background,
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: borderColor),
            borderRadius: BorderRadius.circular(v.borderRadius),
          ),
          shadows: atRest ? v.shadow : const [],
        ),
        child: content,
      ),
    );

    if (atRest) {
      content = CustomPaint(
        foregroundPainter: _RimPainter(
          color: dark ? _rimDark : _rimLight,
          radius: v.borderRadius,
          topLit: dark,
        ),
        child: content,
      );
    }

    if (ringColor != null) {
      content = CustomPaint(
        foregroundPainter: _RectRingPainter(
          color: ringColor,
          offsetColor: colors.background,
          radius: v.borderRadius,
        ),
        child: content,
      );
    }

    return content;
  }

  Widget _buildOverlay(
    BuildContext context,
    FossThemeData theme,
    _SelectVisuals v,
  ) {
    final anchor = _anchorRect(context);
    if (anchor == null) return const SizedBox.shrink();
    // Android back is handled in didPopRoute, so no Router is required here.
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
          ),
        ),
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
    );
  }

  Widget _popup(FossThemeData theme, _SelectVisuals v, double anchorWidth) {
    final list = ListView(
      shrinkWrap: true,
      padding: EdgeInsets.all(theme.spacing(1)),
      children: [
        for (var i = 0; i < widget.items.length; i++)
          _SelectRow<T>(
            item: widget.items[i],
            theme: theme,
            visuals: v,
            selected: widget.isSelected(widget.items[i].value),
            highlighted: i == _highlight,
            indicator: widget.indicator,
            onEnter: () {
              if (_highlight != i) setState(() => _highlight = i);
            },
            onTap: () => _pick(widget.items[i]),
          ),
      ],
    );

    final dark = theme.colors.isDark;
    final surface = DecoratedBox(
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
        child: list,
      ),
    );

    return Semantics(
      role: SemanticsRole.menu,
      container: true,
      child: Focus(
        focusNode: _popupFocus,
        onKeyEvent: _onKey,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: anchorWidth),
          child: CustomPaint(
            foregroundPainter: _RimPainter(
              color: dark ? _rimDark : _rimLight,
              radius: v.borderRadius,
              topLit: dark,
            ),
            child: surface,
          ),
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

/// A single popup row: an indicator column, an optional icon, and the label.
class _SelectRow<T> extends StatelessWidget {
  const _SelectRow({
    required this.item,
    required this.theme,
    required this.visuals,
    required this.selected,
    required this.highlighted,
    required this.indicator,
    required this.onEnter,
    required this.onTap,
  });

  final FossSelectItem<T> item;
  final FossThemeData theme;
  final _SelectVisuals visuals;
  final bool selected;
  final bool highlighted;
  final _SelectIndicator indicator;
  final VoidCallback onEnter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled;
    final fill = highlighted ? visuals.highlightColor : null;
    final textColor = highlighted
        ? visuals.highlightForeground
        : visuals.foreground;

    Widget row = Padding(
      // Asymmetric like the row spec: a wider end inset past the label, a
      // tighter start inset against the indicator column.
      padding: EdgeInsetsDirectional.only(
        start: theme.spacing(2),
        end: theme.spacing(4),
        top: theme.spacing(1),
        bottom: theme.spacing(1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: _indicatorColumn,
            height: _indicatorColumn,
            child: _indicatorWidget(textColor),
          ),
          SizedBox(width: theme.spacing(2)),
          if (item.icon case final icon?) ...[
            IconTheme.merge(
              data: IconThemeData(color: textColor, size: visuals.iconSize),
              child: icon,
            ),
            SizedBox(width: theme.spacing(2)),
          ],
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: visuals.textStyle.copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );

    row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _rowMinHeight),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: fill,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(visuals.rowRadius),
          ),
        ),
        child: Align(heightFactor: 1, child: row),
      ),
    );

    if (!enabled) row = Opacity(opacity: _disabledOpacity, child: row);

    // One merged node per row, so assistive tech announces the option once with
    // its selected state, not the label and control as separate nodes.
    final isCheckbox = indicator == _SelectIndicator.checkbox;
    return MergeSemantics(
      child: Semantics(
        role: isCheckbox
            ? SemanticsRole.menuItemCheckbox
            : SemanticsRole.menuItem,
        button: true,
        // A menu-item-checkbox must be checkable (report checked state); a
        // plain menu item reports selection instead.
        checked: isCheckbox ? selected : null,
        selected: isCheckbox ? null : selected,
        enabled: enabled,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: enabled ? (_) => onEnter() : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onTap : null,
            child: row,
          ),
        ),
      ),
    );
  }

  Widget _indicatorWidget(Color color) {
    switch (indicator) {
      case _SelectIndicator.checkmark:
        if (!selected) return const SizedBox.shrink();
        return FossGlyphIcon(CheckGlyph(color));
      case _SelectIndicator.checkbox:
        final colors = theme.colors;
        return DecoratedBox(
          decoration: ShapeDecoration(
            color: selected ? colors.primary : null,
            shape: RoundedSuperellipseBorder(
              side: selected
                  ? BorderSide.none
                  : BorderSide(color: colors.input),
              borderRadius: BorderRadius.circular(theme.radii.sm),
            ),
          ),
          child: selected
              ? Padding(
                  padding: const EdgeInsets.all(2),
                  child: FossGlyphIcon(CheckGlyph(colors.primaryForeground)),
                )
              : null,
        );
    }
  }
}

/// Positions the popup below the anchor, flipping above when there is no room,
/// and clamping its height to the viewport.
class _PopupLayout extends SingleChildLayoutDelegate {
  const _PopupLayout({required this.anchor});

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final below = constraints.maxHeight - anchor.bottom - _popupOffset;
    final above = anchor.top - _popupOffset;
    final maxHeight = (math.max(below, above) - _popupMargin).clamp(
      0.0,
      constraints.maxHeight,
    );
    return BoxConstraints(
      minWidth: anchor.width,
      maxWidth: constraints.maxWidth,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final below = size.height - anchor.bottom - _popupOffset;
    final placeBelow = childSize.height <= below;
    final dy = placeBelow
        ? anchor.bottom + _popupOffset
        : anchor.top - _popupOffset - childSize.height;
    final dx = anchor.left
        .clamp(
          _popupMargin,
          math.max(_popupMargin, size.width - _popupMargin - childSize.width),
        )
        .toDouble();
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_PopupLayout oldDelegate) => oldDelegate.anchor != anchor;
}

/// Paints a 1px rim inside the trigger, top-lit in dark mode, fading to nothing
/// by the center.
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
    final shader = LinearGradient(
      begin: topLit ? Alignment.topCenter : Alignment.bottomCenter,
      end: Alignment.center,
      colors: [color, color.withValues(alpha: 0)],
    ).createShader(rect);
    final paint = Paint()
      ..shader = shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(
      RoundedSuperellipseBorder(
        borderRadius: BorderRadius.circular(radius),
      ).getOuterPath(rect),
      paint,
    );
  }

  @override
  bool shouldRepaint(_RimPainter old) =>
      old.color != color || old.topLit != topLit || old.radius != radius;
}

/// Paints the focus ring: a rounded rect outset just past the trigger edge with
/// a 1px gap filled by the surface, so the ring reads as detached.
class _RectRingPainter extends CustomPainter {
  const _RectRingPainter({
    required this.color,
    required this.offsetColor,
    required this.radius,
  });

  final Color color;
  final Color offsetColor;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    canvas
      ..drawPath(
        RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(radius + _ringOffset / 2),
        ).getOuterPath(box.inflate(_ringOffset / 2)),
        Paint()
          ..color = offsetColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringOffset,
      )
      ..drawPath(
        RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(
            radius + _ringOffset + _ringWidth / 2,
          ),
        ).getOuterPath(box.inflate(_ringOffset + _ringWidth / 2)),
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = _ringWidth,
      );
  }

  @override
  bool shouldRepaint(_RectRingPainter old) =>
      old.color != color ||
      old.offsetColor != offsetColor ||
      old.radius != radius;
}
