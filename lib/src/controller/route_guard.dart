import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:rolter/src/model/route_node.dart';

/// A composable navigation guard (v3): rewrites or cancels a requested stack.
///
/// The delegate folds a requested stack through an ordered list of guards
/// inside the apply pipeline, sharing a [context] map, and reruns them when
/// any guard's [Listenable] fires. No concrete guards ship in v1; this fixes
/// the contract (typed over `List<R>`, keeps `history`, and has an explicit
/// cancel — unlike a thinner interface).
abstract interface class RouteGuard<R extends RouteNode> implements Listenable {
  /// Inspects [requested] (with the prior [history] and shared [context]) and
  /// returns a result: proceed with a possibly rewritten stack, or cancel.
  FutureOr<GuardResult<R>> call(
    List<List<R>> history,
    List<R> requested,
    Map<String, Object?> context,
  );
}

/// Outcome of a [RouteGuard]: continue with [stack], or cancel navigation.
class GuardResult<R extends RouteNode> {
  /// Proceeds with [stack] as the (possibly rewritten) requested stack.
  const GuardResult.proceed(this.stack) : decision = NavDecision.proceed;

  /// Cancels navigation, leaving the current stack unchanged.
  const GuardResult.cancel()
    : stack = const <Never>[],
      decision = NavDecision.cancel;

  /// The stack to proceed with, or empty when [decision] is
  /// [NavDecision.cancel].
  final List<R> stack;

  /// Whether to proceed with [stack] or cancel navigation.
  final NavDecision decision;
}

/// Whether a guard lets navigation proceed or cancels it.
enum NavDecision {
  /// Proceed with the (possibly rewritten) requested stack.
  proceed,

  /// Cancel navigation and keep the current stack.
  cancel,
}
