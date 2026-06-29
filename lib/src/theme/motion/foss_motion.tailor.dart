// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'foss_motion.dart';

// **************************************************************************
// TailorAnnotationsGenerator
// **************************************************************************

mixin _$FossMotionTailorMixin on ThemeExtension<FossMotion> {
  Duration get skeleton;
  Duration get caretBlink;
  Duration get spinner;
  Duration get overlay;
  Duration get toast;

  @override
  FossMotion copyWith({
    Duration? skeleton,
    Duration? caretBlink,
    Duration? spinner,
    Duration? overlay,
    Duration? toast,
  }) {
    return FossMotion(
      skeleton: skeleton ?? this.skeleton,
      caretBlink: caretBlink ?? this.caretBlink,
      spinner: spinner ?? this.spinner,
      overlay: overlay ?? this.overlay,
      toast: toast ?? this.toast,
    );
  }

  @override
  FossMotion lerp(covariant ThemeExtension<FossMotion>? other, double t) {
    if (other is! FossMotion) return this as FossMotion;
    return FossMotion(
      skeleton: t < 0.5 ? skeleton : other.skeleton,
      caretBlink: t < 0.5 ? caretBlink : other.caretBlink,
      spinner: t < 0.5 ? spinner : other.spinner,
      overlay: t < 0.5 ? overlay : other.overlay,
      toast: t < 0.5 ? toast : other.toast,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FossMotion &&
            const DeepCollectionEquality().equals(skeleton, other.skeleton) &&
            const DeepCollectionEquality().equals(
              caretBlink,
              other.caretBlink,
            ) &&
            const DeepCollectionEquality().equals(spinner, other.spinner) &&
            const DeepCollectionEquality().equals(overlay, other.overlay) &&
            const DeepCollectionEquality().equals(toast, other.toast));
  }

  @override
  int get hashCode {
    return Object.hash(
      runtimeType.hashCode,
      const DeepCollectionEquality().hash(skeleton),
      const DeepCollectionEquality().hash(caretBlink),
      const DeepCollectionEquality().hash(spinner),
      const DeepCollectionEquality().hash(overlay),
      const DeepCollectionEquality().hash(toast),
    );
  }
}
