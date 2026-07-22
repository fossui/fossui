import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/toggle/foss_toggle.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_toggle_group_style.dart';

/// Cell height of a joined outline bar, matching the toggle tap target so the
/// segments sit flush against the shared frame.
const double _cellHeight = 44;

/// One entry in a [FossToggleGroup]: a [value] id, an optional [leading] icon
/// and [child] label, and its own [enabled] flag. Its pressed state is derived
/// from the group selection, not stored here, so it is a plain configuration
/// object rather than a widget.
///
/// A null [child] with a [leading] icon makes a square icon-only entry; name it
/// for assistive tech with [semanticLabel].
///
/// ```dart
/// FossToggleGroupItem(
///   value: 'bold',
///   leading: const Icon(LucideIcons.bold),
///   semanticLabel: 'Bold',
/// );
/// ```
@immutable
class FossToggleGroupItem {
  /// Creates a group entry. [value] identifies it within the group and must be
  /// unique among the group's items.
  const FossToggleGroupItem({
    required this.value,
    this.leading,
    this.child,
    this.semanticLabel,
    this.enabled = true,
  });

  /// The id this entry contributes to the group selection, compared by `==`.
  final String value;

  /// Optional widget before the label, themed as an icon. When [child] is null
  /// it is the sole content of a square icon-only entry.
  final Widget? leading;

  /// The label, typically a [Text]. Null makes a square icon-only entry.
  final Widget? child;

  /// Accessibility name, required in spirit for an icon-only entry.
  final String? semanticLabel;

  /// Whether this entry accepts input. Disabled when false or when the group is
  /// disabled.
  final bool enabled;
}

/// {@category Inputs}
/// {@template foss.toggleGroup.preview}
/// <img src="https://fossui.org/components/toggle-group/overview/light.png"
///   alt="FossToggleGroup, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/toggle-group/overview/dark.png"
///   alt="FossToggleGroup, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the
/// [toggle group documentation ↗](https://fossui.org/docs/components/toggle-group)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/toggle_group/fosstogglegroup/playground).
/// {@endtemplate}
///
/// Binds a row or column of toggles to one shared selection. Each
/// [FossToggleGroupItem]'s pressed state is its membership in the group value,
/// and [variant] and [size] propagate to every item, so the toggles line up and
/// restyle together.
///
/// Use [FossToggleGroup.single] for a one-of-many choice (a `String` value that
/// swaps, and clears to null when the active item is tapped again) or
/// [FossToggleGroup.multiple] for independent toggles (a `Set<String>`). In the
/// [FossToggleVariant.outline] variant the items join into one segmented bar
/// with a shared border and rounded outer ends; in
/// [FossToggleVariant.standard] they sit as separate buttons with a small gap.
///
/// A null `onChanged` or `enabled: false` disables the whole group; an item
/// own `enabled: false` disables just that one. Colors, radius, and spacing
/// come from `context.fossTheme`; pass a [FossToggleGroupStyle] to [style] for
/// a one-off.
///
/// {@macro foss.customize}
///
/// See also [FossToggle] for a single two-state button.
///
/// ```dart
/// FossToggleGroup.single(
///   value: alignment,
///   variant: FossToggleVariant.outline,
///   onChanged: (v) => setState(() => alignment = v),
///   children: const [
///     FossToggleGroupItem(value: 'left', child: Text('Left')),
///     FossToggleGroupItem(value: 'center', child: Text('Center')),
///     FossToggleGroupItem(value: 'right', child: Text('Right')),
///   ],
/// );
/// ```
@FossSince('0.1.1')
class FossToggleGroup extends StatelessWidget {
  /// {@macro foss.toggleGroup.preview}
  ///
  /// Creates a single-selection group. One item is on at a time; selecting
  /// another swaps it, and tapping the active item again clears it to null.
  const FossToggleGroup.single({
    required this.children,
    required String? value,
    required ValueChanged<String?> onChanged,
    this.variant = FossToggleVariant.standard,
    this.size = FossToggleSize.md,
    this.orientation = Axis.horizontal,
    this.enabled = true,
    this.style,
    super.key,
  }) : _single = true,
       _value = value,
       _onSingleChanged = onChanged,
       _values = const {},
       _onMultipleChanged = null;

  /// {@macro foss.toggleGroup.preview}
  ///
  /// Creates a multi-selection group. Items toggle independently in and out of
  /// the [value] set.
  const FossToggleGroup.multiple({
    required this.children,
    required Set<String> value,
    required ValueChanged<Set<String>> onChanged,
    this.variant = FossToggleVariant.standard,
    this.size = FossToggleSize.md,
    this.orientation = Axis.horizontal,
    this.enabled = true,
    this.style,
    super.key,
  }) : _single = false,
       _values = value,
       _onMultipleChanged = onChanged,
       _value = null,
       _onSingleChanged = null;

  /// The entries laid out and bound to the selection.
  final List<FossToggleGroupItem> children;

  /// The visual treatment, propagated to every item. Defaults to
  /// [FossToggleVariant.standard].
  final FossToggleVariant variant;

  /// The size, propagated to every item. Defaults to [FossToggleSize.md].
  final FossToggleSize size;

  /// The layout axis. Defaults to [Axis.horizontal].
  final Axis orientation;

  /// Whether the group accepts input. When false every item is disabled.
  final bool enabled;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossToggleGroupStyle? style;

  final bool _single;
  final String? _value;
  final ValueChanged<String?>? _onSingleChanged;
  final Set<String> _values;
  final ValueChanged<Set<String>>? _onMultipleChanged;

  bool _isOn(FossToggleGroupItem item) =>
      _single ? _value == item.value : _values.contains(item.value);

