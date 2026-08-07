# Rolter examples

The package contains four isolated application import graphs because each one
solves a different application problem. They use the same pure Flutter UI for
a Home → Items → Item detail comparison flow, but each application owns its
route model, Page composition, navigation, and dependencies. The four apps are
reference architectures built from two Rolter composition modes, not four
public Rolter APIs.

Use the root compile-time launcher with one of the tracked, non-secret presets:

```sh
flutter run --dart-define-from-file=env/feature_first.env
flutter run --dart-define-from-file=env/centralized_route_owned.env
flutter run --dart-define-from-file=env/external_builder_scope.env
flutter run --dart-define-from-file=env/router_neutral_adapter.env
```

Open `example/` as the VS Code workspace to use the same four launch presets.
Dedicated entrypoints below remain available when you want to compile one
isolated app directly.

## Feature-first with constructor injection

This solves modular routing ownership: each feature owns its route, decoder,
navigation methods, and typed Page contribution, while the composition root
injects narrow dependencies. It is the recommended enterprise reference and
retains the complete advanced showcase:
nested and independent stacks, namespaces, guards, results, restoration,
custom Pages, transitions, and route-lifetime resources.

```sh
flutter run # defaults to feature-first
flutter run -t lib/apps/feature_first/main.dart
```

See [`lib/apps/feature_first/`](lib/apps/feature_first/).

## Centralized route-owned composition

This solves the conventional small-app case where developers want the complete
route map in one place with minimum abstraction. The route family, decoder map,
and route-owned Page selection live in one `centralized_route_catalog.dart`.
The trade-off is direct coupling between route data and Flutter UI.

```sh
flutter run -t lib/apps/centralized_route_owned/main.dart
```

See [`lib/apps/centralized_route_owned/`](lib/apps/centralized_route_owned/).

## External builder with a narrow Scope

This solves separation of route data from UI while preserving an established
inherited-DI convention. The external `RouteNodePageBuilder` reads one
capability-specific repository scope above `MaterialApp.router`, then passes
the exact repository instance into application-owned screens. Runtime scope
placement is the main trade-off.

```sh
flutter run -t lib/apps/external_builder_scope/main.dart
```

See [`lib/apps/external_builder_scope/`](lib/apps/external_builder_scope/).

## Router-neutral application adapter

This solves a real multi-application or multi-router portability requirement.
Application-owned `AppDestination`, `AppRouteDefinition`, and
`AppNavigationController` contracts form a deliberately flat boundary; only
the infrastructure `RolterAdapter` imports Rolter. It costs a second model and
adapter contract tests and is not another Rolter public API.

```sh
flutter run -t lib/apps/router_neutral_adapter/main.dart
```

See [`lib/apps/router_neutral_adapter/`](lib/apps/router_neutral_adapter/).

The shared [`lib/common/ui/`](lib/common/ui/) layer contains only presentation
DTOs, theme, and content-only widgets. It has no Rolter, repository, Scope, or
application imports. For the full comparison and decision guide, read
[Page composition and application architecture](../doc/page_composition.md).
