/// Read-only view of the session lock — the narrow contract the route guard
/// depends on (Interface-Segregation: it can observe, but cannot lock/unlock).
abstract interface class SessionLock {
  /// Whether the session is currently locked.
  bool get isLocked;

  /// Emits the new value whenever the lock state changes.
  Stream<bool> get changes;
}
