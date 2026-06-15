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
///
/// A guard may rewrite the stack (a redirect), so the fold is repeated until
/// the stack **settles** (a pass leaves it unchanged), bounded by
/// [maxResettlements] to stop a redirect loop from spinning forever. Because of
/// this, **guards must be idempotent**: they can run more than once per commit
/// and must not assume a single invocation per navigation.
class GuardedPipeline<R extends RouteNode> {
  /// Creates a pipeline that folds [normalize] and [guards] over each
  /// requested stack.
  GuardedPipeline({
    required this.guards,
    required this.normalize,
    required this.currentStack,
    this.historyLimit = 16,
    this.maxResettlements = 8,
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

  /// Maximum number of times the guard fold is re-run after the first pass
  /// when guards keep rewriting the stack. The fold stops as soon as the stack
  /// settles; if it never does within this many resettlements the pipeline
  /// treats it as a redirect loop and keeps the current stack. The default (8)
  /// is far more than any sane redirect chain (protect → login → restore)
  /// needs.
  final int maxResettlements;

  /// Fires when any guard's [Listenable] changes — wire to `reevaluate`.
  late final Listenable refresh = Listenable.merge(guards);

  final List<List<R>> _history = <List<R>>[];

  /// Runs [requested] through [normalize] and [guards], re-folding until the
  /// stack settles. Returns the settled stack, [currentStack] if a guard
  /// cancels, or — if it fails to settle within [maxResettlements] — the
  /// current stack (a redirect-loop safety stop).
  Future<List<R>> call(List<R> requested) async {
    final context = <String, Object?>{};
    var next = normalize(requested);

    for (var attempt = 0; attempt <= maxResettlements; attempt++) {
      final before = next;
      for (final guard in guards) {
        final result = await guard(_history, next, context);
        if (result.decision == NavDecision.cancel) {
          return currentStack();
        }
        next = normalize(result.stack);
      }
      if (listEquals(before, next)) {
        _remember(next);

        return next;
      }
    }

    // Intentionally not an `assert(false)`: a non-settling stack is the exact
    // runtime condition this cap exists to survive (a misbehaving guard or an
    // oscillating Listenable). Throwing here would defeat the graceful stop, so
    // we log loudly in debug and keep the current stack instead of looping.
    debugPrint(
      'rolter: GuardedPipeline did not settle within $maxResettlements '
      'resettlements — a guard keeps rewriting the requested stack (a redirect '
      'loop). Keeping the current stack. Check guard interactions and the '
      'Listenable refresh wiring.',
    );

    return currentStack();
  }

  void _remember(List<R> stack) {
    _history.add(stack);
    if (_history.length > historyLimit) {
      _history.removeAt(0);
    }
  }
}
