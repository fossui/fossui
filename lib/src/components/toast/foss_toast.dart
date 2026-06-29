import 'package:flutter/widgets.dart';

part 'foss_toast_style.dart';

/// The kind of a [FossToast]: drives the leading glyph, its tint, and whether
/// the toast auto-dismisses.
enum FossToastType {
  /// A plain notification with no status glyph.
  normal,

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

/// One transient notification. Enqueue it with `showFossToast` or a
/// `FossToastController`; the surface stays on the `popover` role for every
/// [type], which tints only the leading glyph.
///
/// ```dart
/// showFossToast(
///   context,
///   const FossToast(type: FossToastType.success, title: Text('Saved')),
/// );
/// ```
@immutable
class FossToast {
  /// Creates a toast message.
  const FossToast({
    this.title,
    this.description,
    this.type = FossToastType.normal,
    this.icon,
    this.action,
    this.duration,
    this.style,
  });

  /// The title line.
  final Widget? title;

  /// The description below the title.
  final Widget? description;

  /// The kind of toast. Defaults to [FossToastType.normal].
  final FossToastType type;

  /// Overrides the default leading glyph (or the loading spinner). Null hides
  /// the leading slot for [FossToastType.normal].
  final Widget? icon;

  /// An optional trailing action.
  final Widget? action;

  /// Overrides the auto-dismiss delay. Ignored for [FossToastType.loading],
  /// which persists.
  final Duration? duration;

  /// Per-instance visual overrides.
  final FossToastStyle? style;
}
