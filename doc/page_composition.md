# Page composition and application architecture

## What this guide helps you choose

This guide starts from the shape of an application and helps you choose where
routing code, Flutter Page composition, and dependencies should live.

Rolter has two core Page-composition modes:

1. route-owned composition through `PageRouteNode`;
2. data-only `RouteNode` composition through `RouteNodePageBuilder`.

The example package turns those primitives into four complete reference
architectures. They are useful combinations, not four mutually exclusive
Rolter APIs and not an exhaustive list of valid application structures.

## Why there are four example applications

The examples are four deliberate points on a complexity scale. Each solves a
different application or organizational problem while sharing the same
Home → Items → Item detail presentation flow for a fair comparison.

| Runnable architecture | Problem it solves |
|---|---|
| Centralized route-owned | A conventional small application needs its complete route map in one place with minimal abstraction |
| External builder + narrow Scope | UI must leave route data while an existing `InheritedWidget`/Scope-based DI model remains in use |
| Feature-first + constructor injection | A modular application needs each feature to own its routing and Page contributions |
| Router-neutral adapter | Feature or application contracts must be reused across multiple applications or routing engines |

The first three are Rolter-native. The fourth is an application-only boundary
implemented on top of Rolter; it is intentionally not part of the package's
public API.

## Choose by application shape

Start with the constraint that is already real in the application:

- choose **centralized route-owned** when one visible catalog and minimum code
  are more valuable than separating route data from Flutter UI;
- choose **external builder + narrow Scope** when routes should be data-only
  but inherited DI is already an established application convention;
- choose **feature-first + constructor injection** for one strategic,
  modular Rolter application whose feature teams should own their routing;
- choose a **router-neutral adapter** only when cross-application or
  cross-router reuse justifies a second model and adapter contract tests.

Other combinations remain valid. A centralized application can use an
external builder, and a feature-first application can use route-owned Pages.
The runnable examples intentionally select four coherent, teachable defaults
rather than multiplying every possible combination.

## The Rolter composition contract

Route identity, URL state, and tree structure are navigation data. Flutter
Pages, screen composition, and dependency wiring often change for different
reasons. `RouteNodePageBuilder` separates those responsibilities when that
separation is valuable; `PageRouteNode` remains the smaller convenience mode
when it is not.

The normative Rolter contract is deliberately small:

```text
RouteNode data
    ↓ RouteNodePageBuilder Strategy
Flutter Page
```

External composition uses a synchronous Strategy that maps a typed route to a
Flutter Page:

```dart
typedef RouteNodePageBuilder<R extends RouteNode> = Page<Object?> Function(
  BuildContext context,
  R route,
);
```

```text
URL → decoder → RouteNode tree
                    ↓
             guards / RoutesState
                    ↓
         RouteNodePageBuilder Strategy
                    ↓
       root and nested Flutter Navigators
```

The application composition root can now create dependencies, contribute typed
Page factories, and inject only the interfaces a feature needs. Root and nested
navigators use the same internal validation path.

The runtime contract is exact:

- the builder is synchronous and non-owning;
- every Page has `key: route.pageKey`;
- Page keys are compared with `==`, so equal non-identical `ValueKey` instances
  are accepted;
- null and mismatched keys fail in every build mode;
- validation errors do not expose route values, names, URLs, parameters, or
  key values;
- builder exceptions are not caught or wrapped;
- custom Pages and custom `TransitionDelegate` values remain supported;
- custom `Page.createRoute` implementations must still use `settings: this`.

The generic `R` is the common application route family for the rendered tree.
`withChildren` must return a node compatible with that family. Nested hosts
check each immediate `RouteNode` child before passing it to the typed builder;
Rolter 0.2 intentionally does not introduce recursive `RouteNode<R>`.

## Four runnable reference architectures

### 1. Route-owned `PageRouteNode`

**Problem solved.** A conventional small or medium application needs one place
where developers can inspect the complete route map, decoder registrations,
and Page selection without introducing a composition catalog.

**Ownership and dependency flow.** The centralized catalog owns the route
family and decoder map. Each route owns its keyed Page. Dependencies are
usually absent or simple; storing services in route values is deliberately not
demonstrated.

