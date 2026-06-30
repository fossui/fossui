import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/theme/theme.dart';

part 'foss_progress_style.dart';

// The track is a fixed-height bar; its height is a component constant, not a
// token (nothing else references it). The fill eases over its width with a
// plain ease; curves are widget constants, not tokens.
const double _trackHeight = 6;
const Curve _fillCurve = Curves.ease;

/// A determinate progress bar: a full-width track with a leading fill that
/// grows from the start to show how far a long task has run. It is static and
/// non-interactive.
///
/// [value] is the filled fraction in `0..1`, clamped on input. An optional
/// [label] sits at the start of a row above the track and [valueLabel] at the
/// end; the row renders only when at least one is set. The fill animates its
/// width over the `progress` motion token and jumps under reduced motion.
/// Colors, type, and radius come from `context.fossTheme`; pass a
/// [FossProgressStyle] for a one-off override.
///
/// ```dart
/// FossProgress(
///   value: 0.4,
///   label: 'Uploading',
///   valueLabel: '40%',
/// );
/// ```
class FossProgress extends StatelessWidget {
  /// Creates a progress bar filled to [value] (`0..1`, clamped). A bare track
  /// with no label row is the default.
  const FossProgress({
    required this.value,
    this.label,
    this.valueLabel,
    this.semanticsLabel,
    this.style,
    super.key,
  });

  /// The filled fraction, in `0..1`. Values outside the range are clamped.
  final double value;

  /// Text at the start of the row above the track; null hides it.
  final String? label;

  /// Text at the end of the row above the track, the caller's formatted value
  /// (`'40%'`, `'3 of 8'`); null hides it.
  final String? valueLabel;

  /// Accessibility name for the bar when there is no visible [label].
  final String? semanticsLabel;

  /// Per-instance visual overrides.
  final FossProgressStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final s = style;

    final fraction = value.clamp(0.0, 1.0);
    final radius = BorderRadius.circular(FossRadii.full);
    final shape = RoundedSuperellipseBorder(borderRadius: radius);

    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final track = DecoratedBox(
      decoration: ShapeDecoration(
        color: s?.trackColor ?? colors.input,
        shape: shape,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: SizedBox(
          height: _trackHeight,
          width: double.infinity,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: fraction),
            duration: reduceMotion ? Duration.zero : theme.motion.progress,
            curve: _fillCurve,
            builder: (context, t, _) => FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: t,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: s?.fillColor ?? colors.primary,
                  shape: shape,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final row = _buildRow(theme, colors, s);

    return Semantics(
      container: true,
      label: label ?? semanticsLabel,
      value: '${(fraction * 100).round()}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing(2),
        children: [
          ?row,
          track,
        ],
      ),
    );
  }

  Widget? _buildRow(
    FossThemeData theme,
    FossColors colors,
    FossProgressStyle? s,
  ) {
    if (label == null && valueLabel == null) return null;

    // The bar's name and value live on the Semantics container, so the visible
    // row text is excluded to avoid a double announcement.

    final labelStyle = theme.typography.sm.medium
        .copyWith(color: colors.foreground)
        .merge(s?.labelStyle);
    // Tabular figures keep the digits from jittering as the value changes.
    final valueStyle = theme.typography.sm
        .copyWith(
          color: colors.foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
        )
        .merge(s?.valueLabelStyle);

    return ExcludeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Text(label ?? '', style: labelStyle),
          ),
          if (valueLabel case final valueLabel?)
            Text(valueLabel, style: valueStyle),
        ],
      ),
    );
  }
}
