import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/theme/theme.dart';

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
  xl2._(48)
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
/// ```dart
/// FossAvatar(
///   image: NetworkImage('https://example.com/v.png'),
///   fallback: const Text('VL'),
///   semanticsLabel: 'Vitalik Larsen',
/// );
/// ```
class FossAvatar extends StatelessWidget {
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
    final colors = theme.colors;
    final s = style;
    final img = image;
    final fb = fallback;

    final layers = <Widget>[
      if (fb != null)
        DecoratedBox(
          decoration: BoxDecoration(
            color: s?.fallbackColor ?? colors.muted,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: DefaultTextStyle.merge(
              textAlign: TextAlign.center,
              style: size
                  ._fallbackType(theme.typography)
                  .medium
                  .copyWith(color: colors.mutedForeground)
                  .merge(s?.fallbackTextStyle),
              child: fb,
            ),
          ),
        ),
      if (img != null)
        Image(
          image: img,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          // Keep the fallback visible until the first frame; an absent or dead
          // image leaves the layer empty so the fallback shows through.
          frameBuilder: (context, child, frame, _) =>
              frame == null ? const SizedBox.shrink() : child,
          errorBuilder: (context, _, _) => const SizedBox.shrink(),
        ),
    ];

    return Semantics(
      image: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size._box,
          child: ClipOval(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: s?.backgroundColor ?? colors.background,
                shape: BoxShape.circle,
              ),
              child: Stack(fit: StackFit.expand, children: layers),
            ),
          ),
        ),
      ),
    );
  }
}
