part of 'foss_menu.dart';

/// The floating panel of menu rows: the chrome, the rows, the roving highlight,
/// the keyboard model, and the menu semantics container.
///
/// It positions itself against [anchor] with [AnchoredLayout], so an opener
/// hands it a rectangle and nothing more: a trigger's bounds, or a zero-size
/// rectangle at a pointer. Values are physical, so the opener resolves the
/// reading direction before building it.
///
/// It owns row behavior and reports a selection outward through [onSelected],
/// which the opener turns into an action and a dismissal, because the dismissal
/// policy differs per opener. It owns no overlay: the opener supplies the
/// portal, the barrier, and the tap region.
class _FossMenuPanel extends StatefulWidget {
  const _FossMenuPanel({
    required this.items,
    required this.anchor,
    required this.side,
    required this.align,
    required this.animation,
    required this.onSelected,
    required this.onDismiss,
    required this.sideOffset,
    this.style,
  });

  /// The rows, in order.
  final List<FossMenuItem> items;

  /// The rectangle to open against, in the overlay's coordinate space.
  final Rect anchor;

  /// The physical side of [anchor] to open on. Flips on overflow.
  final AnchorSide side;

  /// The physical cross-axis alignment against [anchor].
  final AnchorAlign align;

  /// Drives the open and close transition. The panel fades and scales with it.
  final Animation<double> animation;

  /// Called with the index of a selectable row the user picked.
  final ValueChanged<int> onSelected;

  /// Called when `Escape` closes the panel.
  final VoidCallback onDismiss;

  /// The gap from [anchor] along the main axis, in logical pixels.
  final double sideOffset;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossMenuStyle? style;

  @override
  State<_FossMenuPanel> createState() => _FossMenuPanelState();
}

class _FossMenuPanelState extends State<_FossMenuPanel> {
  final FocusNode _focus = FocusNode(debugLabel: 'FossMenu panel');

  /// The highlighted row, or -1 for none. The panel opens with none, so the
  /// first `ArrowDown` lands on the first row.
  int _highlight = -1;

  @override
  void didUpdateWidget(_FossMenuPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A shorter list can leave the highlight past the end.
    if (_highlight >= widget.items.length) _highlight = -1;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// Whether any row reports the menu-item role, which is what makes the
  /// container role necessary. A disabled row still reports it.
  bool get _hasRows => widget.items.any((item) => item._isRow);

  void _highlightRow(int index) {
    if (_highlight == index) return;
    setState(() => _highlight = index);
  }

  /// Walks the highlight by [delta], skipping rows that cannot take a
  /// selection and wrapping at both ends. Does nothing when no row can.
  void _move(int delta) {
    final count = widget.items.length;
    if (count == 0) return;
    // From nothing highlighted, a step back has to land on the last row, so
    // the walk starts one past the matching end rather than at -1.
    var next = _highlight < 0 ? (delta > 0 ? -1 : 0) : _highlight;
    for (var step = 0; step < count; step++) {
      next = (next + delta) % count;
      if (widget.items[next]._selectable) {
        _highlightRow(next);
        return;
      }
    }
  }

  void _select(int index) {
    if (!widget.items[index]._selectable) return;
    widget.onSelected(index);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.onDismiss();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      if (_highlight >= 0) _select(_highlight);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final visuals = _resolve(theme, widget.style);
    final shape = RoundedSuperellipseBorder(
      side: BorderSide(color: visuals.borderColor),
      borderRadius: BorderRadius.circular(visuals.borderRadius),
    );

    // IntrinsicWidth so the panel hugs its widest row above the minimum: a
    // stretched column would take the incoming maxWidth instead and open
    // full-bleed, which loses the anchoring.
    Widget panel = IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: visuals.minWidth),
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: visuals.backgroundColor,
            shape: shape,
            shadows: visuals.shadows,
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(
              shape: shape,
              textDirection: Directionality.of(context),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: visuals.padding,
                  child: SingleChildScrollView(child: _rows(visuals)),
                ),
                // Decorative and above the rows, so it must not take the taps
                // meant for them.
                Positioned.fill(
                  child: IgnorePointer(
                    child: OverlayInnerRing(colors: theme.colors),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    panel = Focus(
      focusNode: _focus,
      onKeyEvent: _onKey,
      autofocus: true,
      child: panel,
    );

    // The container role goes on only when a row wears the menu-item role,
    // which needs it. Over an empty list, or one of only separators and
    // headings, the role would be a menu with no items, a framework error.
    if (_hasRows) {
      panel = Semantics(
        role: SemanticsRole.menu,
        container: true,
        child: panel,
      );
    }

    return CustomSingleChildLayout(
      delegate: AnchoredLayout(
        anchor: widget.anchor,
        side: widget.side,
        align: widget.align,
        sideOffset: widget.sideOffset,
      ),
      child: FadeTransition(
        opacity: widget.animation,
        child: ScaleTransition(
          scale: widget.animation.drive(_openTween),
          alignment: _growFrom(widget.side, Directionality.of(context)),
          child: panel,
        ),
      ),
    );
  }

  Widget _rows(_MenuVisuals visuals) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < widget.items.length; i++)
        _row(visuals, widget.items[i], i),
    ],
  );

  Widget _row(_MenuVisuals visuals, FossMenuItem item, int index) =>
      switch (item._kind) {
        _MenuItemKind.separator => _MenuSeparator(visuals: visuals),
        _MenuItemKind.label => _MenuLabel(item: item, visuals: visuals),
        _MenuItemKind.item => _MenuRow(
          item: item,
          visuals: visuals,
          highlighted: index == _highlight,
          onEnter: () => _highlightRow(index),
          onTap: () => _select(index),
        ),
      };
}

