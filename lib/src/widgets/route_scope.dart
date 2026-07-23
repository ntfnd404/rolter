import 'package:flutter/widgets.dart';

import 'scope_access.dart';

/// A per-route dependency scope.
///
/// Creates a value (a BLoC, controller, or small dependency graph) in
/// `initState` and disposes it in `dispose`. Placed inside a route's
/// `buildPage`, it lives exactly as long as that page's element: when the page
/// is removed (correct `onDidRemovePage`), Flutter unmounts the subtree and
/// `dispose` runs. Screens that need no scope stay bare; both coexist.
class RouteScope<T> extends StatefulWidget {
  /// Creates a scope that builds its value with [create] and tears it down
  /// with [dispose].
  const RouteScope({
    required this.create,
    required this.dispose,
    required this.child,
    super.key,
  });

  /// Reads the nearest [RouteScope] value of type [T].
  static T of<T>(BuildContext context) => context
      .watchScopeOrThrow<_RouteScopeProvider<T>>(
        'RouteScope<$T> not found in the widget tree.',
      )
      .value;

  /// Builds the scoped value, called once in `initState`.
  final T Function() create;

  /// Tears down the scoped value, called once in `dispose`.
  final void Function(T value) dispose;

  /// The subtree that can read the scoped value via [RouteScope.of].
  final Widget child;

  @override
  State<RouteScope<T>> createState() => _RouteScopeState<T>();
}

class _RouteScopeState<T> extends State<RouteScope<T>> {
  late final T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.create();
  }

  @override
  void dispose() {
    widget.dispose(_value);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _RouteScopeProvider<T>(value: _value, child: widget.child);
}

class _RouteScopeProvider<T> extends InheritedWidget {
  const _RouteScopeProvider({required this.value, required super.child});

  final T value;

  @override
  bool updateShouldNotify(_RouteScopeProvider<T> oldWidget) =>
      value != oldWidget.value;
}
