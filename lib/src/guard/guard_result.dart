import 'package:rolter/src/guard/nav_decision.dart';
import 'package:rolter/src/model/route_node.dart';

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
