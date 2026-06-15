import 'package:flutter/widgets.dart';

/// A typed node in the navigation tree.
///
/// A leaf has an empty [children] list (flat navigation); a shell/tab node has a
/// non-empty [children] list (nested navigation). The whole tree projects to a
/// single URL and is reconstructed from it, so flat and nested share one code
/// path: the difference is only whether [children] is empty.
///
/// ## Identity contract (load-bearing — read before implementing)
///
/// Implementations **must** provide value `==`/`hashCode`, and [pageKey] **must
/// encode every identity-bearing param**. The engine relies on this in two
/// places at once:
///
/// * Change detection — `RoutesState` commits via `listEquals`, so a
///   navigation that only differs in a field not reflected by `==` is silently
///   a no-op.
/// * Page identity — the root and nested navigators key their pages by
///   [pageKey], which must be **unique across the whole tree** (the same
///   uniqueness the Navigator requires). Two nodes sharing a `pageKey` collapse
///   to one page (and trip a duplicate-key assertion).
///
/// For a **leaf**, the simplest correct implementation derives both from the
/// key: put every param in [pageKey] (e.g. `ValueKey('item:$id')`) and mix in
/// [KeyedRouteEquality] (in `keyed_route_equality.dart`) for matching `==`.
/// A **shell/nested** node whose identity includes its [children] or a param
/// not in [pageKey] (e.g. a tab shell keyed `'tabs'` but distinguished by the
/// active tab) must override `==`/`hashCode` to compare those instead.
abstract interface class RouteNode {
  /// Stable page identity. Used by [buildPage] and by the delegate to match
  /// the page removed in `onDidRemovePage` back to its node (see
  /// `removeNodeByKey`). Must be unique across the whole tree and encode every
  /// identity-bearing param (see the class doc's identity contract).
  LocalKey get pageKey;

  /// URL path segment and registry key (e.g. `home`). Written to and read from
  /// the URL **verbatim** (not percent-encoded), so it must be URL-path-safe —
  /// a simple identifier such as an `enum.name` (no `/`, `.`, `~`, or spaces).
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
  ///
  /// Return any [Page] — the engine never downcasts to a concrete page type, so
  /// flat, nested, dialog, and custom-transition routes share one path. The one
  /// invariant: a custom [Page] whose `createRoute` builds its own [Route] MUST
  /// pass `settings: this` to that route. The delegate matches a removed page
  /// back to its node by [pageKey] read from the route's `settings`; a route
  /// without it never drops its node, leaking it from the tree.
  Page<Object?> buildPage(BuildContext context);
}

/// Marker for nodes kept out of browser history (e.g. a not-found route). The
/// information parser returns `null` from `restoreRouteInformation` for these.
abstract interface class HistoryExcluded {}

/// Opt-in marker for a shell/parent node that restricts which child routes it
/// accepts. A debug assert in `RoutesState` (via `hierarchyViolation`) flags a
/// committed tree where such a node has a child it does not allow — a dev-time
/// guard against mis-wired nesting. Nodes that do not implement this are
/// unrestricted.
abstract interface class StrictHierarchy {
  /// Whether [child] is an allowed direct child of this node.
  bool allowsChild(RouteNode child);
}
