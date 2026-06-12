import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:rolter/src/guard/guard_result.dart';
import 'package:rolter/src/model/route_node.dart';

export 'guard_result.dart';
export 'nav_decision.dart';

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
