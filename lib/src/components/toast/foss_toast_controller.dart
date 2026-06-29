import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:foss_ui/src/components/toast/foss_toast.dart';

/// A live toast in a [FossToastController]'s queue.
class FossToastEntry {
  /// Creates an entry. Built by the controller, not directly.
  FossToastEntry({required this.id, required this.toast});

  /// Stable identity within the controller, returned by `show`.
  final int id;

  /// The current message; replaced by `update`.
  FossToast toast;

  /// The auto-dismiss timer, or null when the toast persists.
  Timer? timer;
}

/// Owns the queue of live toasts and their auto-dismiss timers. Shared by a
/// `FossToaster` and read with `FossToastScope.of`. Notifies on every change.
class FossToastController extends ChangeNotifier {
  /// The default auto-dismiss delay.
  static const Duration defaultDuration = Duration(milliseconds: 5000);

  /// The most toasts shown at once; older ones wait.
  static const int maxVisible = 3;

  final List<FossToastEntry> _entries = <FossToastEntry>[];
  int _nextId = 0;

  /// The live toasts, oldest first.
  List<FossToastEntry> get entries => List.unmodifiable(_entries);

  /// Enqueues [toast] and returns its id. Schedules auto-dismiss unless the
  /// toast is [FossToastType.loading] or its duration is zero.
  int show(FossToast toast) {
    final entry = FossToastEntry(id: _nextId++, toast: toast);
    _entries.add(entry);
    _scheduleDismiss(entry);
    notifyListeners();
    return entry.id;
  }

  /// Replaces the message of [id] in place and restarts its timer. The
  /// loading-to-status flip. No-op if [id] is gone.
  void update(int id, FossToast toast) {
    final entry = _find(id);
    if (entry == null) return;
    entry
      ..toast = toast
      ..timer?.cancel();
    _scheduleDismiss(entry);
    notifyListeners();
  }

  /// Removes [id]. No-op if it is already gone.
  void dismiss(int id) {
    final entry = _find(id);
    if (entry == null) return;
    entry.timer?.cancel();
    _entries.remove(entry);
    notifyListeners();
  }

  /// Removes every toast.
  void clear() {
    for (final entry in _entries) {
      entry.timer?.cancel();
    }
    _entries.clear();
    notifyListeners();
  }

  void _scheduleDismiss(FossToastEntry entry) {
    if (entry.toast.type == FossToastType.loading) return;
    final duration = entry.toast.duration ?? defaultDuration;
    if (duration <= Duration.zero) return;
    entry.timer = Timer(duration, () => dismiss(entry.id));
  }

  FossToastEntry? _find(int id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.timer?.cancel();
    }
    super.dispose();
  }
}