/// Maps the open transition onto the scale the panel grows through.
final Tween<double> _openTween = Tween<double>(begin: _openScale, end: 1);

/// The corner the panel grows from on open: the edge nearest its anchor, so it
/// appears to come out of the trigger rather than out of the air.
Alignment _growFrom(AnchorSide side, TextDirection direction) {
  final ltr = direction == TextDirection.ltr;
  return switch (side) {
    AnchorSide.bottom => ltr ? Alignment.topLeft : Alignment.topRight,
    AnchorSide.top => ltr ? Alignment.bottomLeft : Alignment.bottomRight,
    AnchorSide.left => Alignment.centerRight,
    AnchorSide.right => Alignment.centerLeft,
  };
}

/// An action row: an optional glyph, the label, and an optional shortcut, over
/// a highlight that follows the pointer and the arrow keys.
class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.visuals,
    required this.highlighted,
    required this.onEnter,
    required this.onTap,
  });

  final FossMenuItem item;
  final _MenuVisuals visuals;
  final bool highlighted;
  final VoidCallback onEnter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = item.enabled;
    final color = visuals.rowColor(
      highlighted: highlighted,
      destructive: item.destructive,
    );

    Widget row = Padding(
      padding: EdgeInsetsDirectional.only(
        start: item.inset ? _insetStart : visuals.rowPadding,
        end: visuals.rowPadding,
        top: visuals.rowPaddingY,
        bottom: visuals.rowPaddingY,
      ),
      child: Row(
        spacing: visuals.gap,
        children: [
          if (item.icon case final icon?)
            IconTheme.merge(
              data: IconThemeData(
                color: color.withValues(alpha: color.a * _iconOpacity),
                size: visuals.iconSize,
              ),
              child: icon,
            ),
          // The label takes the slack, which pushes a shortcut to the row end
          // and ellipsizes a long label once the panel hits the viewport.
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: visuals.textStyle.copyWith(color: color),
            ),
          ),
          if (item.shortcut case final shortcut?)
            Text(shortcut, style: visuals.shortcutStyle),
        ],
      ),
    );

    row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _rowMinHeight),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: highlighted ? visuals.highlightColor : null,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(visuals.rowRadius),
          ),
        ),
        child: Align(heightFactor: 1, child: row),
      ),
    );

    if (!enabled) row = Opacity(opacity: _disabledOpacity, child: row);

    // One merged node per row, so the label and its shortcut are announced
    // together rather than as two nodes.
    return MergeSemantics(
      child: Semantics(
        role: SemanticsRole.menuItem,
        button: true,
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

/// The divider between two groups of rows.
class _MenuSeparator extends StatelessWidget {
  const _MenuSeparator({required this.visuals});

  final _MenuVisuals visuals;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: visuals.rowPadding,
        vertical: visuals.rowPaddingY,
      ),
      child: SizedBox(
        height: _separatorThickness,
        child: ColoredBox(color: visuals.separatorColor),
      ),
    ),
  );
}

/// The heading above a group of rows. Announced with the menu, but not a row:
/// it takes no input and the keyboard walk skips it.
class _MenuLabel extends StatelessWidget {
  const _MenuLabel({required this.item, required this.visuals});

  final FossMenuItem item;
  final _MenuVisuals visuals;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: item.inset ? _labelInsetStart : visuals.rowPadding,
      end: visuals.rowPadding,
      top: visuals.labelPaddingY,
      bottom: visuals.labelPaddingY,
    ),
    child: Text(item.label, style: visuals.labelStyle),
  );
}
