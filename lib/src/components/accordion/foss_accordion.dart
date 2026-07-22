import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_accordion_style.dart';

// Header geometry, mobile base. The chevron is painted in-package, so its size
// and opacity are widget constants rather than tokens.
const double _chevronSize = 16;
const double _chevronOpacity = 0.80;
const double _chevronStroke = 1.5;

// The chevron aligns to the first line of the title, nudged down to sit on the
// text baseline rather than the line box top.
const double _chevronNudge = 2;

const double _disabledOpacity = 0.64;
const double _ringWidth = 3;
const double _minTapTarget = 48;

/// One collapsible section of a [FossAccordion]: a [value] id, a [title]
/// header, and a [child] panel revealed when the section is open.
///
/// This is data passed to [FossAccordion.children], not a widget. The accordion
/// owns the open set and renders the header, chevron, and animated panel.
///
/// ```dart
/// const FossAccordionItem(
///   value: 'shipping',
///   title: Text('Shipping'),
///   child: Text('Ships in two business days.'),
/// );
/// ```
@FossSince('0.1.1')
@immutable
class FossAccordionItem {
  /// Creates a section keyed by [value].
  const FossAccordionItem({
    required this.value,
    required this.title,
    required this.child,
    this.enabled = true,
  });

  /// The id of this section, unique within a [FossAccordion].
  final String value;

  /// The header content. Any widget; text inherits the title style.
  final Widget title;

  /// The panel content, revealed when the section is open. Any widget; text
  /// inherits the muted panel style.
  final Widget child;

  /// Whether the section accepts input. A disabled section dims and is skipped
  /// by the pointer and the keyboard.
  final bool enabled;
}

/// {@category Layout}
/// {@template foss.accordion.preview}
/// <img src="https://fossui.org/components/accordion/overview/light.png"
///   alt="FossAccordion, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/accordion/overview/dark.png"
///   alt="FossAccordion, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [accordion documentation ↗](https://fossui.org/docs/components/accordion)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/accordion/fossaccordion/playground).
/// {@endtemplate}
///
/// A stack of collapsible sections: each header toggles a panel of content open
/// or closed, with a rotating chevron and an animated height.
///
/// [FossAccordion] owns the open set. Pass [value] with [onValueChanged] to
/// control it, or leave [value] null and seed [initialValue] to let the widget
/// hold its own set. In single mode (the default) opening a section closes the
/// others; set [multiple] to keep any number open. In single mode [collapsible]
/// lets the open section close on a second tap, so zero can be open.
///
/// Colors, type, the chevron rotation, and the panel slide come from
/// `context.fossTheme`; pass a [FossAccordionStyle] to [style] for a one-off.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossAccordion(
///   initialValue: const {'a'},
///   children: const [
///     FossAccordionItem(
///       value: 'a',
///       title: Text('Is it accessible?'),
///       child: Text('Yes. It follows the accessibility pattern.'),
///     ),
///     FossAccordionItem(
///       value: 'b',
///       title: Text('Is it styled?'),
///       child: Text('Yes. It reads its colors and type from the theme.'),
///     ),
///   ],
/// );
/// ```
@FossSince('0.1.1')
class FossAccordion extends StatefulWidget {
  /// {@macro foss.accordion.preview}
  ///
  /// Creates an accordion over [children].
  const FossAccordion({
    required this.children,
    this.multiple = false,
    this.collapsible = true,
    this.initialValue,
    this.value,
    this.onValueChanged,
    this.style,
    super.key,
  }) : assert(
         value == null || initialValue == null,
         'Pass value (controlled) or initialValue (uncontrolled), not both.',
       );

  /// The ordered sections. Each [FossAccordionItem.value] must be unique.
  final List<FossAccordionItem> children;

  /// Whether more than one section may be open at once. Defaults to false
  /// (single): opening a section closes the others.
  final bool multiple;

  /// In single mode, whether the open section closes on a second tap (so zero
  /// sections can be open). Ignored when [multiple] is true. Defaults to true.
  final bool collapsible;

  /// The open set when uncontrolled ([value] is null). The widget owns the set
  /// after seeding.
  final Set<String>? initialValue;

  /// The open set when controlled. The parent owns the set and the widget
  /// renders it.
  final Set<String>? value;

  /// Called with the next open set whenever a section toggles. Fires in both
  /// controlled and uncontrolled modes.
  final ValueChanged<Set<String>>? onValueChanged;

  /// Per-instance overrides layered on the theme-resolved style.
  final FossAccordionStyle? style;

  @override
  State<FossAccordion> createState() => _FossAccordionState();
}

class _FossAccordionState extends State<FossAccordion> {
  final Map<String, FocusNode> _nodes = <String, FocusNode>{};
  late Set<String> _internal;
  String? _focused;

  Set<String> get _open => widget.value ?? _internal;

