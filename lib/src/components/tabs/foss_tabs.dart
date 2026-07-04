import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_tabs_style.dart';

// Fixed tab geometry, the mobile base values, not the desktop step. Vertical
// padding plus the label line height sums to the 36 tab height, so the tab
// grows with the text under a larger scale instead of clipping.
const double _tabHeight = 36;
const double _tabPadX = 9;
const double _tabPadY = (_tabHeight - 24) / 2;
const double _iconSize = 18;
const double _barThickness = 2;
const double _ringWidth = 2;
const double _disabledOpacity = 0.64;

// The inactive label is dimmed to 72% inside the segmented bar, lifting to
// full strength on hover. The underline variant keeps it at full strength.
const double _segmentedInactiveOpacity = 0.72;

/// The two tab looks.
enum FossTabsVariant {
  /// A filled bar with an elevated pill sliding behind the active tab.
  segmented,

  /// A bare strip with a colored bar sliding along the active tab's edge.
  underline,
}

/// The axis the tab strip runs along.
enum FossTabsOrientation {
  /// Tabs in a row, the panel below.
  horizontal,

  /// Tabs in a column, the panel beside.
  vertical,
}

/// One tab: its [value], [label], optional leading [icon] and [content] panel,
/// and whether it is [enabled].
///
/// This is data passed to [FossTabs.tabs], not a widget. The [content] is
/// optional, so a strip can drive a panel laid out elsewhere.
///
/// ```dart
/// const FossTab(value: 'home', label: 'Home', content: HomeBody());
/// ```
@immutable
class FossTab<T> {
  /// Creates a tab carrying [value] and [label].
  const FossTab({
    required this.value,
    required this.label,
    this.icon,
    this.content,
    this.enabled = true,
  });

  /// The value this tab selects. Unique within a [FossTabs].
  final T value;

  /// The text shown on the trigger.
  final String label;

  /// Optional leading glyph, sized to 18. Any widget; no icon dependency.
  final Widget? icon;

  /// The panel shown when this tab is active. Null leaves the panel to the
  /// caller.
  final Widget? content;

  /// Whether the tab accepts focus and selection. A disabled tab dims and is
  /// skipped by the keyboard.
  final bool enabled;
}

/// A row or column of tabs that toggle between sibling panels, with an animated
/// indicator marking the active tab.
///
/// [FossTabs] owns the selection. Pass [value] with [onChanged] to control it,
/// or leave [value] null and seed [initialValue] to let the widget hold its own
/// selection. Each [FossTab] in [tabs] carries its label, optional icon and
/// panel, and an enabled flag; only the active tab's panel renders.
///
/// [variant] picks the look and [orientation] the axis. Colors, type, and the
/// indicator slide come from `context.fossTheme`; pass a [FossTabsStyle] to
/// [style] for a one-off.
///
/// ```dart
/// FossTabs<String>(
///   value: selected,
///   onChanged: (v) => setState(() => selected = v),
///   tabs: const [
///     FossTab(value: 'overview', label: 'Overview', content: OverviewBody()),
///     FossTab(value: 'activity', label: 'Activity', content: ActivityBody()),
///   ],
/// );
/// ```
class FossTabs<T> extends StatefulWidget {
  /// Creates a set of tabs over [tabs].
  const FossTabs({
    required this.tabs,
    this.value,
    this.onChanged,
    this.initialValue,
    this.variant = FossTabsVariant.segmented,
    this.orientation = FossTabsOrientation.horizontal,
    this.style,
    super.key,
  });

  /// The ordered tabs.
  final List<FossTab<T>> tabs;

  /// The selected value when controlled. Null hands selection to the widget,
  /// seeded by [initialValue].
  final T? value;

  /// Called with a tab's value when it is selected.
  final ValueChanged<T>? onChanged;

  /// The initial selection when uncontrolled ([value] is null). Falls back to
  /// the first enabled tab.
  final T? initialValue;

  /// The look. Defaults to [FossTabsVariant.segmented].
  final FossTabsVariant variant;

  /// The axis. Defaults to [FossTabsOrientation.horizontal].
  final FossTabsOrientation orientation;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossTabsStyle? style;

