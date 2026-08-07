import 'package:flutter/widgets.dart';

import 'scope_access.dart';

/// Inherited facade exposing the app's navigator to the widget tree.
///
/// Must be an ancestor of the `Router`: place it above `MaterialApp.router`, or
/// wrap the `child` supplied to `MaterialApp.router.builder`. Both placements
/// are visible to the delegate's `RouteNodePageBuilder` and page subtrees. [N]
/// is the concrete navigator type (e.g. `AppNavigator`). Keep the [navigator]
/// instance stable for this scope's lifetime.
class NavigatorScope<N extends Object> extends InheritedWidget {
  /// Creates a scope exposing [navigator] above [child].
  const NavigatorScope({
    required this.navigator,
    required super.child,
    super.key,
  });

  /// Reads the nearest [NavigatorScope] of type [N] without subscribing.
  static N of<N extends Object>(BuildContext context) => context
      .readScopeOrThrow<NavigatorScope<N>>(
        'NavigatorScope<$N> not found. Place it above MaterialApp.router or '
        'around the router child supplied to MaterialApp.router.builder.',
      )
      .navigator;

  /// The navigator exposed to descendants.
  final N navigator;

  @override
  bool updateShouldNotify(NavigatorScope<N> oldWidget) => false;
}
