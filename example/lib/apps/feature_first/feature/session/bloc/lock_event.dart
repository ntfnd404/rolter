/// Events for [LockBloc].
sealed class LockEvent {
  const LockEvent();
}

/// Lock the session — protected routes get redirected to the unlock screen.
final class LockRequested extends LockEvent {
  const LockRequested();
}

/// Unlock the session — reruns the guards and restores the intended route.
final class UnlockRequested extends LockEvent {
  const UnlockRequested();
}

/// Internal: the domain lock state changed (from `WatchSessionLock.changes`), so
/// the bloc's state mirrors the domain truth even if it changed elsewhere.
final class LockStateChanged extends LockEvent {
  const LockStateChanged(this.isLocked);

  final bool isLocked;
}
