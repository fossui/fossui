import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/foss_theme.dart';

/// A compact override layer for retheming a [FossThemeData] in one call.
///
/// Every field is optional; an unset field keeps the base theme's value. Colors
/// pass through enumerated (one role per field, no auto-contrast). The scales
/// are single seeds: [radius] derives the radius steps, [spacing] sets the
/// spacing unit, [shadowColor] re-tints every shadow layer, and [fontFamily]
/// applies across every type step. Layer it with [FossThemeData.retheme].
///
/// ```dart
/// final theme = FossThemeData.light.retheme(
///   const FossThemeSpec(
///     primary: Color(0xFF51F0A8),
///     primaryForeground: Color(0xFF000000),
///     ring: Color(0xFF51F0A8),
///     radius: 22,
///     fontFamily: 'Plus Jakarta Sans',
///   ),
/// );
/// ```
///
/// For a light and dark pair, layer one spec over each base and give each its
/// own color values (dark usually wants brighter shades):
///
/// ```dart
/// MaterialApp(
///   theme: FossThemeData.light.retheme(
///     const FossThemeSpec(primary: Color(0xFF16A34A), radius: 22),
///   ).toThemeData(),
///   darkTheme: FossThemeData.dark.retheme(
///     const FossThemeSpec(primary: Color(0xFF51F0A8), radius: 22),
///   ).toThemeData(),
/// );
/// ```
@immutable
class FossThemeSpec {
  /// Creates an override layer; every field defaults to null (keep the base).
  const FossThemeSpec({
    this.background,
    this.foreground,
    this.card,
    this.cardForeground,
    this.popover,
    this.popoverForeground,
    this.primary,
    this.primaryForeground,
    this.secondary,
    this.secondaryForeground,
    this.muted,
    this.mutedForeground,
    this.accent,
    this.accentForeground,
    this.destructive,
    this.destructiveForeground,
    this.destructiveForegroundOn,
    this.info,
    this.infoForeground,
    this.success,
    this.successForeground,
    this.warning,
    this.warningForeground,
    this.border,
    this.input,
    this.ring,
    this.radius,
    this.spacing,
    this.controlHeight,
    this.shadowColor,
    this.fontFamily,
  });

  /// App background override.
  final Color? background;

  /// Default text/icon color override.
  final Color? foreground;

  /// Card surface override.
  final Color? card;

  /// Text/icon color on the card override.
  final Color? cardForeground;

  /// Popover and menu surface override.
  final Color? popover;

  /// Text/icon color on the popover override.
  final Color? popoverForeground;

  /// Primary action color override.
  final Color? primary;

  /// Text/icon color on the primary color override.
  final Color? primaryForeground;

  /// Secondary surface override.
  final Color? secondary;

  /// Text/icon color on the secondary surface override.
  final Color? secondaryForeground;

  /// Muted surface override.
  final Color? muted;

  /// Low-emphasis text color override.
  final Color? mutedForeground;

  /// Accent surface override.
  final Color? accent;

  /// Text/icon color on the accent surface override.
  final Color? accentForeground;

  /// Destructive action color override.
  final Color? destructive;

  /// Text/icon color paired with the destructive color override.
  final Color? destructiveForeground;

  /// Text/icon color on a solid destructive fill override.
  final Color? destructiveForegroundOn;

  /// Informational accent override.
  final Color? info;

  /// Text/icon color paired with the info color override.
  final Color? infoForeground;

  /// Success accent override.
  final Color? success;

  /// Text/icon color paired with the success color override.
  final Color? successForeground;

  /// Warning accent override.
  final Color? warning;

  /// Text/icon color paired with the warning color override.
  final Color? warningForeground;

  /// Default border/divider color override.
  final Color? border;

  /// Form-control border color override.
  final Color? input;

  /// Focus ring color override.
  final Color? ring;

  /// Radius base in logical pixels; derives the full radius scale.
  final double? radius;

  /// Spacing unit in logical pixels; every step is `unit * n`.
  final double? spacing;

  /// Height base in logical pixels (the `md` step) for size-variant controls.
  /// Derives both height scales from one seed: `FossControlHeights` for
  /// buttons, selects, toggles, and pickers, and `FossFieldHeights` for
  /// text-entry fields, which sit one step (2px) shorter.
  final double? controlHeight;

  /// Re-tints every shadow layer, keeping each layer's alpha and geometry.
  final Color? shadowColor;

  /// Font family applied across every type step.
  final String? fontFamily;
}