**Choose it when** minimum code and a single routing overview matter most.
**Do not choose it as the default** for a large modular dependency graph: the
central catalog grows and route data remains coupled to Flutter UI. It retains
native access to all Rolter features.

The permanent convenience API keeps this setup small:

```dart
sealed class AppRoute with KeyedRouteEquality implements PageRouteNode {
  const AppRoute();

  @override
  List<RouteNode> get children => const [];

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
  Page<Object?> buildPage(BuildContext context) => MaterialPage<Object?>(
    key: pageKey,
    name: name,
    child: const HomeScreen(),
  );
}

final delegate = RoutingDelegate<AppRoute>(
  state,
  pageBuilder: buildPageFromRouteNode<AppRoute>,
);
```

Typical centralized layout:

```text
apps/centralized_route_owned/
├── centralized_app.dart
├── centralized_route_catalog.dart
└── view/
```

Add a feature by implementing `PageRouteNode`, registering its decoder in the
same catalog, returning a keyed Page, and placing its screen in `view/`.

Runnable reference: [`centralized_route_owned/`](../example/lib/apps/centralized_route_owned/).

### 2. Data-only route with external builder and narrow Scope

**Problem solved.** An application wants data-only routes but already has a
stable inherited DI convention and does not need an immediate feature-catalog
reorganization.

**Ownership and dependency flow.** Route data and decoding live in
`route_data/`; Page creation lives in `page_composition/`. The external builder
reads one capability-specific Scope and constructor-injects the dependency
into an app-owned screen. A broad `AppScope.of` still works technically, but a
narrow scope grants less authority and makes the screen dependency explicit.

**Choose it when** inherited DI is already part of the application or during a
staged migration. **Do not choose it** to hide an entire service container
behind leaf-widget lookups. It retains native access to all Rolter features,
with runtime scope placement as its main trade-off.

The route contains no Flutter UI. The application builder reads one
capability-specific inherited dependency and constructor-injects it into the
screen:

```dart
final class MailboxRoute implements RouteNode {
  const MailboxRoute();

  @override
  LocalKey get pageKey => const ValueKey('mailbox');

  @override
  String get name => 'mailbox';

  @override
  List<RouteNode> get children => const [];

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;
}

Page<Object?> buildAppPage(BuildContext context, AppRoute route) =>
    switch (route) {
      MailboxRoute() => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: MailboxScreen(
          repository: MailRepositoryScope.of(context),
        ),
      ),
    };

MailRepositoryScope(
  repository: repository,
  child: MaterialApp.router(
    routerDelegate: RoutingDelegate<AppRoute>(
      state,
      pageBuilder: buildAppPage,
    ),
  ),
);
```

Typical layout:

```text
apps/external_builder_scope/
├── dependency/
├── route_data/
├── page_composition/
└── view/
```

Add a feature by registering its data-only route decoding, adding a Page case,
and placing only the required capability scope.

Runnable reference: [`external_builder_scope/`](../example/lib/apps/external_builder_scope/).

### 3. Rolter-native feature-first with constructor injection

**Problem solved.** A modular application needs feature teams to extend routing
without growing one central switch or exposing the complete dependency graph.

**Ownership and dependency flow.** Each feature owns its route types, decoder
contribution, navigation methods, Page contribution, and UI. Routing data and
Page composition remain separate responsibilities inside the feature. The
application composition root aggregates contributions, creates dependencies,
and passes only narrow interfaces to typed definitions.

**Choose it when** one strategic application uses Rolter and needs modular
ownership, explicit dependencies, and advanced routing. **Do not add a neutral
SPI** unless another router or application is a concrete requirement. This is
the recommended enterprise default and retains direct compile-time access to
all Rolter features.

The feature layout makes that ownership visible:

```text
feature/mailbox/routing/
├── mailbox_route.dart   # data-only RouteNode
├── mailbox_routes.dart  # decoder contribution
└── mailbox_nav.dart     # feature navigation methods

feature/mailbox/page_composition/
└── mailbox_pages.dart   # typed Page contribution
```

