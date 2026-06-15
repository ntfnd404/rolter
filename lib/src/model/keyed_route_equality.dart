import 'package:rolter/src/model/route_node.dart';

/// Value `==`/`hashCode` for a [RouteNode] derived entirely from its
/// `(runtimeType, pageKey)`.
///
/// Mix this into a **leaf** route that already encodes every identity-bearing
/// param into [RouteNode.pageKey] (e.g. `ValueKey('item:$id')`), so it
/// satisfies the engine's identity contract without hand-writing `==`:
///
/// ```dart
/// final class ItemRoute with KeyedRouteEquality {
///   const ItemRoute(this.id);
///   final int id;
///   @override
///   LocalKey get pageKey => ValueKey('item:$id');
///   // name / toParams / buildPage ...
/// }
/// ```
///
/// Do **not** use it for a shell/nested node whose identity depends on its
/// [RouteNode.children] or on a param that is not part of [RouteNode.pageKey]
/// (e.g. a tab shell keyed `'tabs'`): such a node must override `==`/`hashCode`
/// to compare that extra state, or distinct states collapse to one.
mixin KeyedRouteEquality implements RouteNode {
  @override
  int get hashCode => Object.hash(runtimeType, pageKey);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteNode &&
          other.runtimeType == runtimeType &&
          other.pageKey == pageKey;
}
