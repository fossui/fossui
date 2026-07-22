import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_meter_style.dart';

// The track is a fixed-height bar; its height is a component constant, not a
// token (nothing else references it). It runs two px taller than the progress
// track: the two are siblings, not the same widget. The fill eases over its
// width with a plain ease; curves are widget constants, not tokens.
const double _trackHeight = 8;
const Curve _fillCurve = Curves.ease;

/// {@category Feedback}
/// {@template foss.meter.preview}
/// <img src="https://fossui.org/components/meter/overview/light.png"
///   alt="FossMeter, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/meter/overview/dark.png"
///   alt="FossMeter, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [meter documentation ↗](https://fossui.org/docs/components/meter)
/// or try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/meter/fossmeter/playground).
/// {@endtemplate}
///
/// A static gauge: a full-width track with a leading fill that shows one
/// measurement inside a fixed range (disk used, a quota, a rating). It is the
/// display-only sibling of the progress bar: bounded and non-interactive.
///
/// [value] sits in `[min, max]` (default `0..100`) and is clamped on input; the
/// fill fraction is `(value - min) / (max - min)`. An optional [label] sits at
/// the start of a row above the track and the value at the end; the row renders
/// when [label] is set or [showValue] is true. [formatValue] builds the
/// right-hand text (default a percentage of the range); pass one for a raw or
/// unit form. The fill animates its width over the `progress` motion token and
/// jumps under reduced motion. Colors, type, and radius come from
/// `context.fossTheme`; pass a [FossMeterStyle] for a one-off override.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossMeter(
///   value: 40,
///   label: 'Storage',
/// );
/// ```
@FossSince('0.1.1')
class FossMeter extends StatelessWidget {
  /// {@macro foss.meter.preview}
  ///
  /// Creates a gauge showing [value] within `[min, max]` (clamped). The value
  /// is shown at the end of the label row unless [showValue] is false.
  const FossMeter({
    required this.value,
    this.min = 0,
    this.max = 100,
    this.label,
    this.showValue = true,
    this.formatValue,
    this.semanticsLabel,
    this.style,
    super.key,
  });

  /// The current measurement, clamped into `[min, max]`.
  final num value;

  /// The range floor.
  final num min;

  /// The range ceiling.
  final num max;

  /// Text at the start of the row above the track; null hides it.
  final String? label;

  /// Whether the value is shown at the end of the row above the track.
  final bool showValue;

  /// Builds the value text from the value and range. Defaults to a percentage
  /// of the range (`40%`).
  final String Function(num value, num min, num max)? formatValue;

  /// Accessibility name for the gauge when there is no visible [label].
  final String? semanticsLabel;

  /// Per-instance visual overrides.
  final FossMeterStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final colors = theme.colors;
    final s = style;

    final span = max - min;
    final raw = span > 0 ? (value - min) / span : 0.0;
    // A non-finite value (NaN from a bad computation) must read as empty, not
    // as a full bar: NaN.clamp returns the upper bound on the current SDK.
    final fraction = raw.isFinite ? raw.clamp(0.0, 1.0) : 0.0;
    // The default value text is the fill as a whole-number percentage of the
    // range; a caller formatter takes the raw value and bounds instead.
    final format = formatValue;
    final valueText = format != null
        ? format(value, min, max)
        : '${(fraction * 100).round()}%';

    final shape = RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(FossRadii.full),
    );

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

    return Semantics(
      container: true,
      // Flutter carries no ARIA meter role, so the gauge announces its value
      // and range through the value fields rather than a role.
      label: label ?? semanticsLabel,
      // Announce on the raw scale so value and bounds agree; the visible
      // percent text is for sighted users only.
      value: '$value',
      minValue: '$min',
      maxValue: '$max',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: theme.spacing(2),
        children: [
          ?_buildRow(theme, colors, s, valueText),
          track,
        ],
      ),
    );
  }

  Widget? _buildRow(
    FossThemeData theme,
    FossColors colors,
    FossMeterStyle? s,
    String valueText,
  ) {
    if (label == null && !showValue) return null;

    // The gauge's name and value live on the Semantics container, so the
    // visible row text is excluded to avoid a double announcement.

    final labelStyle = theme.typography.xs.medium
        .copyWith(color: colors.foreground)
        .merge(s?.labelStyle);
    // Tabular figures keep the digits from jittering as the value changes.
    final valueStyle = theme.typography.xs.medium
        .copyWith(
          color: colors.foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
        )
        .merge(s?.valueStyle);

    return ExcludeSemantics(
      child: Row(
        children: [
          Expanded(
            child: Text(
              label ?? '',
              style: labelStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (showValue)
            Text(
              valueText,
              style: valueStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}
