// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'foss_spacing.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$FossSpacingTailorMixin on ThemeExtension<FossSpacing> {
  double get unit;

  @override
  FossSpacing copyWith({double? unit}) {
    return FossSpacing(unit: unit ?? this.unit);
  }

  @override
  FossSpacing lerp(covariant ThemeExtension<FossSpacing>? other, double t) {
    if (other is! FossSpacing) return this as FossSpacing;
    return FossSpacing(
      unit: const DoubleLerpEncoder().lerp(unit, other.unit, t),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FossSpacing &&
            const DeepCollectionEquality().equals(unit, other.unit));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(unit),
    );
  }
}
