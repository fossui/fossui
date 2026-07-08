import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:fossui/src/components/toast/foss_toast.dart';

/// A live toast in a [FossToastController]'s queue.
class FossToastEntry {
  /// Creates an entry. Built by the controller, not directly.
  FossToastEntry({required this.id, required this.toast});

  /// Stable identity within the controller, returned by `show`.
  final int id;

  /// The current message; replaced by `update`.
  FossToast toast;

  // Auto-dismiss machinery, owned by the controller. The timer only runs while
  // the entry is visible and not pressed; [_remaining] carries the time left so
  // a pause resumes where it stopped, and [_total] is null when the toast
  // persists (loading, or a non-positive duration).
  Duration? _total;
  Duration _remaining = Duration.zero;
  Timer? _timer;
  bool _pressed = false;
  final Stopwatch _watch = Stopwatch();
}

/// Owns the queue of live toasts and their auto-dismiss timers. Shared by a
/// `FossToaster` and read with `FossToastScope.of`. Notifies on every change.
///
/// A toast's dismiss timer runs only while the toast is one of the
/// [maxVisible] on screen and is not being pressed, so a queued toast cannot
/// expire before it is ever seen, and a press holds it open.
class FossToastController extends ChangeNotifier {
  /// The default auto-dismiss delay.
  static const Duration defaultDuration = Duration(milliseconds: 5000);

  /// The most toasts shown at once; older ones wait.
  static const int maxVisible = 3;

  final List<FossToastEntry> _entries = <FossToastEntry>[];
  int _nextId = 0;

  /// The live toasts, oldest first.
  List<FossToastEntry> get entries => List.unmodifiable(_entries);

  /// Enqueues [toast] and returns its id. Schedules auto-dismiss once the toast
  /// is visible, unless it is [FossToastType.loading] or its duration is zero.
  int show(FossToast toast) {
    final total = _totalFor(toast);
    final entry = FossToastEntry(id: _nextId++, toast: toast)
      .._total = total
      .._remaining = total ?? Duration.zero;
    _entries.add(entry);
    _reconcile();
    notifyListeners();
    return entry.id;
  }

  /// Replaces the message of [id] in place and restarts its timer. The
  /// loading-to-status flip. No-op if [id] is gone.
  void update(int id, FossToast toast) {
    final entry = _find(id);
    if (entry == null) return;
    _pause(entry);
    final total = _totalFor(toast);
    entry
      ..toast = toast
      .._total = total
      .._remaining = total ?? Duration.zero;
    _reconcile();
    notifyListeners();
  }

  /// Removes [id]. No-op if it is already gone.
  void dismiss(int id) {
    final entry = _find(id);
    if (entry == null) return;
    _pause(entry);
    _entries.remove(entry);
    _reconcile();
    notifyListeners();
  }

  /// Removes every toast.
  void clear() {
    _entries
      ..forEach(_pause)
      ..clear();
    notifyListeners();
  }

  /// Holds [id] open while it is pressed, resuming its countdown on release.
  /// No-op if [id] is gone or persists.
  void setPressed(int id, {required bool pressed}) {
    final entry = _find(id);
    if (entry == null || entry._pressed == pressed) return;
    entry._pressed = pressed;
    _reconcile();
  }

  // Runs a timer for every visible, unpressed, auto-dismiss entry, and pauses
  // the rest. Called after every change; idempotent.
  void _reconcile() {
    final firstVisible = _entries.length - maxVisible;
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      final visible = i >= firstVisible;
      final shouldRun = entry._total != null && visible && !entry._pressed;
      if (shouldRun && entry._timer == null) {
        _resume(entry);
      } else if (!shouldRun && entry._timer != null) {
        _pause(entry);
      }
    }
  }

  void _resume(FossToastEntry entry) {
    entry._watch
      ..reset()
      ..start();
    entry._timer = Timer(entry._remaining, () => dismiss(entry.id));
  }

  void _pause(FossToastEntry entry) {
    if (entry._timer == null) return;
    entry._timer?.cancel();
    entry._timer = null;
    entry._watch.stop();
    entry._remaining -= entry._watch.elapsed;
    if (entry._remaining < Duration.zero) entry._remaining = Duration.zero;
  }

  Duration? _totalFor(FossToast toast) {
    if (toast.type == FossToastType.loading) return null;
    final duration = toast.duration ?? defaultDuration;
    return duration <= Duration.zero ? null : duration;
  }

  FossToastEntry? _find(int id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  void dispose() {
    _entries.forEach(_pause);
    super.dispose();
  }
}
