import 'package:flutter/widgets.dart';

/// Reads a scope ([InheritedWidget]) from the tree, throwing a clear error when
/// it is missing instead of returning `null`. Removes the repeated
/// find-or-throw boilerplate from every `Scope.of`.
extension ScopeAccess on BuildContext {
  /// Reads the nearest [W] **without subscribing** to its rebuilds, or throws.
  /// Use for scopes whose value never changes (e.g. a navigator facade).
  W readScopeOrThrow<W extends InheritedWidget>([String? hint]) {
    final scope = getInheritedWidgetOfExactType<W>();
    if (scope == null) {
      throw FlutterError(hint ?? '$W not found in the widget tree.');
    }
    return scope;
  }

  /// Reads the nearest [W] **and subscribes** to its rebuilds, or throws.
  W watchScopeOrThrow<W extends InheritedWidget>([String? hint]) {
    final scope = dependOnInheritedWidgetOfExactType<W>();
    if (scope == null) {
      throw FlutterError(hint ?? '$W not found in the widget tree.');
    }
    return scope;
  }
}
