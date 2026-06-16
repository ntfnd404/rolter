import 'dart:async';

import 'package:example/feature/session/application/session_lock.dart';

/// The session lock's source of truth — **ephemeral, in-memory application
/// state** (resets on restart; nothing is persisted, so this is a service, not a
/// repository). The presentation `LockBloc` mutates and observes it; the route
/// guard depends only on its read-only [SessionLock] view. Both observe one
/// source instead of knowing about each other.
final class SessionLockService implements SessionLock {
  bool _locked = false;
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  @override
  bool get isLocked => _locked;

  @override
  Stream<bool> get changes => _controller.stream;

  /// Locks the session.
  void lock() => _set(true);

  /// Unlocks the session.
  void unlock() => _set(false);

  void _set(bool value) {
    if (_locked == value) {
      return;
    }
    _locked = value;
    _controller.add(value);
  }

  /// Closes the broadcast stream. Called by the composition root.
  void dispose() => unawaited(_controller.close());
}
