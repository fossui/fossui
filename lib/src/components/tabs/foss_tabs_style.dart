part of 'foss_tabs.dart';

/// Visual overrides for a single [FossTabs]. Every field is optional; a null
/// field falls back to the value the theme resolves for the chosen variant.
/// Pass one via `style:` to tweak a one-off without changing the theme for
/// every other tab set.
///
/// The focus ring and the tab and bar radii stay token-driven; retheme
/// [FossColors] or [FossRadii] to change them globally.
///
/// A segmented set with a green active pill:
///
/// ```dart
/// FossTabs<String>(
///   tabs: tabs,
///   style: const FossTabsStyle(indicatorColor: Color(0xFF10B981)),
/// );
/// ```
@immutable
class FossTabsStyle {
  /// Creates a set of tab overrides. All fields default to null (inherit).
  const FossTabsStyle({
    this.barColor,
    this.indicatorColor,
    this.indicatorShadow,
    this.hoverColor,
    this.activeForeground,
    this.inactiveForeground,
    this.labelStyle,
  });

  /// Fill of the segmented strip bar. Unused by the underline variant.
  final Color? barColor;

  /// Fill of the active indicator: the segmented pill, or the underline bar.
  final Color? indicatorColor;

  /// Shadow layers under the segmented pill; empty for none.
  final List<BoxShadow>? indicatorShadow;

  /// Background tint of a hovered underline tab.
  final Color? hoverColor;

  /// Label color of the active tab.
  final Color? activeForeground;

  /// Label color of inactive tabs.
  final Color? inactiveForeground;

  /// Text style of every tab label. Color is applied per state.
  final TextStyle? labelStyle;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossTabsStyle(barColor: Color(0xFFEEEEEE));
  /// const override = FossTabsStyle(indicatorColor: Color(0xFF10B981));
  /// base.merge(override); // barColor kept, indicatorColor added
  /// ```
  FossTabsStyle merge(FossTabsStyle? other) {
    if (other == null) return this;
    return FossTabsStyle(
      barColor: other.barColor ?? barColor,
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorShadow: other.indicatorShadow ?? indicatorShadow,
      hoverColor: other.hoverColor ?? hoverColor,
      activeForeground: other.activeForeground ?? activeForeground,
      inactiveForeground: other.inactiveForeground ?? inactiveForeground,
      labelStyle: other.labelStyle ?? labelStyle,
    );
  }
}