```dart
AppRoutePageDefinition buildMailboxPageDefinition({
  required MailRepository repository,
}) => TypedAppRoutePageDefinition<MailboxRoute>(
  pageFactory: (context, route, nestedPageBuilder) =>
      MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: MailboxScreen(repository: repository),
      ),
);

final pages = AppRoutePageCatalog([
  buildMailboxPageDefinition(
    repository: dependencies.mailRepository,
  ),
  // Other feature contributions...
]);

final delegate = RoutingDelegate<AppRoute>(
  state,
  pageBuilder: pages.build,
);
```

The composition root owns `AppDependencies`, but a definition receives only a
narrow repository interface. Typed definitions are indexed by exact route
`runtimeType`; duplicate or missing types fail safely. Page dispatch never uses
`route.name`, because separate URL namespaces may both contain `detail`.

This approach keeps one route model and gives feature modules high cohesion
with low coupling at the cost of a small application catalog. Add a feature by
contributing its route, decoder, Page definition, and typed navigation
extension, then aggregate those contributions at the application boundary.

Runnable reference: [`feature_first/`](../example/lib/apps/feature_first/).

### 4. Application `AppDestination` with `RolterAdapter`

**Problem solved.** Feature or application contracts have a real requirement
to run in multiple applications, with different routing engines, or behind a
separately owned platform/navigation boundary.

**Ownership and dependency flow.** Features depend on `AppDestination`, typed
definitions, and a narrow `AppNavigationController`. Only infrastructure knows
Rolter. Definitions capture narrow dependencies and inject them into screens.
The adapter introduces a second route model, mappings, disposal, and contract
tests.

**Choose it when** portability is an actual organizational requirement. **Do
not choose it** because more abstractions merely look more enterprise: without
another consumer it duplicates models and reduces direct access to advanced
Rolter features. The example supports a bounded flat subset, not complete
router interchangeability.

The example keeps Rolter imports in infrastructure:

```text
apps/router_neutral_adapter/
├── application/
│   ├── app_destination.dart
│   ├── app_route_definition.dart
│   └── app_navigation_controller.dart
├── infrastructure/
│   └── rolter_adapter.dart
└── feature/
    ├── home/
    ├── activity/
    └── catalog/
```

```dart
abstract interface class AppDestination {
  String get wireName;
  String get pageIdentity;
  Map<String, String> toParams();
}

abstract interface class AppNavigationController {
  void push(AppDestination destination);
  void pop();
}

final class AppRouteDefinition<T extends AppDestination> {
  const AppRouteDefinition({
    required this.wireName,
    required this.decode,
    required this.pageFactory,
  });

  final String wireName;
  final T? Function(Map<String, String> parameters) decode;
  final Page<Object?> Function(
    BuildContext context,
    T destination,
    LocalKey pageKey,
    AppNavigationController navigator,
  ) pageFactory;
}
```

```text
AppDestination
    ↓ RolterAdapter
private RouteNode
    ↓ RouteNodePageBuilder
Flutter Page
```

The adapter indexes decoders by `wireName`, indexes Page definitions by exact
destination `Type`, derives a key from destination type and `pageIdentity`, and
owns the Rolter state, controller, delegate, parser, and disposal. Feature Page
factories must put the provided key on their Page. Invalid or unknown locations
become a registered `NotFoundDestination`.

The runnable example intentionally supports a small flat Home, Activity, and
Catalog subset with only `push`/`pop`. Nested navigation, namespaces, guards,
history, results, and restoration would require new application contracts and
adapter contract tests. It is not a promise of complete router
interchangeability and is not Rolter public API. Add a feature by defining a
value destination, definition, UI, and only the navigation port operations it
actually needs.

Runnable reference: [`router_neutral_adapter/`](../example/lib/apps/router_neutral_adapter/).

## Runnable isolation and shared comparison UI

The example package is one Flutter package with four isolated application
import graphs under `lib/apps/`. An application never imports another
approach. All four implement the same semantic Home → Items → Item detail flow,
while the feature-first application additionally retains the advanced Rolter
showcase.

`lib/common/ui/` contains only a theme, presentation DTOs, and content-only
Flutter widgets. It has no routes, destinations, repositories, scopes,
navigation ports, or Rolter imports. Each application maps its own domain data
to the common presentation DTO and supplies callbacks from its own navigation
boundary. This keeps the visible task comparable without hiding the
architectural differences behind a shared application layer.

The root entrypoint is a compile-time launcher, not a fifth architecture. From
`example/`, select a tracked non-secret preset:

