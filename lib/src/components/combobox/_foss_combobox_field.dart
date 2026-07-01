part of 'foss_combobox.dart';

/// The shared input, anchored popup, filtering, roving highlight, and dismiss
/// handling behind [FossAutocomplete] and [FossCombobox]. The two faces differ
/// only in the config they pass: whether rows carry a check indicator, the
/// selection predicate, and what a pick reports.
class _FossComboboxField<T> extends StatefulWidget {
  const _FossComboboxField({
    required this.options,
    required this.size,
    required this.enabled,
    required this.showIndicator,
    required this.showTrigger,
    required this.showClear,
    required this.filter,
    required this.isSelected,
    required this.onPick,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.errorText,
    this.startAddon,
    this.initialText,
    this.onTextChanged,
    this.onClear,
    this.style,
    super.key,
  });

  final List<FossComboboxItem<T>> options;
  final FossTextFieldSize size;
  final bool enabled;
  final bool showIndicator;
  final bool showTrigger;
  final bool showClear;
  final bool Function(String label, String query) filter;
  final bool Function(T value) isSelected;
  final void Function(FossComboboxItem<T> item) onPick;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? errorText;
  final Widget? startAddon;
  final String? initialText;
  final ValueChanged<String>? onTextChanged;
  final VoidCallback? onClear;
  final FossComboboxStyle? style;

  @override
  State<_FossComboboxField<T>> createState() => _FossComboboxFieldState<T>();
}

class _FossComboboxFieldState<T> extends State<_FossComboboxField<T>>
    with SingleTickerProviderStateMixin {
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _anchorKey = GlobalKey();

  late TextEditingController _controller;
  late FocusNode _focusNode;
  TextEditingController? _ownedController;
  FocusNode? _ownedFocusNode;

  late final AnimationController _animation;
  late final CurvedAnimation _curve;
  late final Animation<double> _scale;

  bool _open = false;
  int _highlight = -1;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        (_ownedController = TextEditingController(text: widget.initialText));
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
    _controller.removeListener(_onTextChanged);
    _ownedController?.dispose();
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

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _openPopup();
    } else {
      _close();
    }
  }

  void _onTextChanged() {
    widget.onTextChanged?.call(_controller.text);
    if (_open) {
      setState(() => _highlight = _firstEnabled(_filtered));
    }
  }

  void _openPopup() {
    if (!widget.enabled || _open) return;
    setState(() {
      _open = true;
      _highlight = _initialHighlight();
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

  int _initialHighlight() {
    final options = _filtered;
    final selected = options.indexWhere(
      (o) => o.enabled && widget.isSelected(o.value),
    );
    if (selected != -1) return selected;
    return _firstEnabled(options);
  }

  int _firstEnabled(List<FossComboboxItem<T>> options) =>
      options.indexWhere((o) => o.enabled);

  void _pick(FossComboboxItem<T> item) {
    if (!item.enabled) return;
    _controller
      ..removeListener(_onTextChanged)
      ..text = item.label
      ..selection = TextSelection.collapsed(offset: item.label.length)
      ..addListener(_onTextChanged);
    widget.onPick(item);
    _close();
  }

  void _clear() {
    _controller.clear();
    widget.onClear?.call();
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
      _pick(options[_highlight]);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      if (!_open) return KeyEventResult.ignored;
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
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _apply(_resolve(theme, widget.size), widget.style);

    final field = TextFieldTapRegion(
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: KeyedSubtree(
          key: _anchorKey,
          child: FossTextField(
            controller: _controller,
            focusNode: _focusNode,
            size: widget.size,
            label: widget.label,
            hintText: widget.hintText,
            errorText: widget.errorText,
            enabled: widget.enabled,
            leading: widget.startAddon,
            trailing: _trailing(v),
            onSubmitted: (_) => _pickHighlighted(),
          ),
        ),
      ),
    );

    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) => _buildOverlay(context, theme, v),
      child: field,
    );
  }

  Widget? _trailing(_ComboboxVisuals v) {
    final color = v.foreground.withValues(
      alpha: v.foreground.a * _affixOpacity,
    );
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final showClear =
            widget.showClear && _controller.text.isNotEmpty && widget.enabled;
        final children = <Widget>[
          if (showClear)
            _IconButton(
              size: v.iconSize,
              onTap: _clear,
              painter: _CrossPainter(color: color),
            ),
          if (widget.showTrigger && !showClear)
            _IconButton(
              size: v.iconSize,
              onTap: widget.enabled ? _toggle : null,
              painter: _ChevronPainter(color: color),
            ),
        ];
        if (children.isEmpty) return const SizedBox.shrink();
        return Row(mainAxisSize: MainAxisSize.min, children: children);
      },
    );
  }

  void _toggle() {
    if (_open) {
      _close();
    } else {
      _focusNode.requestFocus();
      _openPopup();
    }
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
              showIndicator: widget.showIndicator,
              selected: widget.isSelected(options[i].value),
              highlighted: i == _highlight,
              onEnter: () {
                if (_highlight != i) setState(() => _highlight = i);
              },
              onTap: () => _pick(options[i]),
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

/// A single popup row: an optional check indicator, an optional icon, and the
/// label. Autocomplete rows omit the indicator column.
class _ComboRow<T> extends StatelessWidget {
  const _ComboRow({
    required this.item,
    required this.theme,
    required this.visuals,
    required this.showIndicator,
    required this.selected,
    required this.highlighted,
    required this.onEnter,
    required this.onTap,
  });

  final FossComboboxItem<T> item;
  final FossThemeData theme;
  final _ComboboxVisuals visuals;
  final bool showIndicator;
  final bool selected;
  final bool highlighted;
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
      // Combobox rows carry a wider end inset (coss `pe-4`) to balance the
      // indicator column; the flat autocomplete row is symmetric (`px-2`).
      padding: EdgeInsetsDirectional.only(
        start: theme.spacing(2),
        end: showIndicator ? theme.spacing(4) : theme.spacing(2),
        top: theme.spacing(1),
        bottom: theme.spacing(1),
      ),
      child: Row(
        children: [
          if (showIndicator) ...[
            SizedBox(
              width: _indicatorColumn,
              height: _indicatorColumn,
              child: selected
                  ? CustomPaint(painter: _CheckPainter(color: textColor))
                  : null,
            ),
            SizedBox(width: theme.spacing(2)),
          ],
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

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
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
}

/// A small square icon button for the trailing trigger and clear affordances.
class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.size,
    required this.painter,
    required this.onTap,
  });

  final double size;
  final CustomPainter painter;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: CustomPaint(size: Size.square(size), painter: painter),
      ),
    );
  }
}

