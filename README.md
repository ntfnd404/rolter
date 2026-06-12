# Rolter

A hand-rolled, declarative Navigator 2.0 routing engine for Flutter with a
typed, URL-serializable route tree and built-in nested navigation.

## Features

- Declarative, tree-based route configuration
- Typed routes with URL serialization/deserialization
- Built-in support for nested navigation
- Built directly on top of Navigator 2.0 (`Router`, `RouterDelegate`,
  `RouteInformationParser`)

## Status

This package is in early development. The API is not yet stable and may
change significantly between versions.

## Getting started

Add `rolter` to your `pubspec.yaml`:

```yaml
dependencies:
  rolter: ^0.0.1
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

// 1. Define a typed route tree.
sealed class AppRoute implements RouteNode {
  const AppRoute();
  @override
  List<AppRoute> get children => const [];
  @override
  AppRoute withChildren(List<RouteNode> children) => this;
}

final class HomeRoute extends AppRoute {
  const HomeRoute();
  @override
  LocalKey get pageKey => const ValueKey('home');
  @override
  String get name => 'home';
  @override
  Map<String, String> toParams() => const {};
  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: Scaffold(body: Center(child: Text('Home'))));
}

// 2. Register decoders so URLs / deep links rebuild the tree.
final registry = RouteRegistry<AppRoute>(
  {'home': (params, children) => const HomeRoute()},
  fallback: (uri) => const HomeRoute(),
);

// 3. Wire Navigator 2.0.
final state = RoutesState<AppRoute>(const [HomeRoute()], (stack) => stack);

final app = MaterialApp.router(
  routerDelegate: RoutingDelegate<AppRoute>(state),
  routeInformationParser:
      RoutingInformationParser<AppRoute>(TreeUrlCodec(registry)),
);
```

See the [`example/`](example/) app for nested navigation, tabs, route guards,
push-for-result, dialog-as-route, and per-route dependency scopes.

## Custom pages & transitions

A route's `buildPage` may return **any** `Page` — the engine never downcasts to
a concrete page type, so flat, nested, dialog, and custom-transition routes all
share one code path. Pick by how much you need:

| Need | Return | Custom `Route`? |
|---|---|---|
| A bespoke transition (fade/slide/scale) | `TransitionPage(transitionsBuilder: …)` | no |
| Full route semantics (drag-to-dismiss, barrier, predictive back) | your own `PageRoute`/`ModalRoute` (like `NoAnimationPage`) | yes |
| No animation for a whole nested stack | a `TransitionDelegate` (e.g. `NoAnimationTransitionDelegate`) on the navigator | — |

**One invariant:** a custom `Page` whose `createRoute` builds its own `Route`
MUST pass `settings: this`. The delegate matches a removed page back to its node
by `pageKey` read from the route's `settings`; omit it and the node leaks from
the tree.

## Organising the catalog: monolithic vs feature-first

The engine depends only on the `RouteNode` interface and a `RouteRegistry` map,
so the app's route catalog can be organised either way — pick by scale.

### Monolithic (small / single-module apps)

One `sealed` base, routes as `part` files, one registry. The win is an
**exhaustive `switch`** — the compiler flags an unhandled route.

```dart
// app_route.dart — one library
sealed class AppRoute implements RouteNode {
  const AppRoute();
  @override
  List<AppRoute> get children => const [];
  @override
  AppRoute withChildren(List<RouteNode> children) => this;
}

part 'home_route.dart';   // final class HomeRoute extends AppRoute { ... }
part 'detail_route.dart';

final registry = RouteRegistry<AppRoute>({
  'home':   (_, _) => const HomeRoute(),
  'detail': (p, _) => DetailRoute(int.parse(p['id']!)),
}, fallback: NotFoundRoute.new);
```

### Feature-first (large / multi-package / DDD)

Each feature owns its routes (`class XRoute implements RouteNode` — non-sealed,
so it can live in its own package), a wire-name enum, a decoder contribution,
and its navigation sugar. The composition root only aggregates:

```dart
// feature/home/home_routes.dart
Map<String, RouteDecoder<AppRoute>> get homeRoutes => {
  HomeRouteName.home.wire:   (_, _) => const HomeRoute(),
  HomeRouteName.detail.wire: (p, _) => DetailRoute(int.parse(p['id']!)),
};

// routing/app_registry.dart — composition root
final appRegistry = RouteRegistry<AppRoute>({
  ...homeRoutes, ...mailboxRoutes, ...itemsRoutes, /* ... */
}, fallback: NotFoundRoute.new);
```

A feature with no deep link need not register at all. Dropping `sealed` costs
the exhaustive `switch` but lets routes span packages. **The [`example/`](example/)
app is a worked feature-first reference.**

Rule of thumb: monolithic for a single app; feature-first once features become
their own packages or teams.

## Additional information

- Source code: https://github.com/ntfnd404/rolter
- Issue tracker: https://github.com/ntfnd404/rolter/issues
- License: MIT