```bash
flutter run --dart-define-from-file=env/feature_first.env
```

The dedicated entrypoint remains the direct isolation check:

```bash
flutter run -t lib/apps/feature_first/main.dart
```

Equivalent presets exist for `centralized_route_owned`,
`external_builder_scope`, and `router_neutral_adapter`. Open `example/` as the
VS Code workspace to use its launch menu.

## Independent architectural axes

Do not confuse Page composition, file ownership, dependency delivery, and
router coupling:

| Axis | Options |
|---|---|
| Page composition | Route-owned / external builder |
| Routing ownership | Centralized / feature-first |
| Dependency delivery | No DI / narrow Scope / constructor injection |
| Router coupling | Rolter-native / application adapter |

A centralized app can use an external builder. A feature-first app can use
route-owned Pages. Constructor injection can be composed centrally or from
feature contributions. Choose one primary pattern so ownership, dependency
flow, and extension steps stay predictable; mixing is reasonable during a
migration.

## Rolter-native versus router-neutral

The Rolter-native chain has one model:

```text
AppRoute implements RouteNode
    ↓ RouteNodePageBuilder
Flutter Page
```

The router-neutral chain has two models and a mapping boundary:

```text
AppDestination
    ↓ RolterAdapter
private RouteNode
    ↓ RouteNodePageBuilder
Flutter Page
```

The second chain must map URL parameters, identity, keys, errors, and every
navigation operation. It needs adapter and contract tests and can drift when
either model evolves. In exchange, feature application contracts are not tied
to Rolter. Replacing the engine is easier only for the subset represented by
those contracts.

Rolter-native composition gives direct compile-time access to typed trees,
namespaces, nested stacks, guards, results, restoration, and history. A neutral
SPI either exposes the lowest common denominator or recreates those concepts.
Adding abstractions speculatively is therefore not free portability.

## Which approach is more professional?

More abstractions do not imply more enterprise quality. Professional design
uses the smallest stable boundary that satisfies real organizational needs.

Rolter-native external composition is the recommended default for one
strategic Rolter application. A router-neutral SPI becomes justified when one
or more of these conditions are concrete:

- feature modules are shared by applications using different routers;
- multiple routing engines must be supported concurrently;
- a platform/navigation team owns adapters separately from feature teams;
- application ports are already stable and independently versioned;
- the organization accepts adapter maintenance and contract-test costs.

Without those conditions, the adapter duplicates route models and reduces
access to advanced engine features without delivering useful portability.

## Which approach is more flexible?

Flexibility has several axes. The SPI is most flexible for replacing the
router over its flat subset. Rolter-native composition is most flexible for
using advanced Rolter functionality. External Page composition separates UI
equally well on both sides of an adapter.

| Capability | Route-owned | External + Scope | Rolter-native feature-first | AppDestination + Adapter |
|---|---:|---:|---:|---:|
| Minimum code | Best | Good | Medium | Low |
| Dependency explicitness | Low/medium | Medium | High | High |
| Replace Page composition | Medium | High | High | High |
| Full Rolter access | High | High | High | Through adapter only |
| Replace routing engine | Low | Low | Medium | Highest for flat subset |
| Nested/guards/results/history | Native | Native | Native | Need new SPI contracts |
| Number of route models | 1 | 1 | 1 | 2 |
| Boilerplate | Low | Low | Medium | High |
| Drift risk | Low | Low | Low | Higher |
| Feature reuse across routers | Low | Low | Medium | High |
| Recommended scale | Small | Migration/existing scopes | Enterprise Rolter app | Multi-app/multi-router platform |

## Decision guide

```text
Small application?
  → PageRouteNode

Already have inherited DI?
  → External builder + narrow Scope

One strategic Rolter app with feature modules?
  → Rolter-native feature-first + constructor injection

Features must run in applications with different routers?
  → AppDestination + application adapter
```

## Scope and lifecycle semantics

These mechanisms solve different ownership problems:

- the application composition root owns the app-wide dependency graph;
- a narrow feature or flow scope exposes one capability to a subtree;
- `NavigatorScope` exposes a navigation-specific facade and performs a
  non-listening lookup; its navigator stays stable for the scope lifetime;
- `RouteScope` owns a page/widget-lifetime resource;
- constructor-captured dependencies are read without a context lookup.

