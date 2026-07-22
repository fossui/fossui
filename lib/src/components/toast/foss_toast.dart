import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/alert/foss_alert.dart';
import 'package:fossui/src/components/toast/foss_toaster.dart';

part 'foss_toast_style.dart';

/// The kind of a [FossToast]: drives the leading glyph, its tint, and whether
/// the toast auto-dismisses.
enum FossToastVariant {
  /// A plain notification with no status glyph.
  neutral,

  /// A pending operation: shows a spinner and persists until updated.
  loading,

  /// Informational.
  info,

  /// A successful outcome.
  success,

  /// A caution.
  warning,

  /// An error or failure.
  error,
}

/// {@category Overlays}
/// {@template foss.toast.preview}
/// <img src="https://fossui.org/components/toast/overview/light.png"
///   alt="FossToast, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/toast/overview/dark.png"
///   alt="FossToast, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [toast documentation ↗](https://fossui.org/docs/components/toast) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/components/#/?path=components/toast/fosstoaster/playground).
/// {@endtemplate}
///
/// One transient notification. Enqueue it with `showFossToast` or a
/// `FossToastController`; the surface stays on the `popover` role for every
/// [variant], which tints only the leading glyph.
///
/// {@macro foss.customize}
///
/// See also [FossToaster], the host that displays toasts, and [FossAlert] for a
/// persistent inline message.
///
/// ```dart
/// showFossToast(
///   context,
///   const FossToast(variant: FossToastVariant.success, title: Text('Saved')),
/// );
/// ```
@immutable
class FossToast {
  /// {@macro foss.toast.preview}
  ///
  /// Creates a toast message.
  const FossToast({
    this.title,
    this.description,
    this.variant = FossToastVariant.neutral,
    this.icon,
    this.action,
    this.duration,
    this.style,
  });

  /// The title line.
  final Widget? title;

  /// The description below the title.
  final Widget? description;

  /// The kind of toast. Defaults to [FossToastVariant.neutral].
  final FossToastVariant variant;

  /// Overrides the default leading glyph (or the loading spinner). Null hides
  /// the leading slot for [FossToastVariant.neutral].
  final Widget? icon;

  /// An optional trailing action.
  final Widget? action;

  /// Overrides the auto-dismiss delay. Ignored for [FossToastVariant.loading],
  /// which persists.
  final Duration? duration;

  /// Per-instance visual overrides.
  final FossToastStyle? style;
}
