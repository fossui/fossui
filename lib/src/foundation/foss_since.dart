/// Records the fossui version a public API was introduced in.
///
/// Applied to public API added after the `0.1.0` baseline, so readers and
/// tooling can see when a symbol became available. Everything present in
/// `0.1.0` is left unannotated: the absence of a [FossSince] means the API has
/// existed since the first stable release.
///
/// ```dart
/// @FossSince('0.2.0')
/// class FossDatePicker extends StatelessWidget {
///   // ...
/// }
/// ```
class FossSince {
  /// Creates an annotation marking the [version] an API was introduced in.
  const FossSince(this.version);

  /// The fossui version the annotated API first shipped in, as written in the
  /// changelog (for example `0.2.0`).
  final String version;
}
