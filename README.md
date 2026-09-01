# Rolter

A typed, tree-based Flutter router with deep linking, nested navigation,
guards, and external Page composition.

## Features

- Typed, URL-serializable route trees
- Route-owned or external Flutter Page composition
- Root and nested navigators driven by one route-state tree
- Guards, navigation history, results, and restoration
- Request-scoped asynchronous Router transactions over deterministic FIFO
- Custom Pages, transitions, and independent nested stacks
- Built directly on top of Navigator 2.0 (`Router`, `RouterDelegate`,
  `RouteInformationParser`)

Rolter models the complete navigation state as an immutable typed tree. The
same tree drives root and nested navigators, URLs, guards, history, restoration,
and result-returning routes without requiring code generation or a DI framework.

## Status and compatibility

Rolter is pre-1.0. Starting with 0.3.0, the API exported from
`package:rolter/rolter.dart` and the built-in URL formats are treated as
supported compatibility contracts.

Patch releases are backward-compatible. Before 1.0, a necessary incompatible
public API change may ship only in a minor release and must be documented in
the changelog with migration guidance. Raising the minimum supported Dart or
Flutter SDK is also a compatibility-impacting minor change.

Imports from `package:rolter/src/` are unsupported implementation details and
may change without notice. Lifecycle, error, disposal, and URL compatibility
rules documented below are part of the supported behavioral contract.

Rolter requires Flutter 3.32 or later and Dart 3.8 or later. Development and
canonical formatting use the latest stable SDK, while CI verifies the declared
minimum and the latest stable release.

## Architecture

