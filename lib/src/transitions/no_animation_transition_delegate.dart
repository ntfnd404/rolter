import 'package:flutter/widgets.dart';

/// A [TransitionDelegate] that commits page additions and removals instantly,
/// with no enter/exit animation.
///
/// Pass it to a [Navigator] — the root `RoutingDelegate` or a
/// `NestedNavigatorHost` via its `transitionDelegate` — to disable transitions
/// for that entire stack (instant tab switches, a web build, an embedded
/// pane) without having to make every page a `NoAnimationPage`. Pageless routes
/// attached to a removed page are removed with it.
class NoAnimationTransitionDelegate<T> extends TransitionDelegate<T> {
  /// Creates a const delegate that performs no transitions.
  const NoAnimationTransitionDelegate();

  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
    locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
    pageRouteToPagelessRoutes,
  }) {
    final results = <RouteTransitionRecord>[];

    for (final entering in newPageRouteHistory) {
      if (entering.isWaitingForEnteringDecision) {
        entering.markForAdd();
      }
      results.add(entering);
    }

    for (final exiting in locationToExitingPageRoute.values) {
      if (exiting.isWaitingForExitingDecision) {
        exiting.markForComplete();
        final pageless =
            pageRouteToPagelessRoutes[exiting] ??
            const <RouteTransitionRecord>[];
        for (final route in pageless) {
          route.markForComplete();
        }
      }
      results.add(exiting);
    }

    return results;
  }
}