  @override
  State<FossTabs<T>> createState() => _FossTabsState<T>();
}

class _FossTabsState<T> extends State<FossTabs<T>> {
  final GlobalKey _flexKey = GlobalKey();
  final Map<T, GlobalKey> _tabKeys = <T, GlobalKey>{};
  final Map<T, FocusNode> _nodes = <T, FocusNode>{};

  Rect? _activeRect;
  T? _internal;
  int? _hovered;
  int? _focused;

  bool get _horizontal => widget.orientation == FossTabsOrientation.horizontal;

  T? get _value => widget.value ?? _internal;

  @override
  void initState() {
    super.initState();
    _internal = widget.initialValue ?? _firstEnabledValue();
  }

  @override
  void didUpdateWidget(FossTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Drop keys and nodes for tabs that no longer exist.
    final values = widget.tabs.map((t) => t.value).toSet();
    _tabKeys.removeWhere((value, _) => !values.contains(value));
    final stale = _nodes.keys.where((v) => !values.contains(v)).toList();
    for (final value in stale) {
      _nodes.remove(value)?.dispose();
    }
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  T? _firstEnabledValue() {
    for (final tab in widget.tabs) {
      if (tab.enabled) return tab.value;
    }
    return null;
  }

  GlobalKey _keyFor(T value) => _tabKeys.putIfAbsent(value, GlobalKey.new);

  FocusNode _nodeFor(T value) => _nodes.putIfAbsent(value, FocusNode.new);

  void _select(T value) {
    widget.onChanged?.call(value);
    if (widget.value == null && value != _internal) {
      setState(() => _internal = value);
    }
  }

  // Reads the active tab's box in the strip's coordinate space after layout, so
  // the indicator can track it. Only commits when it actually moves, which
  // stops the post-frame callback from looping.
  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final value = _value;
      final flex = _flexKey.currentContext?.findRenderObject();
      final tab = value == null
          ? null
          : _tabKeys[value]?.currentContext?.findRenderObject();
      if (flex is! RenderBox ||
          tab is! RenderBox ||
          !flex.hasSize ||
          !tab.hasSize) {
        if (_activeRect != null) setState(() => _activeRect = null);
        return;
      }
      final topLeft = flex.globalToLocal(tab.localToGlobal(Offset.zero));
      final rect = topLeft & tab.size;
      if (rect != _activeRect) setState(() => _activeRect = rect);
    });
  }

  // Walks from [from] by [step], skipping disabled tabs, without wrapping.
  int? _adjacent(int from, int step) {
    for (var i = from + step; i >= 0 && i < widget.tabs.length; i += step) {
      if (widget.tabs[i].enabled) return i;
    }
    return null;
  }

  int? _edge(bool last) {
    final range = last
        ? List<int>.generate(widget.tabs.length, (i) => i).reversed
        : List<int>.generate(widget.tabs.length, (i) => i);
    for (final i in range) {
      if (widget.tabs[i].enabled) return i;
    }
    return null;
  }

  KeyEventResult _onKey(KeyEvent event, int index) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      _select(widget.tabs[index].value);
      return KeyEventResult.handled;
    }

    final ltr = Directionality.of(context) == TextDirection.ltr;
    final target = switch (key) {
      LogicalKeyboardKey.home => _edge(false),
      LogicalKeyboardKey.end => _edge(true),
      LogicalKeyboardKey.arrowRight when _horizontal => _adjacent(
        index,
        ltr ? 1 : -1,
      ),
      LogicalKeyboardKey.arrowLeft when _horizontal => _adjacent(
        index,
        ltr ? -1 : 1,
      ),
      LogicalKeyboardKey.arrowDown when !_horizontal => _adjacent(index, 1),
      LogicalKeyboardKey.arrowUp when !_horizontal => _adjacent(index, -1),
      _ => null,
    };
    if (target == null) return KeyEventResult.ignored;
    _nodeFor(widget.tabs[target].value).requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final dark = theme.colors.isDark;
    final v = _resolve(theme, widget.variant, dark, widget.style);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    FossTab<T>? active;
    for (final tab in widget.tabs) {
      if (tab.value == _value) {
        active = tab;
        break;
      }
    }

    final stripVisual = _buildStrip(theme, v, reduceMotion);
    final strip = Semantics(
      role: SemanticsRole.tabBar,
      container: true,
      // A vertical strip sits in a Row, which hands a non-flex child unbounded
      // width; the strip hugs its widest tab, so cap it to the intrinsic width.
      child: _horizontal ? stripVisual : IntrinsicWidth(child: stripVisual),
    );

    _scheduleMeasure();

    final children = <Widget>[strip];
    if (active?.content case final content?) {
      final panel = Semantics(role: SemanticsRole.tabPanel, child: content);
      children.add(_horizontal ? panel : Expanded(child: panel));
    }

    return _horizontal
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.spacing(2),
            children: children,
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: theme.spacing(2),
            children: children,
          );
  }

  Widget _buildStrip(FossThemeData theme, _TabsVisuals v, bool reduceMotion) {
    final segmented = widget.variant == FossTabsVariant.segmented;

    final tabs = <Widget>[
      for (var i = 0; i < widget.tabs.length; i++) _buildTab(theme, v, i),
    ];

    final flex = _horizontal
        ? Row(
            key: _flexKey,
            mainAxisSize: MainAxisSize.min,
            spacing: theme.spacing(0.5),
            children: tabs,
          )
        : Column(
            key: _flexKey,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: theme.spacing(0.5),
            children: tabs,
          );

    final indicator = _activeRect == null
        ? null
        : _buildIndicator(theme, v, _activeRect!, reduceMotion);

    final stack = Stack(
      children: <Widget>[
        if (segmented && indicator != null) indicator,
        flex,
        if (!segmented && indicator != null) indicator,
      ],
    );

    if (segmented) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          color: v.barColor,
          shape: RoundedSuperellipseBorder(
            borderRadius: BorderRadius.circular(v.barRadius),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(theme.spacing(0.5)),
          child: stack,
        ),
      );
    }
    return Padding(
      padding: _horizontal
          ? EdgeInsets.symmetric(vertical: theme.spacing(1))
          : EdgeInsets.symmetric(horizontal: theme.spacing(1)),
      child: stack,
    );
  }

  Widget _buildIndicator(
    FossThemeData theme,
    _TabsVisuals v,
    Rect rect,
    bool reduceMotion,
  ) {
    final ltr = Directionality.of(context) == TextDirection.ltr;
    final duration = reduceMotion ? Duration.zero : theme.motion.overlay;

    // The pill fills the active tab; the bar hugs one edge of it.
    final (
      double left,
      double top,
      double width,
      double height,
      Widget child,
    ) = switch (widget.variant) {
      FossTabsVariant.segmented => (
        rect.left,
        rect.top,
        rect.width,
        rect.height,
        DecoratedBox(
          decoration: ShapeDecoration(
            color: v.indicatorColor,
            shadows: v.indicatorShadow,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(v.tabRadius),
            ),
          ),
        ),
      ),
      FossTabsVariant.underline when _horizontal => (
        rect.left,
        rect.bottom - _barThickness,
        rect.width,
        _barThickness,
        ColoredBox(color: v.indicatorColor),
      ),
      FossTabsVariant.underline => (
        ltr ? rect.left : rect.right - _barThickness,
        rect.top,
        _barThickness,
        rect.height,
        ColoredBox(color: v.indicatorColor),
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

  Widget _buildTab(FossThemeData theme, _TabsVisuals v, int index) {
    final tab = widget.tabs[index];
    final selected = tab.value == _value;
    final hovered = _hovered == index;
    final underline = widget.variant == FossTabsVariant.underline;

    final Color textColor;
    if (selected) {
      textColor = v.activeForeground;
    } else if (underline) {
      textColor = v.inactiveForeground;
    } else {
      textColor = v.inactiveForeground.withValues(
        alpha: hovered ? 1 : _segmentedInactiveOpacity,
      );
    }

    final glyphs = <Widget>[
      if (tab.icon case final icon?)
        IconTheme.merge(
          data: IconThemeData(size: _iconSize, color: textColor),
          child: ExcludeSemantics(child: icon),
        ),
      Text(
        tab.label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.clip,
        style: v.labelStyle.copyWith(color: textColor),
      ),
    ];

    Widget body = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: _tabPadX,
        vertical: _tabPadY,
      ),
      child: Row(
        mainAxisSize: _horizontal ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: _horizontal
            ? MainAxisAlignment.center
            : MainAxisAlignment.start,
        spacing: theme.spacing(1.5),
        children: glyphs,
      ),
    );

    // Underline tabs tint on hover; the focus ring overlays without shifting
    // layout. The segmented active background is the sliding indicator, not the
    // tab.
    body = DecoratedBox(
      decoration: ShapeDecoration(
        color: underline && hovered ? v.hoverColor : null,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(v.tabRadius),
        ),
      ),
      child: body,
    );

    if (_focused == index) {
      body = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          shape: RoundedSuperellipseBorder(
            side: BorderSide(color: theme.colors.ring, width: _ringWidth),
            borderRadius: BorderRadius.circular(v.tabRadius),
          ),
        ),
        child: body,
      );
    }

    final node = _nodeFor(tab.value);
    Widget interactive = MouseRegion(
      cursor: tab.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: tab.enabled ? (_) => setState(() => _hovered = index) : null,
      onExit: tab.enabled
          ? (_) {
              if (_hovered == index) setState(() => _hovered = null);
            }
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: tab.enabled
            ? () {
                node.requestFocus();
                _select(tab.value);
              }
            : null,
        child: Focus(
          focusNode: node,
          canRequestFocus: tab.enabled,
          skipTraversal: !tab.enabled,
          onFocusChange: (focused) => setState(() {
            if (focused) {
              _focused = index;
            } else if (_focused == index) {
              _focused = null;
            }
          }),
          onKeyEvent: (_, event) => _onKey(event, index),
          child: body,
        ),
      ),
    );

    if (!tab.enabled) {
      interactive = Opacity(
        opacity: _disabledOpacity,
        child: IgnorePointer(child: interactive),
      );
    }

    return KeyedSubtree(
      key: _keyFor(tab.value),
      child: Semantics(
        role: SemanticsRole.tab,
        container: true,
        selected: selected,
        enabled: tab.enabled,
        button: true,
        label: tab.label,
        onTap: tab.enabled ? () => _select(tab.value) : null,
        child: ExcludeSemantics(child: interactive),
      ),
    );
  }
}

