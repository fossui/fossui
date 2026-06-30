import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/theme/theme.dart';

/// The axis a [FossSeparator] runs along.
enum FossSeparatorOrientation {
  /// Fills the available width at 1 logical pixel tall (the default).
  horizontal,

  /// Fills the parent's height at 1 logical pixel wide.
  vertical,
}

/// A hairline rule that divides content along a row or a column. Static and
/// non-interactive: a 1 logical pixel line in the `border` role.
///
/// [orientation] picks the axis. [FossSeparatorOrientation.horizontal] (the
/// default) fills the available width; [FossSeparatorOrientation.vertical]
/// fills the parent's height and so needs a bounded cross-axis height (a [Row],
/// for example, supplies the line's height). The color comes from
/// `context.fossTheme`; retheme globally through `FossColors.border` rather
/// than per instance.
///
/// Decorative by default: [decorative] true keeps the line out of the semantics
/// tree, the common case for a purely visual rule. Set it false when the line
/// marks a real content boundary, so assistive tech reaches it as a node.
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
    // 1px short axis is the only baked metric. Vertical needs a bounded parent
    // height, else the infinite extent has nothing to clamp against.
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
