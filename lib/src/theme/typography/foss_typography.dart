import 'package:flutter/material.dart' show ThemeExtension;
import 'package:flutter/widgets.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'foss_typography.tailor.dart';

// The bundled font resolves under a package-qualified family name; the bare
// name would only match a font the consumer declared, so the default scale
// renders with no setup on their side.
const _family = 'packages/fossui/Geist';

/// Text styles per size step. Each carries family, size, line height, and
/// letter spacing; set weight with the [FossTextStyleWeight] getters (`.medium`
/// for labels and buttons, `.semibold` for headings, `.bold` for emphasis).
///
/// ```dart
/// const t = FossTypography.standard;
/// Text('Label', style: t.sm.medium);
/// ```
@TailorMixin(themeGetter: ThemeGetter.none)
class FossTypography extends ThemeExtension<FossTypography>
    with _$FossTypographyTailorMixin {
  /// Creates a type scale. Prefer [standard] unless retheming.
  const FossTypography({
    required this.xs,
    required this.sm,
    required this.base,
    required this.lg,
    required this.xl,
    required this.xl2,
  });

  /// 12 px: captions and fine print.
  @override
  final TextStyle xs;

  /// 14 px: the most common body size.
  @override
  final TextStyle sm;

  /// 16 px: body.
  @override
  final TextStyle base;

  /// 18 px: subheadings.
  @override
  final TextStyle lg;

  /// 20 px: headings.
  @override
  final TextStyle xl;

  /// 24 px: large headings.
  @override
  final TextStyle xl2;

  /// The default type scale.
  static const standard = FossTypography(
    xs: TextStyle(
      fontFamily: _family,
      fontSize: 12,
      height: 14 / 12,
      letterSpacing: 0.12,
    ),
    sm: TextStyle(fontFamily: _family, fontSize: 14, height: 20 / 14),
    base: TextStyle(fontFamily: _family, fontSize: 16, height: 24 / 16),
    lg: TextStyle(
      fontFamily: _family,
      fontSize: 18,
      height: 28 / 18,
      letterSpacing: -0.18,
    ),
    xl: TextStyle(
      fontFamily: _family,
      fontSize: 20,
      height: 28 / 20,
      letterSpacing: -0.20,
    ),
    xl2: TextStyle(
      fontFamily: _family,
      fontSize: 24,
      height: 32 / 24,
      letterSpacing: -0.36,
    ),
  );
}

/// Weight conveniences on a [TextStyle], for use on the [FossTypography] scale.
///
/// ```dart
/// final t = context.fossTheme.typography;
/// Text('Save', style: t.sm.medium);
/// Text('Title', style: t.xl.semibold);
/// ```
extension FossTextStyleWeight on TextStyle {
  /// Medium weight (500): labels and buttons.
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);

  /// Semibold weight (600): headings.
  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);

  /// Bold weight (700): emphasis.
  TextStyle get bold => copyWith(fontWeight: FontWeight.w700);
}
