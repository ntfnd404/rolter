import '../model/route_node.dart';

/// Remembers a navigation target to restore later — the "return after
/// login/unlock" store.
///
/// Deep links need no separate subsystem in rolter: the guard pipeline already
/// runs on `setNewRoutePath`, so a guard can inspect and redirect the requested
/// stack. What it usually also needs is somewhere to stash the *intended*
/// location while it diverts the user (e.g. to a lock/login screen) and replay
/// it once they are allowed through. That is exactly this store — share one
/// with a guard instead of hand-rolling an `intended` field.
class PendingLocation<R extends RouteNode> {
  /// Creates an empty pending-location store.
  PendingLocation();

  List<R>? _stack;

  /// Whether a target is currently remembered.
  bool get hasPending => _stack != null;

  /// The remembered target without clearing it, or `null` if none.
  List<R>? get peek => _stack == null ? null : List<R>.unmodifiable(_stack!);

  /// Remembers [stack] as the target to return to (defensively copied).
  void remember(List<R> stack) => _stack = List<R>.of(stack);

  /// Returns the remembered target and clears it, or `null` if none.
  List<R>? take() {
    final stack = _stack;
    _stack = null;

    return stack == null ? null : List<R>.unmodifiable(stack);
  }

  /// Forgets any remembered target.
  void clear() => _stack = null;
}
