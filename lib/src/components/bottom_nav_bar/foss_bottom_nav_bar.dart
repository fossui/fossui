import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_bottom_nav_bar_style.dart';
part 'foss_bottom_nav_bar_view.dart';
part 'foss_bottom_nav_bar_visuals.dart';

/// One destination in a [FossBottomNavBar]: its [value], [label], glyphs, an
/// optional [badge], and whether it is [enabled].
///
/// This is data passed to [FossBottomNavBar.items], not a widget, so the bar
/// owns the icon size, the colors, and the layout of every cell. [label] is
/// required: it is the name the cell announces.
///
/// ```dart
/// const FossBottomNavItem(
///   value: 'home',
///   label: 'Home',
///   icon: Icon(Icons.home_outlined),
/// );
/// ```
@immutable
@FossSince('0.1.3')
class FossBottomNavItem<T> {
  /// Creates a destination carrying [value] and [label].
  const FossBottomNavItem({
    required this.value,
    required this.label,
    this.icon,
    this.selectedIcon,
    this.badge,
    this.enabled = true,
  });

  /// The value this destination reports. Unique within a [FossBottomNavBar].
  final T value;

  /// The text under the glyph, and the name the cell announces.
  final String label;

  /// The glyph above the label, sized and colored by the bar. Any widget; no
  /// icon dependency.
  final Widget? icon;

  /// Replaces [icon] while this destination is current, for a filled variant
  /// of an outline glyph. Null keeps [icon] and changes only its color.
  final Widget? selectedIcon;

  /// A marker pinned just outside the glyph's top end corner, for a count or a
  /// dot. Decorative: put anything it conveys into [label].
  final Widget? badge;

  /// Whether the destination accepts focus and taps. A disabled cell dims and
  /// is skipped by the keyboard.
  final bool enabled;
}

/// {@category Layout}
/// {@template foss.bottom_nav_bar.preview}
/// <img src="https://fossui.org/components/bottom-nav-bar/overview/light.png"
///   alt="FossBottomNavBar, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/bottom-nav-bar/overview/dark.png"
///   alt="FossBottomNavBar, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the
/// [bottom nav bar documentation ↗](https://fossui.org/docs/components/bottom-nav-bar)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/bottomnavbar/fossbottomnavbar/playground).
/// {@endtemplate}
///
/// A strip of top-level destinations for the bottom of a phone screen: three to
/// five cells, each a glyph over a short label, one of them current.
///
/// The bar is controlled. Pass [value] for the current destination and
/// [onChanged] to hear about taps; it holds no selection state of its own,
/// because the current destination is usually owned by a route or a restored
/// session. Each [FossBottomNavItem] in [items] carries its label, its glyphs,
/// an optional badge, and an enabled flag.
///
/// [onChanged] fires on every tap, including a tap on the destination that is
/// already current, so an app can hang "scroll to top" or "pop to root" off the
/// second tap. A null [onChanged] dims every destination and takes no input; a
/// single one goes inert through [FossBottomNavItem.enabled].
///
/// The bar adds the bottom safe-area inset below itself and paints its fill
/// through it, so place it at the bottom of the screen without wrapping it in a
/// `SafeArea`. Colors and type come from `context.fossTheme`; pass a
/// [FossBottomNavBarStyle] to [style] for a one-off.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossBottomNavBar<String>(
///   value: section,
///   onChanged: (v) => setState(() => section = v),
///   items: const [
///     FossBottomNavItem(value: 'home', label: 'Home', icon: Icon(Icons.home)),
///     FossBottomNavItem(value: 'you', label: 'You', icon: Icon(Icons.person)),
///   ],
/// );
/// ```
@FossSince('0.1.3')
class FossBottomNavBar<T> extends StatefulWidget {
  /// {@macro foss.bottom_nav_bar.preview}
  ///
  /// Creates a bottom navigation bar over [items], with [value] current.
  const FossBottomNavBar({
    required this.items,
    required this.value,
    this.onChanged,
    this.style,
    super.key,
  });

  /// The ordered destinations. Two at minimum; three to five reads best, past
  /// which the labels stop fitting on a phone.
  final List<FossBottomNavItem<T>> items;

