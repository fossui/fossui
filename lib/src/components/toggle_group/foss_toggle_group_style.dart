part of 'foss_toggle_group.dart';

/// Visual overrides for a [FossToggleGroup]. Every field is optional; a null
/// field falls back to the theme-resolved default. Pass one via `style:` to
/// tweak a single group without changing the theme. The item colors, radius,
/// and type resolve through each [FossToggle]; this carries only the group
/// knobs.
///
/// ```dart
/// FossToggleGroup.single(
///   value: view,
///   onChanged: (v) => setState(() => view = v),
///   style: const FossToggleGroupStyle(gap: 6),
///   children: const [
///     FossToggleGroupItem(value: 'list', child: Text('List')),
///     FossToggleGroupItem(value: 'grid', child: Text('Grid')),
///   ],
/// );
/// ```
@immutable
class FossToggleGroupStyle {
  /// Creates a set of group overrides. All fields default to null (inherit).
  const FossToggleGroupStyle({this.gap, this.connectedBorderColor});

  /// Gap between items in the standard variant, in logical pixels.
  final double? gap;

  /// Color of the shared border and seams in the outline variant.
  final Color? connectedBorderColor;

  /// Returns a copy with every non-null field of [other] laid over this one.
  ///
  /// ```dart
  /// const base = FossToggleGroupStyle(gap: 2);
  /// const override = FossToggleGroupStyle(gap: 6);
  /// base.merge(override); // gap becomes 6
  /// ```
  FossToggleGroupStyle merge(FossToggleGroupStyle? other) {
    if (other == null) return this;
    return FossToggleGroupStyle(
      gap: other.gap ?? gap,
      connectedBorderColor: other.connectedBorderColor ?? connectedBorderColor,
    );
  }
}
