import 'package:flutter/foundation.dart';

import '../model/route_node.dart';

/// A committed navigation change, handed to a [NavObserver] after the tree has
/// updated.
///
/// [entered] and [left] are the `pageKey` set-difference between [previous] and
/// [next] across the whole tree (root stack + all nested children), computed
/// from `collectPageKeys`.
@immutable
class NavTransition<R extends RouteNode> {
  /// Creates a transition snapshot.
  const NavTransition({
    required this.previous,
    required this.next,
    required this.entered,
    required this.left,
  });

  /// The committed root stack before this change (read-only).
  final List<R> previous;

  /// The committed root stack after this change (read-only).
  final List<R> next;

  /// pageKeys present in [next] but not in [previous] (nodes that joined).
  final Set<LocalKey> entered;

  /// pageKeys present in [previous] but not in [next] (nodes that left).
  final Set<LocalKey> left;
}

/// Read-only navigation telemetry. `RoutesState` calls [onTransition] after
/// each committed change (after `notifyListeners`), with the previous/next
/// stacks and the entered/left page keys.
///
/// **Must not mutate navigation** (no `push`/`pop`/etc.): it runs inside the
/// commit step, so treat it as telemetry only — logging, analytics,
/// breadcrumbs, a back-stack mirror. Use a guard, not an observer, to navigate.
abstract interface class NavObserver<R extends RouteNode> {
  /// Called once per committed change. See the class doc for the no-mutation
  /// rule.
  void onTransition(NavTransition<R> transition);
}