  /// The current destination. Matches the [FossBottomNavItem.value] of one of
  /// [items].
  final T value;

  /// Called with a destination's value on every tap, including a tap on the
  /// current one. Null makes the bar inert.
  final ValueChanged<T>? onChanged;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossBottomNavBarStyle? style;

  @override
  State<FossBottomNavBar<T>> createState() => _FossBottomNavBarState<T>();
}

class _FossBottomNavBarState<T> extends State<FossBottomNavBar<T>> {
  final Map<T, FocusNode> _nodes = <T, FocusNode>{};

  bool get _live => widget.onChanged != null;

  @override
  void initState() {
    super.initState();
    assert(_debugItemsValid(), 'Invalid items.');
  }

  @override
  void didUpdateWidget(FossBottomNavBar<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(_debugItemsValid(), 'Invalid items.');
    // Drop nodes for destinations that no longer exist.
    final values = widget.items.map((i) => i.value).toSet();
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

  // These checks cannot live in the constructor without giving up `const`: a
  // list's length and contents are not const expressions. A duplicate value
  // collides in the focus-node map and a value outside the set leaves no cell
  // current, so both are caught here instead.
  bool _debugItemsValid() {
    final values = widget.items.map((i) => i.value).toList();
    assert(
      values.length >= 2,
      'A bottom nav bar needs at least 2 items.',
    );
    assert(
      values.toSet().length == values.length,
      'Item values must be unique.',
    );
    assert(values.contains(widget.value), 'value must match one of the items.');
    return true;
  }

  FocusNode _nodeFor(T value) => _nodes.putIfAbsent(value, FocusNode.new);

  // Reports every tap, with no guard on the tapped value already being current:
  // apps hang scroll-to-top and pop-to-root off the second tap.
  void _select(T value) => widget.onChanged?.call(value);

  // Walks from [from] by [step], skipping disabled destinations, without
  // wrapping.
  int? _adjacent(int from, int step) {
    for (var i = from + step; i >= 0 && i < widget.items.length; i += step) {
      if (widget.items[i].enabled) return i;
    }
    return null;
  }

  int? _edge(bool last) {
    final indices = List<int>.generate(widget.items.length, (i) => i);
    for (final i in last ? indices.reversed : indices) {
      if (widget.items[i].enabled) return i;
    }
    return null;
  }

  KeyEventResult _onKey(KeyEvent event, int index) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.enter) {
      _select(widget.items[index].value);
      return KeyEventResult.handled;
    }

    final ltr = Directionality.of(context) == TextDirection.ltr;
    final target = switch (key) {
      LogicalKeyboardKey.home => _edge(false),
      LogicalKeyboardKey.end => _edge(true),
      LogicalKeyboardKey.arrowRight => _adjacent(index, ltr ? 1 : -1),
      LogicalKeyboardKey.arrowLeft => _adjacent(index, ltr ? -1 : 1),
      _ => null,
    };
    if (target == null) return KeyEventResult.ignored;
    _nodeFor(widget.items[target].value).requestFocus();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _resolve(theme, widget.style);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: v.backgroundColor,
        border: v.showTopBorder
            ? Border(top: BorderSide(color: v.borderColor))
            : null,
      ),
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        child: Semantics(
          role: SemanticsRole.tabBar,
          container: true,
          child: Row(
            children: <Widget>[
              for (var i = 0; i < widget.items.length; i++)
                Expanded(child: _cell(theme, v, i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cell(FossThemeData theme, _NavVisuals v, int index) {
    final item = widget.items[index];
    return _NavCell(
      label: item.label,
      icon: item.selectedIcon != null && item.value == widget.value
          ? item.selectedIcon
          : item.icon,
      badge: item.badge,
      enabled: item.enabled && _live,
      selected: item.value == widget.value,
      visuals: v,
      gap: theme.spacing(1),
      padY: theme.spacing(1.5),
      badgeOffset: theme.spacing(0.5),
      focusNode: _nodeFor(item.value),
      onSelect: () => _select(item.value),
      onKeyEvent: (event) => _onKey(event, index),
    );
  }
}
