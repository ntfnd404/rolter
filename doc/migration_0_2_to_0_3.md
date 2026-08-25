# Migrating from Rolter 0.2.1 to 0.3.0

Rolter 0.3.0 keeps route identity, URL grammar, SDK constraints, and existing
method signatures. It adds `RoutingConfig` and changes the observable
completion semantics of Flutter route-path requests and `popWith`.

## Adopt the coordinated root config

The 0.2.1 manual assembly remains supported as a low-level transparent FIFO
integration:

```dart
final delegate = RoutingDelegate<AppRoute>(state, pageBuilder: pages.build);
final parser = RoutingInformationParser<AppRoute>(codec);

MaterialApp.router(
  routerDelegate: delegate,
  routeInformationParser: parser,
);
```

For a root Router with asynchronous parsing, guards, browser history, or system
Back, use the coordinated config:

```dart
final router = RoutingConfig<AppRoute>(
  state: state,
  routeInformationParser: RoutingInformationParser<AppRoute>(codec),
  pageBuilder: pages.build,
);

MaterialApp.router(routerConfig: router);
```

The config sees platform transactions at parser start. A newer platform route
or root Back can therefore supersede an older request before that request
commits. The low-level delegate cannot provide parser-level supersession by
itself, because Flutter has not called it yet while parsing is in progress.

The config borrows a supplied state, parser, provider, and dispatcher. It owns
its adapters and defaults. Stop producers and unmount the Router, then dispose
in this order:

```text
remove application listeners and exact guard refresh callbacks
→ dispose RoutingConfig
→ dispose RoutesState
→ dispose application-owned history, guards, and services
```

Only one active coordinated config may attach to a `RoutesState`, and that
config is intended for one simultaneously mounted root Router. Sequential
remount is supported after the previous Router is fully unmounted; nested
navigators continue to use child dispatchers and route subtrees.

## Request and drain Futures

In 0.2.1, `setNewRoutePath` accepted and enqueued a configuration
synchronously. Its Future did not represent asynchronous guards or commit:

```dart
await delegate.setNewRoutePath(configuration);
// In 0.2.1 the pipeline could still be running here.
```

In 0.3.0, new, initial, and restored route paths receive request-scoped
Futures:

```dart
await delegate.setNewRoutePath(configuration);
// This request settled; a successful state is now published.
```

The Future does not wait for framework or application requests queued after
it. Use the backing state when the application needs the whole active FIFO
drain to become idle:

```dart
await state.processingCompleted;
```

A live request error retains its original object and stack. Buffered tracked
requests discarded by fail-fast receive the same causal error. A superseded or
teardown-abandoned request completes successfully without changing root,
history, observers, listeners, or results.

Expected guard outcomes should not throw. Return a redirect, cancellation, or
normalized tree through the guard pipeline. Reserve exceptions for programming
or infrastructure failures that Flutter may report asynchronously.

## Application FIFO barrier

Application navigation is not converted to latest-wins. An app mutation reads
the latest effective queue snapshot and completes fallible input copying plus
synchronous predicate or transform calculation first. If it will enqueue, it
then seals all committable framework snapshots already accepted by the queue,
invalidates parser-only work, and enqueues its immutable snapshot. This single
temporal rule also applies to absolute operations such as `setRoot` and
`clearAndPush`. Consequently:

```text
framework A → app X → framework B
```

commits in that order. There is no public receipt API, cancellation token, or
automatic command rebase in 0.3.0.

The barrier starts only after input copying and synchronous predicate/transform
calculation succeeds. Keep those callbacks pure and do not navigate from
inside them. A root-stack `pop` or `popWith` that is known to do nothing before
enqueue does not create a barrier or supersede parser-only work. Equivalent
snapshots that are actually enqueued still run the pipeline, and `reevaluate`
is never coalesced.

## Result completion

`popWith(result)` no longer completes its result before navigation policy has
accepted the pop. It completes only if the applied tree removes the target.

- A guard revert or live failure leaves a committed route result pending.
- A result route that never commits or is fail-fast discarded completes with
  `null`.
- Disposal still completes every pending result with `null`.
- Result callbacks observe the already-published root.

Most callers need no source change, but code that assumed an immediate result
before the pop commit must now await normal queue settlement.

## Web URL correction

Browser Back/Forward updates the address bar before async parsing or guards
finish. The transient URL is not committed Rolter state. If normalization,
redirect, or guard revert yields another URI, the coordinated provider replaces
the rejected browser entry instead of pushing a correction that could create a
Back loop. While a platform request is pending, Rolter suppresses reports of the
previous committed presentation, including an initial root or a report Flutter
already prepared for its next frame.

An app mutation that publishes a new route while a browser request is pending
keeps ordinary Flutter reporting, so Back may intentionally select that browser
entry again. If the app mutation publishes nothing, fails, is fail-fast
discarded, or root Back is unhandled, the last committed URI replaces the
superseded browser entry. A newer platform intent invalidates any older pending
route report or correction.

Explicit `Router.navigate` and `Router.neglect` intentions are preserved for
the current app presentation produced by their callback. A provider-originated
presentation uses the default intention instead of inheriting an older app
callback's pending intention. Custom parser/provider behavior, URI
query/fragment, and opaque
`RouteInformation.state` pass through unchanged. Rolter does not retain it as
transaction identity, compare it, log it, or stringify it. Nested navigators do
not report independent URLs.

## Compatibility checklist

- Import only `package:rolter/rolter.dart`; `src` remains unsupported.
- `RoutesState.processingCompleted` remains a shared drain-level Future.
- The low-level `RoutingDelegate` remains available with transparent FIFO.
- Typed trees, nested navigation, guards, history, restoration, scopes, custom
  Pages, external composition, and codecs keep their existing contracts.
- No cancellation, coalescing, latest-wins queue, or public request receipts
  were added.
