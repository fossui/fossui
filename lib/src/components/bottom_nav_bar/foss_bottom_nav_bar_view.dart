part of 'foss_bottom_nav_bar.dart';

// Fixed cell geometry. The glyph is a touch dimension rather than type, so it
// does not grow with the text scaler; the label absorbs the scale and the cell
// grows past the floor with it.
const double _minCellHeight = 56;
const double _disabledOpacity = 0.64;

/// One destination cell: the glyph over its label, the badge pinned to the
/// glyph, hover cursor and focus wiring, and the semantics that expose it as a
/// selectable tab. Selection and keyboard state are owned by
/// [_FossBottomNavBarState] and flow in through callbacks; this widget only
/// renders and forwards intent.
class _NavCell extends StatelessWidget {
  const _NavCell({
    required this.label,
    required this.icon,
    required this.badge,
    required this.enabled,
    required this.selected,
    required this.visuals,
    required this.gap,
    required this.padY,
    required this.badgeOffset,
    required this.focusNode,
    required this.onSelect,
    required this.onKeyEvent,
  });

  final String label;
  final Widget? icon;
  final Widget? badge;
  final bool enabled;
  final bool selected;
  final _NavVisuals visuals;
  final double gap;
  final double padY;
  final double badgeOffset;
  final FocusNode focusNode;
  final VoidCallback onSelect;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final color = selected ? visuals.selectedColor : visuals.unselectedColor;

    final column = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: gap,
      children: <Widget>[
        if (icon case final icon?)
          Stack(
            // The badge overhangs the glyph box; the default clip would eat it.
            clipBehavior: Clip.none,
            children: <Widget>[
              IconTheme.merge(
                data: IconThemeData(size: visuals.iconSize, color: color),
                child: ExcludeSemantics(child: icon),
              ),
              if (badge case final badge?)
                // Anchored just inside the glyph's end edge and grown outward,
                // so a badge wider than the gap overhangs the cell rather than
                // covering the glyph it belongs to.
                PositionedDirectional(
                  top: -badgeOffset,
                  start: visuals.iconSize - badgeOffset,
                  child: ExcludeSemantics(child: badge),
                ),
            ],
          ),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: visuals.labelStyle.copyWith(color: color),
        ),
      ],
    );

    // The floor sits on the cell rather than the bar, so the target is the full
    // bar height without an intrinsic-height pass over the row.
    Widget interactive = ConstrainedBox(
      constraints: BoxConstraints(minHeight: visuals.minHeight),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: enabled
              ? () {
                  focusNode.requestFocus();
                  onSelect();
                }
              : null,
          child: Focus(
            focusNode: focusNode,
            canRequestFocus: enabled,
            skipTraversal: !enabled,
            onKeyEvent: (_, event) => onKeyEvent(event),
            // No Center here: the floor already tightens the cell's minimum
            // height and the column centres inside it. A Center would expand
            // to whatever maximum height the parent offers, stretching the bar
            // in any bounded-height slot.
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: padY),
              child: column,
            ),
          ),
        ),
      ),
    );

    if (!enabled) {
      interactive = Opacity(
        opacity: _disabledOpacity,
        child: IgnorePointer(child: interactive),
      );
    }

    return Semantics(
      role: SemanticsRole.tab,
      container: true,
      selected: selected,
      enabled: enabled,
      button: true,
      label: label,
      onTap: enabled ? onSelect : null,
      child: ExcludeSemantics(child: interactive),
    );
  }
}
