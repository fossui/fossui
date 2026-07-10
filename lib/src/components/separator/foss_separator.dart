import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/theme.dart';

/// The axis a [FossSeparator] runs along.
enum FossSeparatorOrientation {
  /// Fills the available width at 1 logical pixel tall (the default).
  horizontal,

  /// Fills the parent's height at 1 logical pixel wide.
  vertical,
}

/// {@category Layout}
/// {@template foss.separator.preview}
/// <img src="https://fossui.org/components/separator/overview/light.png"
///   alt="FossSeparator, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/separator/overview/dark.png"
///   alt="FossSeparator, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [separator documentation ↗](https://fossui.org/docs/components/separator) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/#/?path=components/separator/fossseparator/playground).
/// {@endtemplate}
///
/// A hairline rule that divides content along a row or a column. Static and
/// non-interactive: a 1 logical pixel line in the `border` role.
///
/// [orientation] picks the axis. The rule fills its long axis, so that axis
/// must be bounded by the parent. [FossSeparatorOrientation.horizontal] (the
/// default) fills the width, so it needs a bounded-width parent (a [Column]
/// with stretch, or an [Expanded] inside a [Row]); vertical fills the height
/// and needs a bounded-height parent (a [Row], for example, supplies it). An
/// unbounded long axis surfaces a layout error rather than misrendering. The
/// color comes from `context.fossTheme`; retheme globally through
/// `FossColors.border` rather than per instance.
///
/// Decorative by default: [decorative] true keeps the line out of the semantics
/// tree, the common case for a purely visual rule. Set it false to mark a real
/// content boundary; the line then emits a structural boundary node that groups
/// and separates the surrounding content. The node carries no spoken label by
/// design, since a divider names nothing.
///
/// ```dart
/// Column(
///   crossAxisAlignment: CrossAxisAlignment.stretch,
///   children: [
///     Text('Above'),
///     FossSeparator(),
///     Text('Below'),
///   ],
/// );
/// ```
class FossSeparator extends StatelessWidget {
  /// {@macro foss.separator.preview}
  ///
  /// Creates a hairline separator.
  const FossSeparator({
    this.orientation = FossSeparatorOrientation.horizontal,
    this.decorative = true,
    super.key,
  });

  /// The axis the rule runs along; [FossSeparatorOrientation.horizontal] by
  /// default.
  final FossSeparatorOrientation orientation;

  /// Whether the rule is purely visual. When true (the default) the line is
  /// hidden from the semantics tree; set it false to expose a content boundary.
  final bool decorative;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = orientation == FossSeparatorOrientation.horizontal;

    // double.infinity fills the long axis (clamped to the parent's bound); the
    // 1px short axis is the only baked metric. That long axis must be bounded
    // by the parent, else the infinite extent has nothing to clamp against.
    final line = SizedBox(
      width: isHorizontal ? double.infinity : 1,
      height: isHorizontal ? 1 : double.infinity,
      child: ColoredBox(color: context.fossTheme.colors.border),
    );

    return decorative
        ? ExcludeSemantics(child: line)
        : Semantics(container: true, child: line);
  }
}
