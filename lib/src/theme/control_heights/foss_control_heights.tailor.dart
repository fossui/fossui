// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'foss_control_heights.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$FossControlHeightsTailorMixin on ThemeExtension<FossControlHeights> {
  double get sm;
  double get md;
  double get lg;

  @override
  FossControlHeights copyWith({double? sm, double? md, double? lg}) {
    return FossControlHeights(
      sm: sm ?? this.sm,
      md: md ?? this.md,
      lg: lg ?? this.lg,
    );
  }

  @override
  FossControlHeights lerp(
    covariant ThemeExtension<FossControlHeights>? other,
    double t,
  ) {
    if (other is! FossControlHeights) return this as FossControlHeights;
    return FossControlHeights(
      sm: const DoubleLerpEncoder().lerp(sm, other.sm, t),
      md: const DoubleLerpEncoder().lerp(md, other.md, t),
      lg: const DoubleLerpEncoder().lerp(lg, other.lg, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FossControlHeights &&
            const DeepCollectionEquality().equals(sm, other.sm) &&
            const DeepCollectionEquality().equals(md, other.md) &&
            const DeepCollectionEquality().equals(lg, other.lg));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(sm),
      const DeepCollectionEquality().hash(md),
      const DeepCollectionEquality().hash(lg),
    );
  }
}
