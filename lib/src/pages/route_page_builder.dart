import 'package:flutter/widgets.dart';

import '../model/route_node.dart';

/// Builds the Flutter [Page] that renders [route].
///
/// A builder is a synchronous, non-owning composition strategy. It may capture
/// application dependencies or read inherited dependencies available above the
/// router, and it may return any [Page] subtype. It can be called more than
/// once, so it must not perform navigation, mutate route state, start I/O, or
/// create app-lifetime resources.
///
/// The returned page must use `route.pageKey` as its [Page.key]. A custom page
/// whose [Page.createRoute] creates its own [Route] must also pass
/// `settings: this` to that route so Flutter can report the removed page back
/// to Rolter.
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:rolter/rolter.dart';
///
/// Page<Object?> buildPage(BuildContext context, PageRouteNode route) {
///   return MaterialPage<Object?>(
///     key: route.pageKey,
///     name: route.name,
///     child: const SizedBox(),
///   );
/// }
///
/// final RouteNodePageBuilder<PageRouteNode> pageBuilder = buildPage;
/// ```
typedef RouteNodePageBuilder<R extends RouteNode> =
    Page<Object?> Function(BuildContext context, R route);

/// Opt-in convenience contract for a route that builds its own Flutter page.
///
/// Prefer a data-only [RouteNode] with an external [RouteNodePageBuilder] when
/// page composition needs explicit application dependencies. This interface
/// keeps route-owned rendering concise for small applications and prototypes.
///
/// ```dart
/// import 'package:flutter/material.dart';
/// import 'package:rolter/rolter.dart';
///
/// final class HomeRoute
///     with KeyedRouteEquality
///     implements PageRouteNode {
///   const HomeRoute();
///
///   @override
///   LocalKey get pageKey => const ValueKey<String>('home');
///
///   @override
///   String get name => 'home';
///
///   @override
///   List<RouteNode> get children => const [];
///
///   @override
///   Map<String, String> toParams() => const {};
///
///   @override
///   RouteNode withChildren(List<RouteNode> children) => this;
///
///   @override
///   Page<Object?> buildPage(BuildContext context) => MaterialPage<Object?>(
///     key: pageKey,
///     name: name,
///     child: const SizedBox(),
///   );
/// }
/// ```
abstract interface class PageRouteNode implements RouteNode {
  /// Builds the page for this route.
  ///
  /// The returned page must use [RouteNode.pageKey] as its [Page.key].
  Page<Object?> buildPage(BuildContext context);
}

/// Adapts route-owned [PageRouteNode.buildPage] to a [RouteNodePageBuilder].
///
/// This is the standard builder for applications that choose the simple
/// route-owned rendering style:
///
/// ```dart
/// import 'package:flutter/widgets.dart';
/// import 'package:rolter/rolter.dart';
///
/// Page<Object?> adaptOwnedPage(
///   BuildContext context,
///   PageRouteNode route,
/// ) => buildPageFromRouteNode<PageRouteNode>(context, route);
/// ```
///
/// The exact [context] and [route] instance are forwarded without wrapping the
/// returned page or catching exceptions.
Page<Object?> buildPageFromRouteNode<R extends PageRouteNode>(
  BuildContext context,
  R route,
) => route.buildPage(context);

/// Invokes [pageBuilder] and enforces Rolter's route/page identity contract.
///
/// This is package-internal implementation shared by root and nested
/// navigators. It is deliberately not exported from `rolter.dart`.
Page<Object?> buildRoutePage<R extends RouteNode>({
  required RouteNodePageBuilder<R> pageBuilder,
  required BuildContext context,
  required R route,
}) {
  final page = pageBuilder(context, route);
  if (page.key != route.pageKey) {
    throw StateError(
      'Rolter page builder returned a Page whose key does not match '
      'RouteNode.pageKey.',
    );
  }

  return page;
}
