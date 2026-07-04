import 'package:flutter/material.dart' show ThemeExtension;
import 'package:flutter/widgets.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'foss_colors.tailor.dart';
part '_foss_palette.dart';

/// Semantic color roles, one field per role. [light] and [dark] are baked
/// constant sets; every blend and translucent overlay is resolved to a fixed
/// sRGB color, so no color math runs at runtime.
///
/// Components read these through `context.fossTheme`, never the private
/// primitive palette. Override roles per app with [copyWith].
///
/// ```dart
/// const c = FossColors.light;
/// final action = c.primary;
/// final brand = c.copyWith(primary: const Color(0xFF6D28D9));
/// ```
@TailorMixin(themeGetter: ThemeGetter.none)
class FossColors extends ThemeExtension<FossColors>
    with _$FossColorsTailorMixin {
  /// Creates a semantic color set. Prefer [light] or [dark] unless retheming.
  const FossColors({
    required this.background,
    required this.foreground,
    required this.card,
    required this.cardForeground,
    required this.popover,
    required this.popoverForeground,
    required this.primary,
    required this.primaryForeground,
    required this.secondary,
    required this.secondaryForeground,
    required this.muted,
    required this.mutedForeground,
    required this.accent,
    required this.accentForeground,
    required this.destructive,
    required this.destructiveForeground,
    required this.destructiveForegroundOn,
    required this.info,
    required this.infoForeground,
    required this.success,
    required this.successForeground,
    required this.warning,
    required this.warningForeground,
    required this.border,
    required this.input,
    required this.ring,
  });

  /// App background.
  @override
  final Color background;

  /// Default text/icon color on [background].
  @override
  final Color foreground;

  /// Card surface.
  @override
  final Color card;

  /// Text/icon color on [card].
  @override
  final Color cardForeground;

  /// Popover and menu surface.
  @override
  final Color popover;

  /// Text/icon color on [popover].
  @override
  final Color popoverForeground;

  /// Primary action color (solid buttons, active states).
  @override
  final Color primary;

  /// Text/icon color on [primary].
  @override
  final Color primaryForeground;

  /// Secondary surface (subtle fills).
  @override
  final Color secondary;

  /// Text/icon color on [secondary].
  @override
  final Color secondaryForeground;

  /// Muted surface (disabled, low-emphasis fills).
  @override
  final Color muted;

  /// Low-emphasis text color.
  @override
  final Color mutedForeground;

  /// Accent surface (hover fills, highlights).
  @override
  final Color accent;

  /// Text/icon color on [accent].
  @override
  final Color accentForeground;

  /// Destructive action color (delete, errors).
  @override
  final Color destructive;

  /// Text/icon color paired with [destructive].
  @override
  final Color destructiveForeground;

  /// Text/icon color on a solid [destructive] fill.
  @override
  final Color destructiveForegroundOn;

  /// Informational accent.
  @override
  final Color info;

  /// Text/icon color paired with [info].
  @override
  final Color infoForeground;

  /// Success accent.
  @override
  final Color success;

  /// Text/icon color paired with [success].
  @override
  final Color successForeground;

  /// Warning accent.
  @override
  final Color warning;

  /// Text/icon color paired with [warning].
  @override
  final Color warningForeground;

  /// Default border/divider color.
  @override
  final Color border;

  /// Form-control border color.
  @override
  final Color input;

  /// Focus ring color.
  @override
  final Color ring;

  /// Whether this is a dark set, judged by [background] luminance. Drives the
  /// dark-only surface lifts and rim highlights components paint at rest.
  bool get isDark => background.computeLuminance() < 0.5;

  /// The default light color set.
  static const light = FossColors(
    background: Color(0xFFFFFFFF),
    foreground: _FossPalette.neutral800,
    card: Color(0xFFFFFFFF),
    cardForeground: _FossPalette.neutral800,
    popover: Color(0xFFFFFFFF),
    popoverForeground: _FossPalette.neutral800,
    primary: _FossPalette.neutral800,
    primaryForeground: _FossPalette.neutral50,
    secondary: Color(0x0A000000), // black at 4% alpha
    secondaryForeground: _FossPalette.neutral800,
    muted: Color(0x0A000000), // black at 4% alpha
    mutedForeground: Color(0xFF686868), // neutral-500, 90% over black
    accent: Color(0x0A000000), // black at 4% alpha
    accentForeground: _FossPalette.neutral800,
    destructive: _FossPalette.red500,
    destructiveForeground: _FossPalette.red700,
    destructiveForegroundOn: Color(0xFFFFFFFF),
    info: _FossPalette.blue500,
    infoForeground: _FossPalette.blue700,
    success: _FossPalette.emerald500,
    successForeground: _FossPalette.emerald700,
    warning: _FossPalette.amber500,
    warningForeground: _FossPalette.amber700,
    border: Color(0x14000000), // black at 8% alpha
    input: Color(0x1A000000), // black at 10% alpha
    ring: _FossPalette.neutral400,
  );

  /// The default dark color set.
  static const dark = FossColors(
    background: Color(0xFF141414), // darkest neutral, 96% over white
    foreground: _FossPalette.neutral100,
    card: Color(0xFF191919), // background, 98% over white
    cardForeground: _FossPalette.neutral100,
    popover: Color(0xFF1D1D1D), // background, 96% over white
    popoverForeground: _FossPalette.neutral100,
    primary: _FossPalette.neutral100,
    primaryForeground: _FossPalette.neutral800,
    secondary: Color(0x0AFFFFFF), // white at 4% alpha
    secondaryForeground: _FossPalette.neutral100,
    muted: Color(0x0AFFFFFF), // white at 4% alpha
    mutedForeground: Color(0xFF818181), // neutral-500, 90% over white
    accent: Color(0x0AFFFFFF), // white at 4% alpha
    accentForeground: _FossPalette.neutral100,
    destructive: Color(0xFFFB414A), // red-500, 90% over white
    destructiveForeground: _FossPalette.red400,
    destructiveForegroundOn: Color(0xFFFFFFFF),
    info: _FossPalette.blue500,
    infoForeground: _FossPalette.blue400,
    success: _FossPalette.emerald500,
    successForeground: _FossPalette.emerald400,
    warning: _FossPalette.amber500,
    warningForeground: _FossPalette.amber400,
    border: Color(0x0FFFFFFF), // white at 6% alpha
    input: Color(0x14FFFFFF), // white at 8% alpha
    ring: _FossPalette.neutral500,
  );
}
