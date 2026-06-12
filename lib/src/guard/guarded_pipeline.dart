import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:rolter/src/guard/route_guard.dart';
import 'package:rolter/src/model/route_node.dart';

/// Builds an apply-pipeline from an ordered list of [RouteGuard]s.
///
/// Use [call] as the `RoutesState` pipeline: it normalises the requested stack,
/// folds it through each guard (sharing a `context` map), and — on a guard
/// cancel — keeps the current stack. Subscribe [refresh] to
/// `RoutesState.reevaluate` so a guard's `Listenable` change reruns the guards
/// against the current location (e.g. auth state changed → re-protect/restore).
class GuardedPipeline<R extends RouteNode> {
  /// Creates a pipeline that folds [normalize] and [guards] over each
  /// requested stack.
  GuardedPipeline({
    required this.guards,
    required this.normalize,
    required this.currentStack,
    this.historyLimit = 16,
  });

  /// Ordered list of guards applied to every requested stack.
  final List<RouteGuard<R>> guards;

  /// Normalises a requested stack before and after each guard runs.
  final List<R> Function(List<R> requested) normalize;

  /// Returns the currently committed stack, used when a guard cancels.
  final List<R> Function() currentStack;

  /// Size of the sliding `history` window passed to guards. Bounded so the
  /// buffer never grows unboundedly over the app's lifetime (every committed
  /// stack is remembered). The default — 16 — is a few screens of look-back,
  /// enough for breadcrumb or loop-detection guards; raise it only if a guard
  /// needs to see deeper into the past.
  final int historyLimit;

  /// Fires when any guard's [Listenable] changes — wire to `reevaluate`.
  late final Listenable refresh = Listenable.merge(guards);

  final List<List<R>> _history = <List<R>>[];

  /// Runs [requested] through [normalize] and [guards], returning the
  /// resulting stack, or [currentStack] if a guard cancels.
  Future<List<R>> call(List<R> requested) async {
    var next = normalize(requested);
    final context = <String, Object?>{};
    for (final guard in guards) {
      final result = await guard(_history, next, context);
      if (result.decision == NavDecision.cancel) {
        return currentStack();
      }
      next = normalize(result.stack);
    }
    _remember(next);

    return next;
  }

  void _remember(List<R> stack) {
    _history.add(stack);
    if (_history.length > historyLimit) {
      _history.removeAt(0);
    }
  }
}
