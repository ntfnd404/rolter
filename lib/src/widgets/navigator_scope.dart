import 'package:flutter/widgets.dart';

import 'package:rolter/src/widgets/scope_access.dart';

/// Inherited facade exposing the app's navigator to the widget tree.
///
/// Must sit ABOVE `MaterialApp.router` (not inside its `builder:`), so the
/// delegate's build context — and therefore every `buildPage` and screen — can
/// read it. [N] is the concrete navigator type (e.g. `AppNavigator`).
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
        'NavigatorScope<$N> not found. Place it ABOVE MaterialApp.router, '
        'not inside its builder: (see spec C5).',
      )
      .navigator;

  /// The navigator exposed to descendants.
  final N navigator;

  @override
  bool updateShouldNotify(NavigatorScope<N> oldWidget) => false;
}
