import 'dart:async';

import 'package:flutter/foundation.dart';

import '../model/route_node.dart';
import 'guard_result.dart';

export 'guard_result.dart';
export 'nav_decision.dart';

/// A composable navigation guard: rewrites or cancels a requested stack.
///
/// The pipeline folds a requested stack through an ordered list of guards,
/// sharing a [context] map, and reruns them when any guard's [Listenable]
/// fires. The contract is typed over `List<R>`, carries the prior [history],
/// and has an explicit cancel.
abstract interface class RouteGuard<R extends RouteNode> implements Listenable {
  /// Inspects [requested] (with the prior [history] and shared [context]) and
  /// returns a result: proceed with a possibly rewritten stack, or cancel.
  FutureOr<GuardResult<R>> call(
    List<List<R>> history,
    List<R> requested,
    Map<String, Object?> context,
  );
}
