## 0.4.0

### Breaking changes

- `RoutingInformationParser` now requires `routesForRootPath`. Applications
  explicitly map `/` to their complete structural root stack; Rolter no longer
  allows the built-in codec's empty value to reach a root Navigator and does
  not assume a `home` route.
- `RoutesState` now rejects an empty initial or final committed root. Empty
  requested snapshots remain valid when the application pipeline normalizes
  them to a non-empty result.

### Changed

- `/` is treated as an input alias. The selected codec determines the
  canonical URL, so a mapping such as `/ → DashboardRoute` is reported as
  `/dashboard` (or a codec-specific opaque URL). With `RoutingConfig`, a Web
  correction replaces the alias entry instead of creating a Back loop.
- `TreeUrlCodec` and `Base64RouteCodec` retain raw empty-tree round-tripping
  through `/`. Malformed non-root built-in URLs that contain no valid node now
  use the registry fallback; partially valid Base64 payloads keep valid nodes.
- `NestedNavigatorHost` renders an empty box while its addressed subtree is
  absent or has no children, instead of constructing a nested Navigator with
  no pages. It creates the Navigator again when children appear.
- Parser failures preserve their original error object and stack without
  including route information, query data, state, routes, or keys in
  Rolter-owned diagnostics.
- `EntryQueryStore` is explicitly a decoded single-value map for the most
  recent entry attempt; capture is not rolled back by a later parsing failure.
- Base64 decoding retains its first-non-empty-segment compatibility rule, and
  empty nested hosts bubble Back without invoking a nested override.

### Documentation

- Added the [0.3.0 to 0.4.0 migration guide](doc/migration_0_3_to_0_4.md),
  including root aliases, canonical URLs, custom parser/codec duties, Web
  history correction, and the non-empty committed-root invariant.

## 0.3.0

### Added

- `RoutingConfig`, the recommended root `MaterialApp.router` integration.
  It starts framework transaction identity before parsing, preserves custom
  parsers/providers and `RouteInformation.state`, and coordinates root Back,
  request settlement, and URL reporting without a second route-state tree.

### Changed

- `RoutingDelegate` now gives every new, initial, and restored framework route
  path its own Future. The Future waits for that request's asynchronous
  pipeline, reaches completion immediately before its synchronous state
  publication, and does not wait for later requests in the shared FIFO drain.
- The coordinated config abandons an uncommitted framework transaction when a
  newer platform route or root Back supersedes it. Every actually enqueued app
  mutation creates the same temporal FIFO barrier, while pre-enqueue no-ops and
  failed predicate/transform calculations leave platform work untouched.
- Framework request errors preserve their original object and stack. Tracked
  framework requests buffered behind a failed transaction receive the same
  causal error without running, while a fresh request can start a new drain.
- `popWith(result)` now completes the pending result only when the applied tree
  removes its target. Guard reverts and live failures keep a committed result
  pending; failed speculative result routes complete with `null`.
- Browser guard corrections use replace-style reporting to avoid Back loops.
  A browser-selected URL may remain visible while async policy settles, but it
  is not committed route state. App routes that publish normally keep Flutter's
  standard reporting; no-publication, failure, discard, and unhandled root Back
  restore the committed URI without allowing stale corrections to win. A newer
  platform intent also suppresses an older report that Flutter already prepared
  for its next frame, including during initial async parsing, and teardown
  prevents late reports from reaching the route-information provider.
- Route-report intentions now belong to their actual presentation: current app
  `Router.navigate` and `Router.neglect` intentions pass through, accepted
  platform routes use Flutter's default intention, and corrections replace the
  rejected entry. An unrelated report cannot consume another presentation's
  prepared correction policy.
- Coordinated transactions retain only the originating URI. Opaque
  `RouteInformation.state` still reaches custom parsers unchanged and is never
  compared, logged, or stringified by Rolter.
- The supported pre-1.0 public surface and compatibility policy are now
  explicit. SDK constraints, route identity, and URL grammar did not change;
  `RoutingConfig` is the only additive public declaration. The existing
  transitive `meta` package is declared directly so package-internal APIs can
  use `@internal` on the minimum supported Flutter version.

### Documentation

- Added the [0.2.1 to 0.3.0 migration guide](doc/migration_0_2_to_0_3.md) for
  callers that directly observe `RouterDelegate` Futures.

## 0.2.1

### Fixed

- `RoutesState.dispose()` now abandons active and buffered navigation work
  without a late commit, notification, observer call, or pipeline error.
  Navigation mutations after disposal throw a generic `StateError` before
  invoking application callbacks or changing pending results.
- Rolter-owned validation diagnostics no longer expose raw duplicate page keys
  or invalid route-name values.

### Changed

- The feature-first example now removes its exact guard-refresh callback before
  disposing the delegate and route state.
- Lifecycle, drain-level Future, callback ownership, and trusted telemetry
  guidance are documented. Public APIs and the URL format are unchanged.

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