/// Builds the default appearance from the theme tokens for [variant], then lays
/// a per-instance [override] over it field by field.
_TabsVisuals _resolve(
  FossThemeData theme,
  FossTabsVariant variant,
  bool dark,
  FossTabsStyle? override,
) {
  final c = theme.colors;
  final segmented = variant == FossTabsVariant.segmented;
  return _TabsVisuals(
    barColor: override?.barColor ?? c.muted,
    indicatorColor:
        override?.indicatorColor ??
        (segmented ? (dark ? c.input : c.background) : c.primary),
    indicatorShadow:
        override?.indicatorShadow ??
        (segmented ? theme.shadows.sm : const <BoxShadow>[]),
    hoverColor: override?.hoverColor ?? c.accent,
    activeForeground: override?.activeForeground ?? c.foreground,
    inactiveForeground: override?.inactiveForeground ?? c.mutedForeground,
    labelStyle: override?.labelStyle ?? theme.typography.base.medium,
    barRadius: theme.radii.lg,
    tabRadius: theme.radii.md,
  );
}

/// The fully resolved, non-null appearance. A [FossTabsStyle] override is laid
/// over it by [_resolve], so the widget reads only non-null fields.
@immutable
class _TabsVisuals {
  const _TabsVisuals({
    required this.barColor,
    required this.indicatorColor,
    required this.indicatorShadow,
    required this.hoverColor,
    required this.activeForeground,
    required this.inactiveForeground,
    required this.labelStyle,
    required this.barRadius,
    required this.tabRadius,
  });

  final Color barColor;
  final Color indicatorColor;
  final List<BoxShadow> indicatorShadow;
  final Color hoverColor;
  final Color activeForeground;
  final Color inactiveForeground;
  final TextStyle labelStyle;
  final double barRadius;
  final double tabRadius;
}
