## 0.0.1

Initial release.

- Declarative, tree-based route state (`RouteNode` + pure tree operations) with
  typed, URL-serializable routes. Routes carry an explicit identity contract
  (value equality + a `pageKey` that encodes every identity-bearing param and is
  unique across the tree), with a `KeyedRouteEquality` mixin for leaves and
  debug asserts that catch a duplicate page key, a `StrictHierarchy` parent with
  a disallowed child, or a non-URL-safe route name.
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
- Async-safe navigation through a serial `NavigationQueue` and composable route
  guards (`RouteGuard`, `GuardedPipeline`) with redirect-loop protection
  (the guard fold re-settles, bounded by `maxResettlements`).
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
