## 0.2.0

### Breaking changes

- **Breaking change:** `RouteNode` is now navigation data only and no longer
  declares `buildPage(BuildContext)`.
- `RoutingDelegate` and `NestedNavigatorHost` now require a
  `RouteNodePageBuilder<R>`. Root and nested navigation use the same builder and
  reject a page unless its key is non-null and equals `route.pageKey`.

Before 0.2.0, every route implemented `RouteNode.buildPage` and delegates built
pages implicitly:

```dart
final delegate = RoutingDelegate<AppRoute>(state);
```

For the closest 0.2.0 migration, implement the permanent `PageRouteNode`
convenience interface and pass its adapter explicitly:

```dart
final delegate = RoutingDelegate<AppRoute>(
  state,
  pageBuilder: buildPageFromRouteNode<AppRoute>,
);
```

Alternatively, keep routes data-only and pass an application-owned external
builder. Every returned root or nested `Page` must set
`key: route.pageKey`; missing or mismatched keys now throw `StateError` in all
build modes.

The URL wire format and existing codecs are unchanged. This release does not
require an intermediate 0.1.1 compatibility release: before 1.0, a minor
version increment communicates an approved breaking Dart API change.

### Added

- `RouteNodePageBuilder<R>` for application-owned Flutter `Page` composition.
- `PageRouteNode` and `buildPageFromRouteNode` as a permanent convenience API
  for small applications that prefer route-owned page composition.
- Runtime-safe validation for incompatible child types in nested navigators.
- A feature-first example page catalog with typed dispatch and narrow
  constructor injection.
- Four runnable composition references: feature-first constructor injection,
  centralized route-owned routing, external builder with a narrow inherited
  scope, and a deliberately limited application-only router-neutral adapter.
- A page-composition architecture guide and a complete `0.1.x` to `0.2.0`
  migration guide.

See [Page composition](https://github.com/ntfnd404/rolter/blob/v0.2.0/doc/page_composition.md)
and the complete
[Migration to 0.2.0](https://github.com/ntfnd404/rolter/blob/v0.2.0/doc/migration_0_1_to_0_2.md)
for the public API diff, composition choices, scope semantics, and migration
steps.

## 0.1.0

Initial release.

- Declarative, tree-based route state (`RouteNode` + pure tree operations) with
  typed, URL-serializable routes. Routes carry an explicit identity contract
  (value equality + a `pageKey` that encodes every identity-bearing param and is
  unique across the tree), with a `KeyedRouteEquality` mixin for leaves and
  production validation that rejects a duplicate page key or a non-URL-safe
  route name. `StrictHierarchy` remains an opt-in debug diagnostic for mis-wired
  nesting.
- URL grammar via a swappable `RouteUrlCodec` (default `TreeUrlCodec`,
  dot-depth): lossless param round-trip (values with `&`, `%`, `/`, or
  non-ASCII are preserved) and standard `?k=v` query interop, with an optional
  `EntryQueryStore` to keep pass-through params (e.g. `utm_*`) the tree does not
  model.
- Navigator 2.0 wiring: `RoutingDelegate`, `RoutingInformationParser`,
  `NavigationService` and `NavigationController`.
- Built-in nested navigation via `NavigatorScope` and `NestedNavigatorHost`
  (path-addressed, with an optional `transitionDelegate` and a single
  back-button override hook).
- Async-safe navigation through a public, fail-fast `NavigationQueue`; the
  mutable queue owned by `RoutesState` remains encapsulated. Composable guards
  (`RouteGuard`, `GuardedPipeline`) include redirect-loop protection (the guard
  fold re-settles, bounded by `maxResettlements`).
- Predicate stack operations over the typed route — `popUntil`, `removeWhere`,
  `pushAndResetTo` — as pure tree functions and on `NavigationService`.
- Read-only navigation telemetry via `NavObserver` (each commit reports the
  previous/next stacks and the entered/left page keys).
- Deep links are handled by guards (no separate subsystem); a `PendingLocation`
  store holds the intended target for return-after-login/unlock, and a
  `StreamListenable` bridges a `Bloc`/`Cubit`/stream into the `Listenable` a
  guard exposes (read state synchronously, re-evaluate on each event).
- Browser-like `NavigationHistory` — back/forward over committed states (wired
  as a `NavObserver`, replays via a `restore` callback; new navigation drops the
  forward tail).
- Mountable feature sub-routers: a `RouteRegistry` can mount sub-registries
  (`children`) so a feature owns its own route-name namespace, composed via
  `FeatureRouter` + `composeFeatureRouters` (two features can each have a
  `detail` route). Page keys remain global.
- `Base64RouteCodec` — an opaque base64url-JSON-in-path `RouteUrlCodec` for
  redirects that strip the fragment (OAuth / Telegram); the whole route survives
  as one token.
- Navigation state restores from `RouteInformation` (web reloads/deep links and
  OS-killed relaunch) via `restorationScopeId`; documented and enabled in the
  example.
- Result-returning navigation: `pushForResult` / `popWith` (e.g. pickers and
  dialog-as-route that return a value), keyed by `pageKey` with no leaked
  awaiters.
- Per-route dependency scoping via `RouteScope`.
- Custom `Page` types: `TransparentPage`, `NoAnimationPage`, and `TransitionPage`
  (bespoke transitions without a `Route` subclass), plus a
  `NoAnimationTransitionDelegate` for animation-free nested stacks.
- `example/` app demonstrating the engine end to end: flat + nested navigation,
  `IndexedStack` tabs, route guards with a lock/restore flow, push-for-result,
  dialog-as-route, per-route scopes, confirm-on-leave via `PopScope`, and
  multi-tab independent stacks (each tab keeps its own stack, all in the URL).
