part of 'foss_button.dart';

/// The interactive status a [FossButtonController] holds. The three states are
/// mutually exclusive: [idle] is the normal, enabled state.
enum FossButtonStatus {
  /// Enabled and ready. The normal resting state.
  idle,

  /// Running work: shows a spinner and does not respond to taps.
  loading,

  /// Switched off: the button does not respond to taps.
  disabled,
}

/// Drives a [FossButton] imperatively, so loading and disabled can be toggled
/// without rebuilding the button from new parameters. Pass one to a button's
/// `controller`; you own it and must [dispose] it.
///
/// The button stays interactive only while the status is
/// [FossButtonStatus.idle] (and its `onPressed` is non-null). [run] is the
/// common path: it wraps an async action in a loading state that clears when
/// the action settles.
///
/// ```dart
/// final controller = FossButtonController();
///
/// FossButton(
///   controller: controller,
///   onPressed: () => controller.run(() => save()),
///   child: const Text('Save'),
/// );
/// ```
class FossButtonController extends ChangeNotifier {
  /// Creates a controller, [idle] by default.
  FossButtonController([FossButtonStatus status = FossButtonStatus.idle])
    : _status = status;

  FossButtonStatus _status;

  /// The current status.
  FossButtonStatus get status => _status;

  /// Whether the status is [FossButtonStatus.loading].
  bool get isLoading => _status == FossButtonStatus.loading;

  /// Whether the button is interactive: the status is [FossButtonStatus.idle].
  bool get isEnabled => _status == FossButtonStatus.idle;

  /// Returns to the normal, enabled state.
  void idle() => _set(FossButtonStatus.idle);

  /// Shows a spinner and stops responding to taps.
  void loading() => _set(FossButtonStatus.loading);

  /// Switches the button off without removing its `onPressed`.
  void disable() => _set(FossButtonStatus.disabled);

  /// Runs [action] with the button in [FossButtonStatus.loading], returning to
  /// [FossButtonStatus.idle] when it settles, including on error. A no-op
  /// unless the status is [FossButtonStatus.idle], so overlapping runs and runs
  /// on a disabled button cannot race the status back to idle.
  Future<void> run(Future<void> Function() action) async {
    if (_status != FossButtonStatus.idle) return;
    loading();
    try {
      await action();
    } finally {
      idle();
    }
  }

  void _set(FossButtonStatus status) {
    if (_status == status) return;
    _status = status;
    notifyListeners();
  }
}
