part of 'foss_tabs.dart';

// Fixed tab geometry, the mobile base values, not the desktop step. Vertical
// padding plus the label line height sums to the 36 tab height, so the tab
// grows with the text under a larger scale instead of clipping.
const double _tabHeight = 36;
const double _tabPadX = 10;
const double _tabPadY = (_tabHeight - 24) / 2;
const double _iconSize = 18;
const double _barThickness = 2;
const double _disabledOpacity = 0.64;

// The inactive label is dimmed to 72% inside the segmented bar, lifting to
// full strength on hover. The underline variant keeps it at full strength.
const double _segmentedInactiveOpacity = 0.72;

/// One interactive tab: its label, optional icon, hover and focus wiring, and
/// the semantics that expose it as a selectable tab. Selection, hover, and
/// keyboard state are owned by [_FossTabsState] and flow in through callbacks;
/// this widget only renders and forwards intent.
class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.selected,
    required this.hovered,
    required this.variant,
    required this.horizontal,
    required this.visuals,
    required this.iconGap,
    required this.focusNode,
    required this.onSelect,
    required this.onEnter,
    required this.onExit,
    required this.onKeyEvent,
  });

  final String label;
  final Widget? icon;
  final bool enabled;
  final bool selected;
  final bool hovered;
  final FossTabsVariant variant;
  final bool horizontal;
  final _TabsVisuals visuals;
  final double iconGap;
  final FocusNode focusNode;
  final VoidCallback onSelect;
  final VoidCallback onEnter;
  final VoidCallback onExit;
  final KeyEventResult Function(KeyEvent event) onKeyEvent;

  @override
  Widget build(BuildContext context) {
    final underline = variant == FossTabsVariant.underline;
    final textColor = switch ((selected, underline)) {
      (true, _) => visuals.activeForeground,
      (false, true) => visuals.inactiveForeground,
      (false, false) => visuals.inactiveForeground.withValues(
        alpha: hovered ? 1 : _segmentedInactiveOpacity,
      ),
    };

    final row = Row(
      mainAxisSize: horizontal ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: horizontal
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      spacing: iconGap,
      children: <Widget>[
        if (icon case final icon?)
          IconTheme.merge(
            data: IconThemeData(size: _iconSize, color: textColor),
            child: ExcludeSemantics(child: icon),
          ),
        Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
          style: visuals.labelStyle.copyWith(color: textColor),
        ),
      ],
    );

    // Underline tabs tint on hover. The segmented active background is the
    // sliding indicator, not the tab.
    Widget interactive = DecoratedBox(
      decoration: ShapeDecoration(
        color: underline && hovered ? visuals.hoverColor : null,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(visuals.tabRadius),
        ),
      ),
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: enabled ? (_) => onEnter() : null,
        onExit: enabled ? (_) => onExit() : null,
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: _tabPadX,
                vertical: _tabPadY,
              ),
              child: row,
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

/// The sliding marker for the active tab: an elevated pill behind it in the
/// segmented look, a thin bar on its trailing edge in the underline look. It
/// animates offset and extent to [rect], the active tab's box in strip space.
class _TabIndicator extends StatelessWidget {
  const _TabIndicator({
    required this.rect,
    required this.variant,
    required this.horizontal,
    required this.ltr,
    required this.visuals,
    required this.duration,
  });

  final Rect rect;
  final FossTabsVariant variant;
  final bool horizontal;
  final bool ltr;
  final _TabsVisuals visuals;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    // The pill fills the active tab; the bar hugs one edge of it.
    final (
      double left,
      double top,
      double width,
      double height,
      Widget child,
    ) = switch (variant) {
      FossTabsVariant.segmented => (
        rect.left,
        rect.top,
        rect.width,
        rect.height,
        DecoratedBox(
          decoration: ShapeDecoration(
            color: visuals.indicatorColor,
            shadows: visuals.indicatorShadow,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(visuals.tabRadius),
            ),
          ),
        ),
      ),
      FossTabsVariant.underline when horizontal => (
        rect.left,
        rect.bottom - _barThickness,
        rect.width,
        _barThickness,
        ColoredBox(color: visuals.indicatorColor),
      ),
      FossTabsVariant.underline => (
        ltr ? rect.left : rect.right - _barThickness,
        rect.top,
        _barThickness,
        rect.height,
        ColoredBox(color: visuals.indicatorColor),
      ),
    };

    return AnimatedPositioned(
      left: left,
      top: top,
      width: width,
      height: height,
      duration: duration,
      curve: Curves.easeInOut,
      child: child,
    );
  }
}