![Rolter architecture](https://raw.githubusercontent.com/ntfnd404/rolter/main/screenshots/architecture.webp)

The URL codec reconstructs typed route nodes, guards settle the requested
tree, and `RoutesState` commits a single source of truth rendered by root and
nested navigators.

![Deep link followed by nested and root back navigation](https://raw.githubusercontent.com/ntfnd404/rolter/main/screenshots/deep_link_nested_back.gif)

The animation opens a deep link into a nested stack, then removes the nested
detail before returning through the root stack.

## Getting started

Add `rolter` to your `pubspec.yaml`:

```yaml
dependencies:
  rolter: ^0.4.0
```

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

// 1. Define a typed route tree. PageRouteNode is the concise route-owned mode.
sealed class AppRoute with KeyedRouteEquality implements PageRouteNode {
  const AppRoute();

  @override
  List<AppRoute> get children => const [];

  @override
  AppRoute withChildren(List<RouteNode> children) => this;
}

final class DashboardRoute extends AppRoute {
  const DashboardRoute();

  @override
  LocalKey get pageKey => const ValueKey('dashboard');

  @override
  String get name => 'dashboard';

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage<Object?>(
    key: pageKey,
    name: name,
    child: const Scaffold(body: Center(child: Text('Dashboard'))),
  );
}

// 2. Register decoders so URLs / deep links rebuild the tree.
final registry = RouteRegistry<AppRoute>(
  {'dashboard': (params, children) => const DashboardRoute()},
  fallback: (uri) => const DashboardRoute(),
);

// 3. Wire the coordinated Navigator 2.0 integration.
final state = RoutesState<AppRoute>(
  const [DashboardRoute()],
  (stack) => stack,
);
final router = RoutingConfig<AppRoute>(
  state: state,
  routeInformationParser: RoutingInformationParser<AppRoute>(
    TreeUrlCodec(registry),
    routesForRootPath: (information) => const [DashboardRoute()],
  ),
  pageBuilder: buildPageFromRouteNode<AppRoute>,
);

final app = MaterialApp.router(
  routerConfig: router,
);
```

### The `/` entry URL

Rolter does not assume that an application has a route named `home`. The
built-in parser therefore requires `routesForRootPath`, which maps an empty or
slash-only incoming path to the application's complete structural root stack.
The callback receives the original `RouteInformation`, including query,
fragment, and opaque `state`. Keep it synchronous, deterministic, and free of
navigation side effects; authentication and session decisions belong in the
route pipeline.

`/` is an input alias, not necessarily the canonical URL. In the example above,
opening `/` commits `DashboardRoute`, then `TreeUrlCodec` restores it as
`/dashboard`. `RoutingConfig` reports that Web correction with `neglect`, so it
replaces the alias entry instead of creating a Back loop. A different codec may
produce an opaque canonical URL. Routes returned by `routesForRootPath` must
round-trip through the selected codec by route-tree value equality, including
nested children and identity-bearing parameters. This is an application
contract rather than an additional runtime encode/decode by Rolter. If the
last returned route is `HistoryExcluded`, the stack is still accepted but URL
reporting is intentionally suppressed.

An optional `EntryQueryStore` captures `Uri.queryParameters` before route
resolution. Its value is a decoded, single-value map rather than a lossless raw
query string, and a later parsing failure does not roll it back. The opaque
input `RouteInformation.state` is available to `routesForRootPath` but is not
automatically copied to restored or canonical route information.

The raw codec domain still includes an empty tree: both built-in codecs can
round-trip `[]` through `/`. Router state is stricter. `RoutesState` requires a
non-empty initial and committed root because Flutter's root `Navigator.pages`
cannot be empty. A custom parser or app mutation may submit `[]` only when the
pipeline intentionally normalizes it to a non-empty application root.

To call navigation from screens via `context.navigator`, place a
`NavigatorScope` (with your `NavigationController`) **above**
`MaterialApp.router` — see the [`example/`](example/) app. The snippet above
renders and deep-links without it. The composition owner must dispose `router`
before `state`.

For application-owned composition, dependency-injection options, and exact
scope visibility, see [Page composition](doc/page_composition.md). The
[`example/`](example/) app is the feature-first external-composition reference
and also demonstrates nested navigation, guards, results, and per-route scopes.

Import only `package:rolter/rolter.dart`. Anything under
`package:rolter/src/` is implementation detail and may change in any release.

## Dependency injection (DI) and page composition

Choose the example that matches the shape of your application. Rolter itself
has only two core Page-composition modes: route-owned `PageRouteNode`, or a
data-only `RouteNode` mapped by an external `RouteNodePageBuilder`. The four
runnable architectures combine those primitives with different routing
ownership, dependency delivery, and portability requirements.

| Runnable architecture | Best fit | Main trade-off |
|---|---|---|
| Centralized route-owned | Conventional small apps that need one complete routing map | Least code; route data knows Flutter UI |
| External builder + narrow `Scope.of` | Existing inherited DI or staged UI separation | Clean route data; runtime scope placement |
| Feature-first + constructor injection | Modular Rolter apps (recommended) | Feature ownership and explicit dependencies; small application catalog |
| Router-neutral application adapter | Real multi-app or multi-router platforms | Portability for its bounded subset; two models and adapter tests |

Centralized versus feature-first describes who owns routing files. Scope versus
constructor injection describes dependency flow. The adapter adds an
application-owned portability boundary; it is example code, not a fourth
Rolter composition API.

The low-level Page delegate used inside the coordinated config is also
available for advanced manual Router assembly:

```dart
final delegate = RoutingDelegate<AppRoute>(
  state,
  pageBuilder: buildPageFromRouteNode<AppRoute>,
);
```

Manual assembly keeps transparent FIFO semantics but cannot see a newer
platform request while an asynchronous parser is still running. Prefer
`RoutingConfig` for a root Router with async parsing or guards.

With a data-only route, composition moves to an application builder:

```dart
Page<Object?> buildAppPage(BuildContext context, AppRoute route) =>
    switch (route) {
      MailboxRoute() => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: MailboxScreen(repository: mailRepository),
      ),
    };

final delegate = RoutingDelegate<AppRoute>(
  state,
  pageBuilder: buildAppPage,
);
```

The builder can capture a constructor-injected dependency or read an
application-defined narrow scope. Both a scope above `MaterialApp.router` and a
scope returned by `MaterialApp.router.builder` wrap the Router, so both are
visible to the delegate Page builder and Page subtree. A user-defined
`AppScope.of(context)` still works; `AppScope` was example code, never Rolter
API. Prefer capability-specific scopes over broad container lookup from leaf
widgets.

The four runnable references are:

- [`example/lib/apps/feature_first/`](example/lib/apps/feature_first/): modular,
  constructor-injected Rolter-native enterprise reference and default app;
- [`example/lib/apps/centralized_route_owned/`](example/lib/apps/centralized_route_owned/):
  centralized route-owned composition;
- [`example/lib/apps/external_builder_scope/`](example/lib/apps/external_builder_scope/):
  external builder with a narrow inherited scope;
- [`example/lib/apps/router_neutral_adapter/`](example/lib/apps/router_neutral_adapter/):
  application-only, router-neutral flat adapter example.

Each folder is an isolated application import graph. They share only pure
Flutter presentation content for the same Home → Items → Item detail flow, so
the routing and dependency differences can be compared without duplicating UI.
The feature-first app additionally retains the complete advanced showcase.

From `example/`, select an app through the compile-time launcher:

```bash
flutter run --dart-define-from-file=env/feature_first.env
```

Or run the dedicated entrypoint to verify its isolated import graph:

```bash
flutter run -t lib/apps/feature_first/main.dart
```

Open `example/` as the VS Code workspace to use its four launch presets.

`RoutingDelegate.pageBuilder` and `NestedNavigatorHost.pageBuilder` are
required. Every result uses `key: route.pageKey`; builders are synchronous and
non-owning, so disposable resources belong to a provider or `RouteScope`.

Read [Page composition and application architecture](doc/page_composition.md)
to choose by application shape and compare ownership, dependency flow,
lifecycle, extensibility, and router portability. See
[Migration from 0.1.x to 0.2.0](doc/migration_0_1_to_0_2.md) for the exact
breaking API diff. When upgrading from 0.2.1, also read
[Migration from 0.2.1 to 0.3.0](doc/migration_0_2_to_0_3.md) for the new
request-scoped `RouterDelegate` Future contract. For 0.4.0, read
[Migration from 0.3.0 to 0.4.0](doc/migration_0_3_to_0_4.md) for the required
root-path mapping and non-empty committed-root invariant.

## Extensible navigation scheduling and security

`NavigationQueue` is a public, fail-fast FIFO primitive for custom navigation
architectures. It copies submitted snapshots, serializes asynchronous
processors, and never silently drops or coalesces requests. Requests queued
behind a failed processor are discarded, and a fresh request is accepted after
the failure has been observed through `processingCompleted`.

The queue intentionally has no built-in capacity or overflow policy. If an
application can generate navigation faster than its processor can settle it,
debounce or rate-limit that event source before adding snapshots.

`RoutesState` deliberately does not expose its mutable internal queue. Use its
navigation methods and the read-only `isProcessing` and `processingCompleted`
properties so every request passes through the configured `ApplyPipeline`.
`processingCompleted` represents the whole active drain: requests added before
the queue becomes idle share it, and a failure discards work buffered behind
the failed snapshot.

In `0.3.0`, every new, initial, or restored framework route path receives its
own Future. That Future remains pending while the request's pipeline runs,
completes at its commit boundary, and preserves that request's live error and
stack. By the time a success callback runs, the resulting route state is
published. It does not wait for later requests in the same drain.

This request Future and `RoutesState.processingCompleted` have different jobs:
the former settles one framework transaction, while the latter waits for the
whole active drain, including requests added before the queue becomes idle.
`RoutingConfig` additionally creates transaction identity at parser start.
A newer platform route or a root system Back supersedes an older uncommitted
framework transaction, including one still parsing. A superseded request is
abandoned without a route, history, observer, result, or widget transition.
Once a request has committed it is no longer supersedable; Flutter may also
call `RouterDelegate.build` for an unrelated parent rebuild. Avoiding display
of an already committed state in that case would require a second render-state
tree, which Rolter deliberately does not introduce.

Application navigation is never silently discarded by this policy. Every app
mutation first reads the latest effective queue state and completes its input
copying plus synchronous predicate or transform calculation. If the operation
will enqueue, it then creates one temporal FIFO barrier, seals all committable
framework snapshots already accepted by the queue, and enqueues the immutable
app snapshot. This includes absolute operations such as `setRoot` and
`clearAndPush`. For example,
`framework A → app X → framework B` commits in exactly that order.

An operation that is known to do nothing before enqueue, such as `pop()` or
`popWith()` on a one-entry effective root stack, creates no barrier and does not
supersede parser-only platform work. Other equivalent snapshots are still
enqueued because a guard may depend on external state; `reevaluate()` always
reruns the pipeline. Predicate and transform callbacks are synchronous routing
calculations: keep them pure and do not call navigation APIs from inside them.
The low-level `RoutingDelegate` remains available when transparent FIFO without
parser-level supersession is the desired integration.

A failure retains the queue's fail-fast behavior: buffered framework Futures
receive the causal error, untracked application snapshots are discarded, and a
fresh request starts a new drain.

`popWith(result)` is commit-aligned: its result completes only when the applied
tree actually removes the target route. A guard revert or live failure leaves
the committed route's result pending; a speculative result route discarded by
a failed drain completes with `null`.

Expected guard decisions such as redirects and cancellation should return a
settled route result rather than throw. A live pipeline exception represents a
programming or infrastructure failure and can surface through Flutter's async
Router integration.

## Router lifecycle

The owner must stop external navigation producers and detach app-owned
listeners before disposing the coordinated config and route state:

```dart
final routeRefresh = pipeline.refresh;
final reevaluateRoutes = state.reevaluate;
routeRefresh.addListener(reevaluateRoutes);

// During owner teardown:
routeRefresh.removeListener(reevaluateRoutes);
router.dispose();
state.dispose();
history.dispose(); // when the application owns NavigationHistory
```

Every navigation mutation throws `StateError` after `RoutesState.dispose()`.
An active pipeline cannot be cancelled generically, but its late success or
error is abandoned without changing the route tree or notifying callbacks;
buffered snapshots do not start their pipelines. Capture `processingCompleted`
before disposal if teardown diagnostics need to observe the remaining drain.
An abandoned framework request Future completes successfully after its queued
work drains, without committing its configuration.

`RoutingConfig` borrows the supplied state, parser, provider, and
back-button dispatcher. It owns its internal adapters and any default platform
provider or dispatcher it creates. Only one active coordinated config may
attach to a `RoutesState`, and one config is intended for one simultaneously
mounted root Router. Fully unmount it before a sequential remount or before
disposing it; nested navigators use child dispatchers and route subtrees rather
than mounting the root config again. Late reports are suppressed after config
or state teardown. Low-level delegates, controllers, and services never own the
state.

An asynchronous guard must remain safe if its dependencies are disposed before
its Future settles. A timeout can bound the drain, but does not provide that
late-safety guarantee. A `pushForResult` awaiter receives `null` on teardown;
check the awaiting UI/owner lifecycle before starting follow-up navigation.

A custom `SnapshotProcessor` is trusted application code and can choose not to
run route guards. Neither it nor `RouteGuard` is a security boundary: modified
clients can bypass client-side navigation policy. Always enforce authorization
again on the server before returning protected data or performing a protected
operation.

## Route identity (important)

Every `RouteNode` must have value `==`/`hashCode`, and its `pageKey` must encode
every identity-bearing param and be **unique across the whole tree**. The engine
detects changes with `listEquals` and keys pages by `pageKey`, so a param left
out of both is invisible (the navigation is silently a no-op) and a shared
`pageKey` would collapse two pages into one. `RoutesState` therefore rejects a
duplicate key before commit. Rolter diagnostics do not stringify duplicate
keys, but `NavObserver` intentionally receives raw routes and keys and must be
treated as trusted application code. Log only an allowlisted projection. For a
leaf, put the params in the key and mix in `KeyedRouteEquality`:

```dart
final class ItemRoute with KeyedRouteEquality implements RouteNode {
  const ItemRoute(this.id);

  final int id;

  @override
  LocalKey get pageKey => ValueKey('item:$id'); // every param in the key

  @override
  String get name => 'item';

  @override
  List<RouteNode> get children => const [];

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;
}
```

A shell/tab node distinguished by its `children` or by a param not in `pageKey`
(e.g. the active tab) must override `==`/`hashCode` to compare that state.
`RouteNode.name` is a public URL-schema token such as an enum name; do not use
an entity, account, tenant, or session identifier as the route name.

**Serializable vs runtime params.** Typed route fields carry both kinds, so
there is no separate `arguments`/`extra` split: `toParams()` is the URL wire
format — the serializable identity that survives a deep link (their
`arguments`). A typed field you *don't* put in `toParams()` is runtime-only
(their `extra`): fine within a session, but a cold deep link can't reconstruct
it, so keep anything that must survive in `toParams()`.

## Confirm on leave (blocking back)

Route guards run *after* a page is removed (`onDidRemovePage`), so they can't
pre-empt a back gesture. Block leaving with Flutter's `PopScope` on the screen,
then pop explicitly once confirmed:

```dart
PopScope(
  canPop: !hasUnsavedChanges,
  onPopInvokedWithResult: (didPop, _) async {
    if (didPop) return;
    if (await confirmDiscard(context)) context.navigator.pop();
  },
  child: /* ... */,
);
```

A guard's `cancel` is the *programmatic* safety net — the engine re-syncs the
navigator to the tree when a guard reverts a removal — but per-screen
confirmation belongs in `PopScope`. See the example's "Confirm on leave" demo.

## Deep links & return-after-login

A deep link is just a guard input: the guard pipeline runs on every
`setNewRoutePath`, so a guard can inspect and redirect the incoming stack — no
separate deep-link subsystem. To divert the user (e.g. to a lock/login screen)
and return them afterwards, share a `PendingLocation` with the guard:

```dart
final _pending = PendingLocation<AppRoute>();

@override
GuardResult<AppRoute> call(history, requested, context) {
  if (locked && wantsProtected) {
    _pending.remember(requested);                 // stash the intended target
    return const GuardResult.proceed([LockRoute()]);
  }
  if (_pending.hasPending && onLockScreen) {
    return GuardResult.proceed(_pending.take()!); // restore it on unlock
  }

  return GuardResult.proceed(requested);
}
```

Wire the guard's `Listenable` to `RoutesState.reevaluate` so unlocking reruns
the pipeline and replays the remembered location. See the example's `LockGuard`.

## Guards backed by a Bloc / stream

A `RouteGuard` is a `Listenable` — the pipeline reruns the guards whenever one
fires. A `Bloc`/`Cubit` is a `Stream`, not a `Listenable`, so bridge it with
`StreamListenable` instead of mixing in a `ChangeNotifier`: compose one, delegate
`addListener`/`removeListener` to it, and read the bloc's current value
synchronously from its `state` inside `call`:

```dart
final class LockGuard implements RouteGuard<AppRoute> {
  LockGuard(this._bloc) {
    _refresh = StreamListenable(_bloc.stream); // fires the guard on each event
  }

  final LockBloc _bloc;                        // Bloc<LockEvent, LockState>
  late final StreamListenable _refresh;
  final _pending = PendingLocation<AppRoute>();

  @override
  void addListener(VoidCallback l) => _refresh.addListener(l);

  @override
  void removeListener(VoidCallback l) => _refresh.removeListener(l);

  @override
  GuardResult<AppRoute> call(history, requested, context) {
    if (_bloc.state.isLocked && wantsProtected) {  // read current state, sync
      _pending.remember(requested);
      return const GuardResult.proceed([LockRoute()]);
    }
    if (_pending.hasPending && onLockScreen) {
      return GuardResult.proceed(_pending.take()!);
    }

    return GuardResult.proceed(requested);
  }

  void dispose() => _refresh.dispose();
}
```

The stream only signals *when* to re-evaluate; the decision reads the bloc's
`state` directly, so the guard stays decoupled from how state is stored (the
same shape works for a `ValueNotifier`, an `rxdart` subject, etc.). Pass an
already-`distinct()` (or mapped) stream to avoid redundant reruns.

## Back / forward history

`NavigationHistory` records committed states (wire it as a `NavObserver`) and
replays them through a `restore` callback, giving browser-like back/forward for
in-app controls or non-web targets (on the web the browser already does this):

```dart
late final RoutesState<AppRoute> state;
final history = NavigationHistory<AppRoute>((stack) => state.setRoot(stack));
state = RoutesState<AppRoute>(initial, pipeline, observers: [history]);

// `history` is a ChangeNotifier, so a control can rebuild its enabled state:
IconButton(onPressed: history.canGoBack ? history.back : null, icon: ...);
IconButton(onPressed: history.canGoForward ? history.forward : null, icon: ...);
```

A *new* navigation drops the forward entries (browser semantics); only
`back`/`forward` move the cursor without recording.

## Swapping the URL grammar

The parser depends on the `RouteUrlCodec` interface, not a concrete codec.
`TreeUrlCodec` is the default dot-depth implementation. Rolter also ships
`Base64RouteCodec` — a compact base64url-JSON-in-path codec for redirects that
strip the fragment (OAuth / Telegram): the whole route survives as one token
(`/eyJuIjoiaG9tZSJ9`). Or write your own, as long as `decode(encode(tree))`
round-trips.

At the raw codec boundary, `encode([])` is `/` and direct `decode('/')` is
empty. The built-in parser intercepts that root alias before codec decoding and
requires an app-defined non-empty route stack. For non-root external input,
the built-in codecs use the registry fallback when the payload contains no
valid node; a partially valid Base64 payload keeps its valid nodes. A custom
codec used with the built-in parser must likewise return a non-empty tree for a
non-root URL or apply its own fallback.

Base64url is reversible encoding, not encryption, integrity protection, or
authentication. Anyone can decode, modify, and re-encode the route token. Do
not put secrets, credentials, or personal data in URLs; validate decoded route
semantics and enforce protected data and operations on the server.

### URL compatibility policy

The built-in encoder always writes the current wire format. Before 1.0, a
breaking URL grammar change increments the minor version, and the decoder keeps
accepting the previous minor's format for at least one complete minor release
cycle. Security-critical fixes may shorten that window and will be called out
prominently in the changelog.

Deep links often outlive package constraints. If an application replaces a
built-in codec or changes its route names or serialized parameters, the
application owns the corresponding migration and backward-decoding policy.

## Feature sub-routers (namespace isolation)

A flat registry shares one route-name namespace. When features ship as separate
packages, mount each under its own sub-registry so their names are isolated —
two features can each define a `detail`:

```dart
final shopRegistry = RouteRegistry<AppRoute>(
  {'home': ..., 'detail': ...},   // names local to shop
  fallback: NotFoundRoute.new,
);

final appRegistry = composeFeatureRouters<AppRoute>(
  fallback: NotFoundRoute.new,
  decoders: {...homeRoutes},        // flat top-level routes still work
  features: [
    FeatureRouter(name: 'shop', mountDecoder: ..., registry: shopRegistry),
    FeatureRouter(name: 'blog', mountDecoder: ..., registry: blogRegistry),
  ],
);
// /shop/.detail and /blog/.detail resolve via their OWN registries.
```

Page keys stay **global** (the Navigator's requirement), so keep them unique
across the whole tree (e.g. prefix by feature) even though URL *names* are
isolated. See the example's "Feature sub-routers" demo.

## State restoration

The navigation tree is restored from `RouteInformation`, so it survives a web
reload / deep link **and** an OS-killed relaunch — just set `restorationScopeId`
on `MaterialApp.router`:

```dart
MaterialApp.router(
  restorationScopeId: 'app',
  routerConfig: router,
);
```

The delegate restores through the framework's default `setRestoredRoutePath`
(which funnels into the same `setNewRoutePath`), so no extra engine wiring is
needed. Per-screen *ephemeral* state (scroll offset, a half-typed field) is the
screen's own concern — use Flutter's `RestorationMixin` inside the screen (or a
`RouteScope` value), independent of the router.

## Web transaction and browser-history behavior

On Web, Back or Forward changes the browser address before an asynchronous
parser or guard settles. That pending address may therefore be visible briefly,
but it is not the committed `RoutesState.root`. While that platform transaction
is pending, the previous committed presentation is not reported over the new
address, including during initial asynchronous parsing. A superseded
transaction does not publish a route or report a stale URL, even if Flutter had
already prepared that report for its next frame.

When normalization, redirect, or guard revert produces a different final URI,
the coordinated provider reports the correction with Flutter's `neglect`
intention. The rejected browser-history entry is replaced instead of adding a
new entry that would create a Back loop. `Router.navigate` and `Router.neglect`
intentions pass through for the current app presentation that their callback
produced. A provider-originated presentation uses Flutter's default intention,
so it cannot inherit an older app callback's still-pending intention. Ordinary
app navigation retains Flutter's standard reporting behavior.

If an app mutation supersedes a browser-selected request and publishes a new
route, that app route uses the normal Flutter reporting intention; the browser
entry remains meaningful and Back may select it again. If the app mutation
publishes nothing (no-op/guard revert), fails, is fail-fast discarded, or root
Back is unhandled, Rolter restores the last committed URI with `neglect` so the
rejected browser entry does not become a loop. A later platform intent makes an
older prepared route or correction stale and cannot be overwritten by it.

Custom parsers and providers remain supported. URI path, query, fragment, and
`RouteInformation.state` are passed to them unchanged. Rolter treats `state` as
opaque provider-owned data: it is not retained as transaction identity and is
never compared, logged, or stringified. Only the root
coordinated config should report route information; nested navigators keep
using their child dispatchers and route subtrees. A `RoutingConfig` is not
supported as the simultaneous config of multiple root Router widgets.

## Web URL strategy

rolter is URL-strategy-agnostic — pick one in your app's `main()`:

- **Hash** (Flutter web default — `/#/hub/home~intent=stream`): no server
  config, and the route lives in the fragment, immune to path normalization;
  but not SEO-friendly.
- **Path** (`usePathUrlStrategy()` — `/hub/home~intent=stream`): clean,
  shareable, SEO-friendly URLs, but the server must rewrite unknown paths to
  `index.html`. One caveat: the dot-depth grammar puts leading-dot segments
  (`.settings`) and `~` in the real path, so a proxy/CDN that normalizes
  RFC-3986 dot-segments could rewrite them — test your hosting, or use the hash
  strategy / `Base64RouteCodec` if that bites.

## Custom pages & transitions

A `RouteNodePageBuilder` may return **any** `Page` — the engine never downcasts
to a concrete page type, so flat, nested, dialog, and custom-transition routes
all share one code path. Pick by how much you need:

| Need | Return | Custom `Route`? |
|---|---|---|
| A bespoke transition (fade/slide/scale) | `TransitionPage(transitionsBuilder: …)` | no |
| Full route semantics (drag-to-dismiss, barrier, predictive back) | your own `PageRoute`/`ModalRoute` (like `NoAnimationPage`) | yes |
| No animation for a whole nested stack | a `TransitionDelegate` (e.g. `NoAnimationTransitionDelegate`) on the navigator | — |

**One invariant:** a custom `Page` whose `createRoute` builds its own `Route`
MUST pass `settings: this`. The delegate matches a removed page back to its node
by `pageKey` read from the route's `settings`; omit it and the node leaks from
the tree.