  @override
  void initState() {
    super.initState();
    assert(() {
      final ids = widget.children.map((c) => c.value).toList();
      return ids.length == ids.toSet().length;
    }(), 'FossAccordionItem values must be unique.');
    _internal = _seed();
  }

  @override
  void didUpdateWidget(FossAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    final values = widget.children.map((c) => c.value).toSet();
    final stale = _nodes.keys.where((v) => !values.contains(v)).toList();
    for (final value in stale) {
      _nodes.remove(value)?.dispose();
    }
    if (_focused != null && !values.contains(_focused)) _focused = null;
    // Uncontrolled: drop open ids whose item was removed. Prune now so the
    // render is correct; defer the notify to after the frame, since firing
    // onValueChanged during a parent rebuild would setState mid-build.
    if (widget.value == null) {
      final pruned = _internal.intersection(values);
      if (pruned.length != _internal.length) {
        _internal = pruned;
        final notify = widget.onValueChanged;
        if (notify != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) notify(pruned);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  // Single mode holds at most one id: keep the first seed in children order and
  // drop the rest, so the invariant holds from the first frame.
  Set<String> _seed() {
    final initial = widget.initialValue;
    if (initial == null) return <String>{};
    if (widget.multiple) return <String>{...initial};
    for (final item in widget.children) {
      if (initial.contains(item.value)) return <String>{item.value};
    }
    return <String>{};
  }

  FocusNode _nodeFor(String value) => _nodes.putIfAbsent(value, FocusNode.new);

  void _toggle(String value) {
    final open = _open;
    final Set<String> next;
    if (widget.multiple) {
      next = <String>{...open};
      if (!next.add(value)) next.remove(value);
    } else if (open.contains(value)) {
      next = widget.collapsible ? <String>{} : open;
    } else {
      next = <String>{value};
    }
    if (next.length == open.length && next.containsAll(open)) return;
    widget.onValueChanged?.call(next);
    if (widget.value == null) setState(() => _internal = next);
  }

  // Walks from [from] by [step], skipping disabled sections, without wrapping.
  int? _adjacent(int from, int step) {
    for (var i = from + step; i >= 0 && i < widget.children.length; i += step) {
      if (widget.children[i].enabled) return i;
    }
    return null;
  }

  int? _edge({required bool last}) {
    final indices = List<int>.generate(widget.children.length, (i) => i);
    for (final i in last ? indices.reversed : indices) {
      if (widget.children[i].enabled) return i;
    }
    return null;
  }

  void _moveFocus(int? target) {
    if (target == null) return;
    _nodeFor(widget.children[target].value).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final v = _resolve(theme, widget.style);
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < widget.children.length; i++)
          _buildItem(theme, v, reduceMotion, i),
      ],
    );
  }

  Widget _buildItem(
    FossThemeData theme,
    _AccordionVisuals v,
    bool reduceMotion,
    int index,
  ) {
    final item = widget.children[index];
    final open = _open.contains(item.value);
    final last = index == widget.children.length - 1;
    final duration = reduceMotion ? Duration.zero : theme.motion.overlay;

    Widget header = Padding(
      padding: v.headerPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: v.headerGap,
        children: <Widget>[
          Expanded(
            child: DefaultTextStyle.merge(
              style: v.titleStyle,
              child: item.title,
            ),
          ),
          _Chevron(
            open: open,
            color: v.chevronColor,
            duration: duration,
          ),
        ],
      ),
    );

    header = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _minTapTarget),
      child: header,
    );

    if (_focused == item.value && item.enabled) {
      header = CustomPaint(
        foregroundPainter: _RingPainter(
          color: theme.colors.ring,
          radius: theme.radii.md,
        ),
        child: header,
      );
    }

    final trigger = MergeSemantics(
      child: Semantics(
        button: true,
        expanded: open,
        enabled: item.enabled,
        onTap: item.enabled ? () => _toggle(item.value) : null,
        child: FocusableActionDetector(
          enabled: item.enabled,
          focusNode: _nodeFor(item.value),
          mouseCursor: item.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          // Only clear when this item owns the highlight: on an arrow move the
          // next item's highlight-on can arrive before this one's off, and an
          // unguarded clear would drop the ring off the focused item.
          onShowFocusHighlight: (value) {
            if (value) {
              setState(() => _focused = item.value);
            } else if (_focused == item.value) {
              setState(() => _focused = null);
            }
          },
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.arrowDown): _MoveFocusIntent(1),
            SingleActivator(LogicalKeyboardKey.arrowUp): _MoveFocusIntent(-1),
            SingleActivator(LogicalKeyboardKey.home): _EdgeFocusIntent(
              last: false,
            ),
            SingleActivator(LogicalKeyboardKey.end): _EdgeFocusIntent(
              last: true,
            ),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _toggle(item.value);
                return null;
              },
            ),
            _MoveFocusIntent: CallbackAction<_MoveFocusIntent>(
              onInvoke: (intent) {
                _moveFocus(_adjacent(index, intent.step));
                return null;
              },
            ),
            _EdgeFocusIntent: CallbackAction<_EdgeFocusIntent>(
              onInvoke: (intent) {
                _moveFocus(_edge(last: intent.last));
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: item.enabled ? () => _toggle(item.value) : null,
            child: header,
          ),
        ),
      ),
    );

    final panel = _Panel(
      open: open,
      duration: duration,
      child: Padding(
        padding: v.panelPadding,
        child: DefaultTextStyle.merge(style: v.panelStyle, child: item.child),
      ),
    );

    Widget section = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[trigger, panel],
    );

    if (!last) {
      section = DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: v.dividerColor)),
        ),
        child: section,
      );
    }
    if (!item.enabled) {
      section = Opacity(opacity: _disabledOpacity, child: section);
    }
    return section;
  }
}

