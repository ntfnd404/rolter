import 'package:flutter/widgets.dart';

/// A typed node in the navigation tree.
///
/// A leaf has an empty [children] list (flat navigation); a shell/tab node has a
/// non-empty [children] list (nested navigation). The whole tree projects to a
/// single URL and is reconstructed from it, so flat and nested share one code
/// path: the difference is only whether [children] is empty.
abstract interface class RouteNode {
  /// Stable page identity. Used by [buildPage] and by the delegate to match
  /// the page removed in `onDidRemovePage` back to its node (see
  /// `removeNodeByKey`).
  LocalKey get pageKey;

  /// URL path segment and registry key (e.g. `home`).
  String get name;

  /// Nested stack hosted by this node. Empty for a leaf.
  List<RouteNode> get children;

  /// URL wire format for this node's params. Confined to encode/decode — screens
  /// never see this map.
  Map<String, String> toParams();

  /// Returns a copy of this node with its [children] replaced. A leaf returns
  /// `this`. Required by tree mutation (`mutateNodeAt`).
  RouteNode withChildren(List<RouteNode> children);

  /// Builds the page for this node. A nested node hosts a child navigator over
  /// its [children] (see `NestedNavigatorHost`).
  Page<Object?> buildPage(BuildContext context);
}

/// Marker for nodes kept out of browser history (e.g. a not-found route). The
/// information parser returns `null` from `restoreRouteInformation` for these.
abstract interface class HistoryExcluded {}
