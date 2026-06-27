part of 'foss_button.dart';

/// Visual overrides for a [FossButton]. Every field is optional; a null field
/// falls back to the value the theme resolves for the button's variant and
/// size. Pass one to a single button via `style:` to tweak a one-off, without
/// changing the theme for every other button.
///
/// Stateful fields ([backgroundColor], [foregroundColor]) are
/// [WidgetStateProperty]s resolved against the button's interactive state set
/// (hovered, pressed, focused, disabled); the rest are plain values.
///
/// A solid fill and pill corners:
///
/// ```dart
/// FossButton(
///   onPressed: save,
///   style: const FossButtonStyle(
///     borderRadius: 999,
///     backgroundColor: WidgetStatePropertyAll(Color(0xFF6D28D9)),
///   ),
///   child: const Text('Save'),
/// );
/// ```
///
/// A fill that darkens on hover and press, via
/// [WidgetStateProperty.resolveWith]:
///
/// ```dart
/// FossButton(
///   onPressed: save,
///   style: FossButtonStyle(
///     backgroundColor: WidgetStateProperty.resolveWith((states) {
///       if (states.contains(WidgetState.pressed)) {
///         return const Color(0xFF4C1D95);
///       }
///       if (states.contains(WidgetState.hovered)) {
///         return const Color(0xFF5B21B6);
///       }
///       return const Color(0xFF6D28D9);
///     }),
///   ),
///   child: const Text('Save'),
/// );
/// ```
///
/// A compact, borderless, shadowless override:
///
/// ```dart
/// FossButton(
///   onPressed: save,
///   style: const FossButtonStyle(
///     side: BorderSide.none,
///     shadow: [],
///     padding: EdgeInsets.symmetric(horizontal: 8),
///     minHeight: 28,
///     gap: 4,
///   ),
///   child: const Text('Save'),
/// );
/// ```
@immutable
class FossButtonStyle {
  /// Creates a set of button overrides. All fields default to null (inherit).
  const FossButtonStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.side,
    this.borderRadius,
    this.padding,
    this.minHeight,
    this.textStyle,
    this.shadow,
    this.iconSize,
    this.gap,
    this.disabledOpacity,
  });

  /// Fill color per interactive state.
  final WidgetStateProperty<Color>? backgroundColor;

  /// Label and icon color per interactive state.
  final WidgetStateProperty<Color>? foregroundColor;

  /// Border drawn around the button, or [BorderSide.none] for none.
  final BorderSide? side;

  /// Corner radius in logical pixels.
  final double? borderRadius;

  /// Inner padding around the content.
  final EdgeInsetsGeometry? padding;

  /// Minimum content height in logical pixels; grows with text scale.
  final double? minHeight;

  /// Label text style; its color is taken from [foregroundColor].
  final TextStyle? textStyle;

  /// Drop shadow layers; empty for none.
  final List<BoxShadow>? shadow;

  /// Leading and trailing icon size in logical pixels.
  final double? iconSize;

  /// Gap between icon and label in logical pixels.
  final double? gap;

  /// Opacity applied to the whole button when disabled.
  final double? disabledOpacity;

  /// Returns a copy with every non-null field of [other] laid over this one.
  /// Used to layer a per-instance override on the theme-resolved defaults.
  ///
  /// ```dart
  /// const base = FossButtonStyle(borderRadius: 8, minHeight: 36);
  /// const override = FossButtonStyle(minHeight: 28);
  /// base.merge(override); // borderRadius 8 kept, minHeight becomes 28
  /// ```
  FossButtonStyle merge(FossButtonStyle? other) {
    if (other == null) return this;
    return FossButtonStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      side: other.side ?? side,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      minHeight: other.minHeight ?? minHeight,
      textStyle: other.textStyle ?? textStyle,
      shadow: other.shadow ?? shadow,
      iconSize: other.iconSize ?? iconSize,
      gap: other.gap ?? gap,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
    );
  }
}
