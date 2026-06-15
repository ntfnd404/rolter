import 'package:flutter/foundation.dart';

import 'package:rolter/src/model/route_node.dart';
import 'package:rolter/src/state/nav_observer.dart';

/// Browser-like back/forward over committed navigation states.
///
/// Wire it as a [NavObserver] on `RoutesState` (it records each committed
/// stack) and give it a [restore] callback that re-commits a stack — typically
/// `RoutesState.setRoot`. A **new** navigation drops any forward entries (just
/// like a browser); [back]/[forward] move a cursor and replay an entry without
/// recording it. It is a [ChangeNotifier], so back/forward controls can rebuild
/// their enabled state from [canGoBack]/[canGoForward].
///
/// On the web the platform already provides back/forward through the URL; this
/// is for in-app controls and non-web targets.
class NavigationHistory<R extends RouteNode> extends ChangeNotifier
    implements NavObserver<R> {
  /// Creates a history that replays entries through [restore], keeping at most
  /// [limit] of them.
  NavigationHistory(this.restore, {this.limit = 50})
    : assert(limit > 0, 'limit must be positive');

  /// Re-commits a remembered stack (e.g. `RoutesState.setRoot`).
  final void Function(List<R> stack) restore;

  /// Maximum remembered entries; the oldest are dropped beyond this.
  final int limit;

  final List<List<R>> _entries = <List<R>>[];
  int _cursor = -1;

  // Stacks a back()/forward() asked to restore, awaiting their commit. Matched
  // by value (not a sticky flag) so a no-op or guard-rewritten replay can't
  // wedge recording, and rapid back/forward can't miscount.
  final List<List<R>> _pendingReplays = <List<R>>[];

  /// Whether there is an older entry to go [back] to.
  bool get canGoBack => _cursor > 0;

  /// Whether there is a newer entry to go [forward] to.
  bool get canGoForward => _cursor >= 0 && _cursor < _entries.length - 1;

  @override
  void onTransition(NavTransition<R> transition) {
    if (_pendingReplays.isNotEmpty &&
        listEquals(transition.next, _pendingReplays.first)) {
      // This commit is a back()/forward() replay landing as asked — the cursor
      // already points at it, so don't record.
      _pendingReplays.removeAt(0);

      return;
    }
    // Any other commit is a genuine navigation: it supersedes pending replays
    // and invalidates the forward tail (browser semantics).
    _pendingReplays.clear();
    if (_cursor < _entries.length - 1) {
      _entries.removeRange(_cursor + 1, _entries.length);
    }
    _entries.add(transition.next);
    if (_entries.length > limit) {
      _entries.removeAt(0);
    }
    _cursor = _entries.length - 1;
    notifyListeners();
  }

  /// Replays the previous entry, if any.
  void back() {
    if (!canGoBack) {
      return;
    }
    _cursor--;
    _replay(_entries[_cursor]);
  }

  /// Replays the next entry, if any.
  void forward() {
    if (!canGoForward) {
      return;
    }
    _cursor++;
    _replay(_entries[_cursor]);
  }

  void _replay(List<R> stack) {
    _pendingReplays.add(stack);
    restore(stack);
    notifyListeners();
  }
}
