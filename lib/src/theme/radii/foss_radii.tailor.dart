// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'foss_radii.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$FossRadiiTailorMixin on ThemeExtension<FossRadii> {
  double get sm;
  double get md;
  double get lg;
  double get xl;
  double get xl2;

  @override
  FossRadii copyWith({
    double? sm,
    double? md,
    double? lg,
    double? xl,
    double? xl2,
  }) {
    return FossRadii(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
      xl: xl ?? this.xl,
      xl2: xl2 ?? this.xl2,
    );
  }

  @override
  FossRadii lerp(covariant ThemeExtension<FossRadii>? other, double t) {
    if (other is! FossRadii) return this as FossRadii;
    return FossRadii(
      sm: const DoubleLerpEncoder().lerp(sm, other.sm, t),
      md: const DoubleLerpEncoder().lerp(md, other.md, t),
      lg: const DoubleLerpEncoder().lerp(lg, other.lg, t),
      xl: const DoubleLerpEncoder().lerp(xl, other.xl, t),
      xl2: const DoubleLerpEncoder().lerp(xl2, other.xl2, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FossRadii &&
            const DeepCollectionEquality().equals(sm, other.sm) &&
            const DeepCollectionEquality().equals(md, other.md) &&
            const DeepCollectionEquality().equals(lg, other.lg) &&
            const DeepCollectionEquality().equals(xl, other.xl) &&
            const DeepCollectionEquality().equals(xl2, other.xl2));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(sm),
      const DeepCollectionEquality().hash(md),
      const DeepCollectionEquality().hash(lg),
      const DeepCollectionEquality().hash(xl),
      const DeepCollectionEquality().hash(xl2),
    );
  }
}