Flutter placement semantics are important and test-covered:

- a scope above `MaterialApp.router` is visible to the delegate Page builder
  and Page subtree;
- a scope returned from `MaterialApp.router.builder` wraps the Router child, so
  it is also visible to the delegate Page builder and Page subtree;
- a scope placed inside a Page is visible only below that Page boundary.

Use `MaterialApp.router.builder` when the scope should be rebuilt around the
whole Router subtree, for example after a tenant or session graph changes. Use
an outer scope when it owns the router itself. In either placement,
`updateShouldNotify` must reflect dependency identity changes if consumers
should rebuild.

Page builders are descriptions, not owners. They can run repeatedly. Do not
start I/O, navigate, mutate route state, or allocate a disposable object in a
builder. Capture app-lifetime dependencies in composition and put disposable
Page resources in a provider or `RouteScope`:

```dart
MaterialPage<Object?>(
  key: route.pageKey,
  child: RouteScope<EditorController>(
    create: EditorController.new,
    dispose: (controller) => controller.dispose(),
    child: const EditorScreen(),
  ),
);
```

`RouteScope` creates once on mount, preserves the instance across rebuilds,
captures the corresponding disposer, recreates on Widget key replacement, and
disposes when the Page subtree unmounts. A failed `create` has no value to
dispose.

## Nested composition and custom Pages

Shell factories receive the complete composite builder and forward it to each
nested host:

```dart
Page<Object?> buildShellPage(
  BuildContext context,
  ShellRoute route,
  RouteNodePageBuilder<AppRoute> nestedPageBuilder,
) => MaterialPage<Object?>(
  key: route.pageKey,
  child: NestedNavigatorHost<AppRoute>(
    service: NavigatorScope.of<AppNavigator>(context),
    path: const ['shell'],
    pageBuilder: nestedPageBuilder,
  ),
);
```

Builders may return `MaterialPage`, `TransparentPage`, `TransitionPage`,
`NoAnimationPage`, or an application Page. Transition delegates remain on the
relevant navigator. Every Page still uses `route.pageKey`, and a custom
`createRoute` passes `settings: this`.

## Extending each style

For route-owned centralized routing, add the route and its decoder to the
central module. For external Scope composition, also add a builder case and
place the narrow scope. For Rolter-native feature-first composition, add four
feature contributions and register them in application catalogs. For the
adapter SPI, add a destination and definition, then verify both engine-neutral
contracts and Rolter mapping contracts.

Choose extension points using OOP, SOLID, GRASP, DRY, and familiar GoF roles:

- `RouteNodePageBuilder` is a Strategy;
- `buildPageFromRouteNode` is an Adapter for route-owned composition;
- the application composition root is Creator and Information Expert;
- feature contributions preserve High Cohesion and Low Coupling;
- one shared root/nested validation helper avoids duplicated policy.

Avoid these anti-patterns:

- services stored in routes or destinations;
- UI imports in a data-only route;
- Page dispatch by `route.name`;
- app-wide container lookup from leaf widgets;
- disposable resources created in a Page builder;
- asynchronous Page builders;
- a global mutable Page registry;
- a giant neutral `AppNavigationController` mirroring every engine feature;
- claims of full router interchangeability without equivalent contracts;
- an adapter SPI without a concrete organizational need.

## Public API versus example-only API

| Symbol | Location | Status |
|---|---|---|
| `RouteNodePageBuilder` | Rolter | Public |
| `PageRouteNode` | Rolter | Public |
| `buildPageFromRouteNode` | Rolter | Public |
| `AppRoutePageDefinition` | Main example | Application-only |
| `AppDestination` | Adapter example | Application-only |
| `AppRouteDefinition` | Adapter example | Application-only |
| `AppNavigationController` | Adapter example | Application-only |
| `RolterAdapter` | Adapter example | Application-only |

Rolter core intentionally contains no DI container, service locator, BLoC or
provider integration, application catalog, router-neutral SPI, global
registry, asynchronous Page builder, reflection, or code generation.

See the [0.1.x to 0.2.0 migration guide](migration_0_1_to_0_2.md) only when
migrating the breaking Dart API. The [example package](../example/example.md)
contains commands that run all four reference architectures.