/// Positions the popup below the anchor, flipping above when there is no room,
/// and clamping its height to the viewport and the popup maximum.
class _PopupLayout extends SingleChildLayoutDelegate {
  const _PopupLayout({required this.anchor});

  final Rect anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final below = constraints.maxHeight - anchor.bottom - _popupOffset;
    final above = anchor.top - _popupOffset;
    final room = (math.max(below, above) - _popupMargin).clamp(
      0.0,
      constraints.maxHeight,
    );
    return BoxConstraints(
      minWidth: anchor.width,
      maxWidth: constraints.maxWidth,
      maxHeight: math.min(room, _popupMaxHeight),
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

/// A bare check mark, the picked-row indicator.
class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset p(double x, double y) => Offset(x * s, y * s);
    canvas.drawPath(
      Path()
        ..moveTo(p(0.24, 0.52).dx, p(0.24, 0.52).dy)
        ..lineTo(p(0.42, 0.7).dx, p(0.42, 0.7).dy)
        ..lineTo(p(0.76, 0.3).dx, p(0.76, 0.3).dy),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.color != color;
}

/// A stacked up/down chevron, the trigger's open affordance.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    Offset p(double x, double y) => Offset(x * s, y * s);
    canvas
      ..drawPath(
        Path()
          ..moveTo(p(0.3, 0.44).dx, p(0.3, 0.44).dy)
          ..lineTo(p(0.5, 0.3).dx, p(0.5, 0.3).dy)
          ..lineTo(p(0.7, 0.44).dx, p(0.7, 0.44).dy),
        stroke,
      )
      ..drawPath(
        Path()
          ..moveTo(p(0.3, 0.56).dx, p(0.3, 0.56).dy)
          ..lineTo(p(0.5, 0.7).dx, p(0.5, 0.7).dy)
          ..lineTo(p(0.7, 0.56).dx, p(0.7, 0.56).dy),
        stroke,
      );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// An X glyph, the clear affordance.
class _CrossPainter extends CustomPainter {
  const _CrossPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1
      ..strokeCap = StrokeCap.round;
    Offset p(double x, double y) => Offset(x * s, y * s);
    canvas
      ..drawLine(p(0.34, 0.34), p(0.66, 0.66), stroke)
      ..drawLine(p(0.66, 0.34), p(0.34, 0.66), stroke);
  }

  @override
  bool shouldRepaint(_CrossPainter old) => old.color != color;
}
