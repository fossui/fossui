import 'package:flutter/widgets.dart';
import 'package:fossui/src/theme/theme.dart';

part 'foss_avatar_style.dart';

/// The size axis of a [FossAvatar]. Selects the square box edge and the
/// fallback text step; [md] (32) is the default.
enum FossAvatarSize {
  /// 24 logical pixels.
  xs._(24),

  /// 28 logical pixels.
  sm._(28),

  /// 32 logical pixels (default).
  md._(32),

  /// 36 logical pixels.
  lg._(36),

  /// 40 logical pixels.
  xl._(40),

  /// 48 logical pixels.
  xl2._(48),
  ;

  const FossAvatarSize._(this._box);

  final double _box;

  // The fallback type step climbs with the box: the three smallest share xs,
  // then sm, base, lg.
  TextStyle _fallbackType(FossTypography t) => switch (this) {
    FossAvatarSize.xs || FossAvatarSize.sm || FossAvatarSize.md => t.xs,
    FossAvatarSize.lg => t.sm,
    FossAvatarSize.xl => t.base,
    FossAvatarSize.xl2 => t.lg,
  };
}

/// {@category Layout}
/// {@template foss.avatar.preview}
/// <img src="https://fossui.org/components/avatar/overview/light.png"
///   alt="FossAvatar, light theme" width="480"
///   style="max-width:100%;height:auto" />
/// <img src="https://fossui.org/components/avatar/overview/dark.png"
///   alt="FossAvatar, dark theme" width="480"
///   style="max-width:100%;height:auto" />
///
/// See the [avatar documentation ↗](https://fossui.org/docs/components/avatar) or
/// try it live in the
/// [playground ↗](https://play.fossui.org/#/?path=components/avatar/fossavatar/playground).
/// {@endtemplate}
///
/// A user's stand-in: a fixed-size circle that shows a profile [image] and
/// falls back to a [fallback] glyph (usually initials) while the image loads,
/// when it is absent, or when it fails to load. Static and non-interactive.
///
/// [image] is an [ImageProvider]; null renders the [fallback] alone. [fallback]
/// is any widget and shows beneath the image until the first frame arrives, so
/// a dead URL degrades to initials instead of crashing. [size] drives the box
/// and the fallback text step. Colors, type, and shape come from
/// `context.fossTheme`; pass a [FossAvatarStyle] for a one-off override.
///
/// {@macro foss.customize}
///
/// ```dart
/// FossAvatar(
///   image: NetworkImage('https://example.com/v.png'),
///   fallback: const Text('VL'),
///   semanticsLabel: 'Violet Light',
/// );
/// ```
class FossAvatar extends StatelessWidget {
  /// {@macro foss.avatar.preview}
  ///
  /// Creates an avatar. With no [image] the [fallback] fills the circle; with
  /// neither, a bare `background` circle renders.
  const FossAvatar({
    this.image,
    this.fallback,
    this.size = FossAvatarSize.md,
    this.semanticsLabel,
    this.style,
    super.key,
  });

  /// The profile image. Null renders the [fallback] alone.
  final ImageProvider? image;

  /// Shown beneath the image until it loads, and whenever it is absent or
  /// fails. Usually [Text] initials; any widget is accepted.
  final Widget? fallback;

  /// Selects the box edge and the fallback text step. Defaults to
  /// [FossAvatarSize.md].
  final FossAvatarSize size;

  /// Accessibility name for the avatar. When null the avatar is decorative.
  final String? semanticsLabel;

  /// Per-instance visual overrides.
  final FossAvatarStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = context.fossTheme;

    final avatar = SizedBox.square(
      dimension: size._box,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style?.backgroundColor ?? theme.colors.background,
          shape: BoxShape.circle,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (fallback case final fb?) _fallbackLayer(theme, fb),
            if (image case final img?) _imageLayer(img),
          ],
        ),
      ),
    );

    // A labelled avatar exposes one image node; unlabelled it is decorative
    // and contributes no semantics, so the monogram never announces.
    final label = semanticsLabel;
    if (label == null) return ExcludeSemantics(child: avatar);
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(child: avatar),
    );
  }

  // The fallback fills a muted circle with the centered glyph, its type stepped
  // to the box and overridable through [style].
  Widget _fallbackLayer(FossThemeData theme, Widget fb) => DecoratedBox(
    decoration: BoxDecoration(
      color: style?.fallbackColor ?? theme.colors.muted,
      shape: BoxShape.circle,
    ),
    child: Center(
      child: DefaultTextStyle.merge(
        textAlign: TextAlign.center,
        style: size
            ._fallbackType(theme.typography)
            .medium
            .copyWith(color: theme.colors.mutedForeground)
            .merge(style?.fallbackTextStyle),
        child: fb,
      ),
    ),
  );

  // The image is the only square layer, so it carries the sole clip; a
  // fallback-only avatar pays for none. The fallback shows through until the
  // first frame and whenever the image is absent or fails.
  Widget _imageLayer(ImageProvider img) => ClipOval(
    child: Image(
      image: img,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, _) =>
          frame == null ? const SizedBox.shrink() : child,
      errorBuilder: (context, _, _) => const SizedBox.shrink(),
    ),
  );
}
