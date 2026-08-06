# Migrating from Rolter 0.1.x to 0.2.0

Rolter 0.2.0 is an approved clean breaking release. There is no intermediate
0.1.1 deprecation release and no temporary compatibility hierarchy.

The URL wire format is unchanged. Existing encoded route names, parameters,
tree structure, guards, results, restoration, history, and codecs retain their
0.1.x behavior. The breaking change is in Dart page-composition APIs.

## Public API diff

Removed from `RouteNode`:

```dart
Page<Object?> buildPage(BuildContext context);
```

Added:

```dart
typedef RouteNodePageBuilder<R extends RouteNode> = Page<Object?> Function(
  BuildContext context,
  R route,
);

abstract interface class PageRouteNode implements RouteNode {
  Page<Object?> buildPage(BuildContext context);
}

Page<Object?> buildPageFromRouteNode<R extends PageRouteNode>(
  BuildContext context,
  R route,
);
```

Changed constructors:

```dart
RoutingDelegate<R>(
  state,
  pageBuilder: builder, // now required
);

NestedNavigatorHost<R>(
  service: service,
  path: path,
  pageBuilder: builder, // now required
);
```

The public builder is named `RouteNodePageBuilder`, rather than
`RoutePageBuilder`, because current Flutter SDKs already export an unrelated
`RoutePageBuilder`; the route-qualified name avoids an import collision with
`package:flutter/material.dart`.

## Option A: preserve route-owned composition

If 0.1.x route classes should keep their current `buildPage` methods, change
the base route to implement `PageRouteNode` and pass the adapter:

```diff
-abstract class AppRoute implements RouteNode {
+abstract class AppRoute implements PageRouteNode {
 }

-final delegate = RoutingDelegate<AppRoute>(state);
+final delegate = RoutingDelegate<AppRoute>(
+  state,
+  pageBuilder: buildPageFromRouteNode<AppRoute>,
+);
```

No individual `buildPage` body needs to change, except that every returned page
must explicitly use `key: route.pageKey` (or `key: pageKey` inside the route).

## Option B: move to external composition

For a data-only route hierarchy:

1. Remove `buildPage` from every route.
2. Create one `RouteNodePageBuilder<AppRoute>` or an app-level typed catalog.
3. Move each former method body to its corresponding typed page definition.
4. Pass the complete builder to `RoutingDelegate` and every
   `NestedNavigatorHost`.
5. Capture dependencies in the composition root and inject narrow contracts
   into pages/screens.

Before:

```dart
final class MailboxRoute extends AppRoute {
  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage<Object?>(
    key: pageKey,
    child: MailboxScreen(repository: AppScope.of(context).mailRepository),
  );
}
```

After:

```dart
final class MailboxRoute extends AppRoute {
  // Navigation data only.
}

Page<Object?> buildMailboxPage(
  BuildContext context,
  MailboxRoute route,
  MailRepository repository,
) => MaterialPage<Object?>(
  key: route.pageKey,
  name: route.name,
  child: MailboxScreen(repository: repository),
);
```

## Incremental hybrid migration

An application may temporarily keep some routes route-owned while moving other
routes to external composition:

```dart
Page<Object?> buildDuringMigration(BuildContext context, AppRoute route) {
  if (route is PageRouteNode) {
    return buildPageFromRouteNode<PageRouteNode>(context, route);
  }
  return buildExternalPage(context, route);
}

final delegate = RoutingDelegate<AppRoute>(
  state,
  pageBuilder: buildDuringMigration,
);
```

This is a migration bridge, not a third core API. Keep each route on exactly one
composition path and converge on one primary application style so ownership and
dependency flow remain predictable.

## Required page-key invariant

Root and nested rendering now share one validation path. A builder result is
accepted only when:

```dart
page.key == route.pageKey
```

A null page key is invalid, even if a custom page would otherwise render. This
check runs in debug, profile, and release modes. Its error deliberately omits
route values, URLs, parameters, and key values. Exceptions thrown by the
application builder are not caught or wrapped, so their original type and
stack are preserved.

## Nested child typing

`RouteNode.children` remains `List<RouteNode>` in 0.2.0. A
`NestedNavigatorHost<R>` validates every child before passing it to the typed
builder and throws `StateError` for an incompatible type. Do not introduce a
recursive `RouteNode<R>` solely for this migration.

## Scope placement

- A scope above `MaterialApp.router` is visible to the delegate builder and the
  Page subtree.
- A scope returned from `MaterialApp.router.builder` wraps the Router child, so
  it is also visible to the delegate builder and the Page subtree.
- A scope created inside a Page is visible only below that Page boundary.

Use an outer scope when it owns the router itself. Use
`MaterialApp.router.builder` when a tenant/session dependency graph should wrap
and rebuild the complete Router subtree. Prefer constructor injection from the
external catalog when dependencies are known at the application composition
root. Keep disposable page resources in a provider or `RouteScope`, never in
the page builder.

An application-defined `AppScope.of(context)` is still supported; `AppScope`
was never part of Rolter itself. The package example removed its old app-wide
scope only because constructor injection left it unused. If retaining inherited
lookup, prefer a capability-specific feature or repository scope.

## Custom pages

`TransparentPage`, `NoAnimationPage`, `TransitionPage`, and custom transition
delegates are unchanged. Continue to set `key: route.pageKey`. If a custom
`Page.createRoute` creates its own `Route`, continue to pass `settings: this`.

## Migration checklist

- [ ] Every route either implements data-only `RouteNode`, or inherits a base
      that implements `PageRouteNode`.
- [ ] Every `RoutingDelegate` has `pageBuilder:`.
- [ ] Every `NestedNavigatorHost` has `pageBuilder:`.
- [ ] Every returned page has `key: route.pageKey`.
- [ ] Nested shells receive and forward the complete builder.
- [ ] Typed catalogs dispatch by route type, not wire name.
- [ ] Duplicate and missing page definitions fail safely.
- [ ] Builder dependencies and page-lifetime ownership are tested.
- [ ] `dart analyze`, tests, documentation, and consumer builds pass before
      release.