  void _onToggle(FossToggleGroupItem item, {required bool on}) {
    if (_single) {
      // Tapping the active item clears the selection to null.
      _onSingleChanged?.call(on ? null : item.value);
      return;
    }
    final next = Set<String>.of(_values);
    if (on) {
      next.remove(item.value);
    } else {
      next.add(item.value);
    }
    _onMultipleChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      children.map((c) => c.value).toSet().length == children.length,
      'FossToggleGroup item values must be unique; a duplicate makes two cells '
      'share selection state.',
    );
    final theme = context.fossTheme;
    final resolved = _GroupVisuals.resolve(theme, style);
    final outline = variant == FossToggleVariant.outline;
    final direction = Directionality.of(context);
    final radius = Radius.circular(theme.radii.lg);
    final last = children.length - 1;

    final items = <Widget>[
      for (var i = 0; i < children.length; i++)
        _item(
          children[i],
          outline: outline,
          corners: _cornerRadius(
            radius: radius,
            isFirst: i == 0,
            isLast: i == last,
            orientation: orientation,
            direction: direction,
          ),
        ),
    ];

    Widget bar;
    if (outline) {
      // Join the cells into one bar with 1px seams; the shared frame rounds the
      // outer ends over the flush segments.
      final seamed = <Widget>[
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) _Seam(orientation: orientation, color: resolved.border),
          items[i],
        ],
      ];
      final joined = Flex(
        direction: orientation,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: seamed,
      );
      bar = CustomPaint(
        foregroundPainter: _FramePainter(
          color: resolved.border,
          radius: theme.radii.lg,
        ),
        // Bound the cross axis so the seams and cells can stretch to a shared
        // extent even when the group sits in an unbounded slot (a scroll view).
        child: orientation == Axis.horizontal
            ? IntrinsicHeight(child: joined)
            : IntrinsicWidth(child: joined),
      );
    } else {
      bar = Flex(
        direction: orientation,
        mainAxisSize: MainAxisSize.min,
        spacing: resolved.gap,
        children: items,
      );
    }

    return Semantics(
      container: true,
      // A single-select group is a radio group; multiple-select has no matching
      // role, so it stays a bare container.
      role: _single ? SemanticsRole.radioGroup : SemanticsRole.none,
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: bar,
      ),
    );
  }

  Widget _item(
    FossToggleGroupItem item, {
    required bool outline,
    required BorderRadius corners,
  }) {
    final on = _isOn(item);
    final itemEnabled = enabled && item.enabled;
    return FossToggle(
      pressed: on,
      onPressedChanged: itemEnabled ? (_) => _onToggle(item, on: on) : null,
      variant: variant,
      size: size,
      leading: item.leading,
      semanticLabel: item.semanticLabel,
      style: outline
          ? FossToggleStyle(
              side: BorderSide.none,
              shadow: const [],
              cornerRadius: corners,
              minHeight: _cellHeight,
            )
          : null,
      child: item.child,
    );
  }
}

/// Resolves the joined-bar corners for an item at a position. A horizontal
/// group rounds along the reading axis and mirrors under RTL; a vertical group
/// rounds top to bottom. The first item rounds its leading corners, the last
/// its trailing corners, and the middle items stay square.
BorderRadius _cornerRadius({
  required Radius radius,
  required bool isFirst,
  required bool isLast,
  required Axis orientation,
  required TextDirection direction,
}) {
  if (isFirst && isLast) return BorderRadius.all(radius);
  var topLeft = Radius.zero;
  var topRight = Radius.zero;
  var bottomLeft = Radius.zero;
  var bottomRight = Radius.zero;

  if (orientation == Axis.vertical) {
    if (isFirst) {
      topLeft = radius;
      topRight = radius;
    }
    if (isLast) {
      bottomLeft = radius;
      bottomRight = radius;
    }
  } else {
    final ltr = direction == TextDirection.ltr;
    if (isFirst) {
      if (ltr) {
        topLeft = bottomLeft = radius;
      } else {
        topRight = bottomRight = radius;
      }
    }
    if (isLast) {
      if (ltr) {
        topRight = bottomRight = radius;
      } else {
        topLeft = bottomLeft = radius;
      }
    }
  }

  return BorderRadius.only(
    topLeft: topLeft,
    topRight: topRight,
    bottomLeft: bottomLeft,
    bottomRight: bottomRight,
  );
}

/// A 1px divider between two joined outline cells, stretched to fill the bar's
/// cross axis by the enclosing [Flex].
class _Seam extends StatelessWidget {
  const _Seam({required this.orientation, required this.color});

  final Axis orientation;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final horizontal = orientation == Axis.horizontal;
    return SizedBox(
      width: horizontal ? 1 : null,
      height: horizontal ? null : 1,
      child: ColoredBox(color: color),
    );
  }
}

/// The resolved group appearance: the item gap and the connected-bar border.
@immutable
class _GroupVisuals {
  const _GroupVisuals({required this.gap, required this.border});

  factory _GroupVisuals.resolve(FossThemeData theme, FossToggleGroupStyle? s) =>
      _GroupVisuals(
        gap: s?.gap ?? theme.spacing(0.5),
        border: s?.connectedBorderColor ?? theme.colors.input,
      );

  final double gap;
  final Color border;
}

/// Paints the shared 1px frame around a joined outline bar as a superellipse,
/// rounding the outer ends over the flush segments.
class _FramePainter extends CustomPainter {
  const _FramePainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(0.5);
    canvas.drawRSuperellipse(
      RSuperellipse.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.color != color || old.radius != radius;
}