/// Moves keyboard focus to the section [step] away (skipping disabled ones).
class _MoveFocusIntent extends Intent {
  const _MoveFocusIntent(this.step);

  final int step;
}

/// Moves keyboard focus to the first ([last] false) or last section.
class _EdgeFocusIntent extends Intent {
  const _EdgeFocusIntent({required this.last});

  final bool last;
}

/// The chevron: a down-pointing glyph that rotates to point up when [open].
class _Chevron extends StatelessWidget {
  const _Chevron({
    required this.open,
    required this.color,
    required this.duration,
  });

  final bool open;
  final Color color;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: open ? 1 : 0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, t, child) => Transform.translate(
        offset: const Offset(0, _chevronNudge),
        child: Transform.rotate(angle: t * math.pi, child: child),
      ),
      child: CustomPaint(
        size: const Size.square(_chevronSize),
        painter: _ChevronPainter(color),
      ),
    );
  }
}

/// The collapsible panel: its height animates between 0 and the content's
/// natural height, clipped so content never spills during the transition.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.open,
    required this.duration,
    required this.child,
  });

  final bool open;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: open ? 1 : 0),
      duration: duration,
      curve: Curves.easeInOut,
      builder: (context, t, child) => ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: t,
          child: child,
        ),
      ),
      // Closed content stays out of the semantics tree; only the open panel is
      // announced as the header's region.
      child: ExcludeSemantics(excluding: !open, child: child),
    );
  }
}

/// Paints a down-pointing chevron centered in its box.
class _ChevronPainter extends CustomPainter {
  const _ChevronPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.25, h * 0.375)
      ..lineTo(w * 0.5, h * 0.625)
      ..lineTo(w * 0.75, h * 0.375);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _chevronStroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_ChevronPainter old) => old.color != color;
}

/// Paints the focus ring: a superellipse outset hugging the trigger at
/// [radius], so the ring reads smooth, not circular.
class _RingPainter extends CustomPainter {
  const _RingPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).inflate(_ringWidth / 2);
    canvas.drawRSuperellipse(
      RSuperellipse.fromRectAndRadius(
        rect,
        Radius.circular(radius + _ringWidth / 2),
      ),
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

/// Builds the default appearance from the theme tokens, then lays a
/// per-instance [override] over it field by field.
_AccordionVisuals _resolve(FossThemeData theme, FossAccordionStyle? override) {
  final c = theme.colors;
  final t = theme.typography;
  final gap = theme.spacing(4);
  return _AccordionVisuals(
    titleStyle:
        override?.titleTextStyle ?? t.sm.medium.copyWith(color: c.foreground),
    panelStyle:
        override?.panelTextStyle ?? t.sm.copyWith(color: c.mutedForeground),
    chevronColor:
        override?.chevronColor ??
        c.foreground.withValues(alpha: _chevronOpacity),
    dividerColor: override?.dividerColor ?? c.border,
    headerPadding:
        override?.headerPadding ?? EdgeInsets.symmetric(vertical: gap),
    panelPadding: override?.panelPadding ?? EdgeInsets.only(bottom: gap),
    headerGap: gap,
  );
}

/// The fully resolved, non-null appearance. A [FossAccordionStyle] override is
/// laid over it by [_resolve], so the widget reads only non-null fields.
@immutable
class _AccordionVisuals {
  const _AccordionVisuals({
    required this.titleStyle,
    required this.panelStyle,
    required this.chevronColor,
    required this.dividerColor,
    required this.headerPadding,
    required this.panelPadding,
    required this.headerGap,
  });

  final TextStyle titleStyle;
  final TextStyle panelStyle;
  final Color chevronColor;
  final Color dividerColor;
  final EdgeInsetsGeometry headerPadding;
  final EdgeInsetsGeometry panelPadding;
  final double headerGap;
}
