import 'package:flutter/widgets.dart';
import 'package:fossui/src/foundation/foss_since.dart';
import 'package:fossui/src/theme/colors/foss_colors.dart';
import 'package:fossui/src/theme/foss_theme.dart';
import 'package:fossui/src/theme/typography/foss_typography.dart';

/// The type step of a [FossText], one entry per [FossTypography] size. [base]
/// (16 logical pixels) is the default.
enum FossTextSize {
  /// 12 px: captions and fine print.
  xs,

  /// 14 px: the most common body size.
  sm,

  /// 16 px: body (the default).
  base,

  /// 18 px: subheadings.
  lg,

  /// 20 px: headings.
  xl,

  /// 24 px: large headings.
  xl2
  ;

  TextStyle _style(FossTypography t) => switch (this) {
    FossTextSize.xs => t.xs,
    FossTextSize.sm => t.sm,
    FossTextSize.base => t.base,
    FossTextSize.lg => t.lg,
    FossTextSize.xl => t.xl,
    FossTextSize.xl2 => t.xl2,
  };
}

/// The weight of a [FossText]. [regular] (400) is the default.
enum FossTextWeight {
  /// Regular weight (400): body text.
  regular(FontWeight.w400),

  /// Medium weight (500): labels.
  medium(FontWeight.w500),

  /// Semibold weight (600): headings.
  semibold(FontWeight.w600),

  /// Bold weight (700): emphasis.
  bold(FontWeight.w700)
  ;

  const FossTextWeight(this.value);

  /// The underlying [FontWeight].
  final FontWeight value;
}

/// A semantic color role for a [FossText], resolved from `FossColors`. Leave
/// the color null to use the `foreground` role.
enum FossTextColor {
  /// The default text color.
  foreground,

  /// Dimmed text for secondary content.
  mutedForeground,

  /// The brand accent color.
  primary,

  /// The destructive (danger) color.
  destructive
  ;

  Color _resolve(FossColors c) => switch (this) {
    FossTextColor.foreground => c.foreground,
    FossTextColor.mutedForeground => c.mutedForeground,
    FossTextColor.primary => c.primary,
    FossTextColor.destructive => c.destructive,
  };
}

/// {@category Typography}
/// {@template foss.text.preview}
/// <img src="https://fossui.org/components/text/overview/light.png"
///   alt="FossText, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/text/overview/dark.png"
///   alt="FossText, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [text documentation ↗](https://fossui.org/docs/components/text) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/text/fosstext/playground).
/// {@endtemplate}
///
/// On-brand text in one line. [FossText] renders a string in a [FossTypography]
/// step at one of four weights, resolving the type scale and the bundled font
/// from `context.fossTheme` so the text stays on theme without reaching into
/// the tokens.
///
/// Pick the step and weight with [size] and [weight], or use a named
/// constructor ([FossText.body], [FossText.title], [FossText.heading], and the
/// like) for a common role. [color] takes a semantic [FossTextColor] role; when
/// null the text uses the `foreground` role. [style] merges over the resolved
/// style, winning on any field it sets. Set [header] on a true document heading
/// so assistive technology can navigate to it. The remaining parameters pass
/// straight through to the underlying `Text`.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossText.title('Account settings');
/// FossText(
///   'The quick brown fox.',
///   size: FossTextSize.sm,
///   color: FossTextColor.mutedForeground,
/// );
/// ```
@FossSince('0.1.1')
class FossText extends StatelessWidget {
  /// {@macro foss.text.preview}
  ///
  /// Creates on-brand text. [data] is the string; [size], [weight], and [color]
  /// pick the style, the rest pass through to `Text`.
  const FossText(
    this.data, {
    this.size = FossTextSize.base,
    this.weight = FossTextWeight.regular,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.style,
    this.header = false,
    super.key,
  });

  /// Caption text: [FossTextSize.xs], [FossTextWeight.regular].
  const FossText.caption(
    this.data, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.style,
    this.header = false,
    super.key,
  }) : size = FossTextSize.xs,
       weight = FossTextWeight.regular;

  /// Body text: [FossTextSize.sm], [FossTextWeight.regular].
  const FossText.body(
    this.data, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.style,
    this.header = false,
    super.key,
  }) : size = FossTextSize.sm,
       weight = FossTextWeight.regular;

  /// Label text: [FossTextSize.sm], [FossTextWeight.medium].
  const FossText.label(
    this.data, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.style,
    this.header = false,
    super.key,
  }) : size = FossTextSize.sm,
       weight = FossTextWeight.medium;

  /// Title text: [FossTextSize.lg], [FossTextWeight.semibold].
  const FossText.title(
    this.data, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.style,
    this.header = false,
    super.key,
  }) : size = FossTextSize.lg,
       weight = FossTextWeight.semibold;

  /// Heading text: [FossTextSize.xl], [FossTextWeight.semibold].
  const FossText.heading(
    this.data, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.style,
    this.header = false,
    super.key,
  }) : size = FossTextSize.xl,
       weight = FossTextWeight.semibold;

  /// Display text: [FossTextSize.xl2], [FossTextWeight.bold].
  const FossText.display(
    this.data, {
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
    this.style,
    this.header = false,
    super.key,
  }) : size = FossTextSize.xl2,
       weight = FossTextWeight.bold;

  /// The string to render.
  final String data;

  /// The type step. Defaults to [FossTextSize.base].
  final FossTextSize size;

  /// The weight. Defaults to [FossTextWeight.regular].
  final FossTextWeight weight;

  /// The color role. Defaults to the `foreground` role when null.
  final FossTextColor? color;

  /// How the text aligns horizontally.
  final TextAlign? textAlign;

  /// The maximum number of lines before the text clips or ellipsizes.
  final int? maxLines;

  /// How visual overflow is handled.
  final TextOverflow? overflow;

  /// Whether the text should wrap at soft line breaks.
  final bool? softWrap;

  /// Accessibility name that replaces the visible string when set.
  final String? semanticsLabel;

  /// A per-instance style merged over the resolved style, winning on any field
  /// it sets.
  final TextStyle? style;

  /// Whether to mark the text as a heading for assistive technology, so screen
  /// readers can navigate to it by heading. Defaults to false; set it on true
  /// document headings, not on every visually large label.
  final bool header;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;
    final resolved = size
        ._style(theme.typography)
        .copyWith(
          fontWeight: weight.value,
          color: color?._resolve(theme.colors) ?? theme.colors.foreground,
        )
        .merge(style);

    final text = Text(
      data,
      style: resolved,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
      semanticsLabel: semanticsLabel,
    );

    if (!header) return text;
    return Semantics(header: true, child: text);
  }
}
