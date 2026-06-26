// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'foss_typography.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$FossTypographyTailorMixin on ThemeExtension<FossTypography> {
  TextStyle get xs;
  TextStyle get sm;
  TextStyle get base;
  TextStyle get lg;
  TextStyle get xl;
  TextStyle get xl2;

  @override
  FossTypography copyWith({
    TextStyle? xs,
    TextStyle? sm,
    TextStyle? base,
    TextStyle? lg,
    TextStyle? xl,
    TextStyle? xl2,
  }) {
    return FossTypography(
      xs: xs ?? this.xs,
      sm: sm ?? this.sm,
      base: base ?? this.base,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xl2: xl2 ?? this.xl2,
    );
  }

  @override
  FossTypography lerp(
    covariant ThemeExtension<FossTypography>? other,
    double t,
  ) {
    if (other is! FossTypography) return this as FossTypography;
    return FossTypography(
      xs: TextStyle.lerp(xs, other.xs, t)!,
      sm: TextStyle.lerp(sm, other.sm, t)!,
      base: TextStyle.lerp(base, other.base, t)!,
      lg: TextStyle.lerp(lg, other.lg, t)!,
      xl: TextStyle.lerp(xl, other.xl, t)!,
      xl2: TextStyle.lerp(xl2, other.xl2, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FossTypography &&
            const DeepCollectionEquality().equals(xs, other.xs) &&
            const DeepCollectionEquality().equals(sm, other.sm) &&
            const DeepCollectionEquality().equals(base, other.base) &&
            const DeepCollectionEquality().equals(lg, other.lg) &&
            const DeepCollectionEquality().equals(xl, other.xl) &&
            const DeepCollectionEquality().equals(xl2, other.xl2));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(xs),
      const DeepCollectionEquality().hash(sm),
      const DeepCollectionEquality().hash(base),
      const DeepCollectionEquality().hash(lg),
      const DeepCollectionEquality().hash(xl),
      const DeepCollectionEquality().hash(xl2),
    );
  }
}
