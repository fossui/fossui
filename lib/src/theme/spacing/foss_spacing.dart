import 'package:flutter/material.dart' show ThemeExtension;
import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/theme/lerp_encoders.dart';
import 'package:theme_tailor_annotation/theme_tailor_annotation.dart';

part 'foss_spacing.tailor.dart';

/// Spacing scale built from one [unit] (4 px). Call the instance to scale the
/// unit ([call]) or build an inset ([all]); every step is `unit * n`.
///
/// ```dart
/// const s = FossSpacing.standard;
/// final gap = s(2); // 8 px
/// final pad = s.all(4); // EdgeInsets.all(16)
/// ```
@TailorMixin(themeGetter: ThemeGetter.none, encoders: [DoubleLerpEncoder()])
class FossSpacing extends ThemeExtension<FossSpacing>
    with _$FossSpacingTailorMixin {
  /// Creates a spacing scale. Prefer [standard] unless retheming.
  const FossSpacing({this.unit = 4});

  /// Base spacing unit in logical pixels.
  @override
  final double unit;

  /// `unit * n`: `spacing(2)` is 8 px, `spacing(1.5)` is 6 px.
  double call(double n) => unit * n;

  /// `EdgeInsets.all(unit * n)`.
  EdgeInsets all(double n) => EdgeInsets.all(unit * n);

  /// The default spacing scale.
  static const standard = FossSpacing();
}
