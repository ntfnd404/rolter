# Migrating from Rolter 0.3.0 to 0.4.0

Rolter 0.4.0 makes the structural meaning of `/` explicit and prevents an
empty route tree from reaching Flutter's root Navigator. This is a minor
release because the built-in parser constructor changes and empty committed
state is no longer accepted.

Route identity, the grammar of valid non-empty built-in URLs, request-scoped
Router Futures, coordinated Web transactions, and the rest of the 0.3.0 public
contract remain unchanged.

## Provide the route stack for `/`

The built-in parser now requires `routesForRootPath`:

```dart
final parser = RoutingInformationParser<AppRoute>(
  TreeUrlCodec<AppRoute>(registry),
  routesForRootPath: (information) => const <AppRoute>[
    DashboardRoute(),
  ],
);
```

The callback returns the complete root stack, including any nested children
needed by the initial structure. Rolter does not infer `HomeRoute`, select the
first registry entry, or put application policy in `RoutingConfig` or
`RoutesState`.

The callback receives the original `RouteInformation`. Its `uri` still
contains query and fragment data, and `state` remains the same opaque object
provided by Flutter or a custom provider. If an `EntryQueryStore` is supplied,
the parser captures `Uri.queryParameters` before calling `routesForRootPath`.
That value is a decoded, single-value map rather than a lossless copy of the
original query string, and it is not rolled back if later parsing fails. Opaque
input `state` is not automatically copied to restored or canonical route
information.

Keep the callback synchronous, deterministic, and free of navigation side
effects. It defines a structural entry point, not an authentication or session
decision. Async authorization, redirects, and guard policy belong in the
application's `ApplyPipeline`.

## `/` is an alias; the codec defines the canonical URL

The routes returned by `routesForRootPath` must round-trip by route-tree value
equality through the selected codec, including nested children and
identity-bearing parameters. Rolter documents this application obligation but
does not perform an additional runtime encode/decode. For example:

```text
incoming URL:       /
root callback:      [DashboardRoute()]
TreeUrlCodec:       /dashboard
```

On Web, `RoutingConfig` reports `/dashboard` with Flutter's replace-style
`neglect` intention. The browser-selected alias is replaced rather than adding
another history entry, so Back does not loop between `/` and `/dashboard`.
Another codec may choose a different, including opaque, canonical URL.
If the last root route implements `HistoryExcluded`, parsing and committing it
remain valid but restoration returns `null`, so no canonical report is sent.

Manual low-level assembly with `RoutingDelegate` and a parser still resolves
the same routes, but it does not provide `RoutingConfig`'s coordinated
post-frame browser-history correction.

Query or fragment values that are not represented by the route model may be
absent from the canonical URL. Use `EntryQueryStore` for attribution query
parameters that must survive outside the typed route tree.

## Empty codec values and committed state are different domains

Raw codecs remain useful independently of Flutter Router and may represent an
empty tree:

```dart
codec.encode(const <AppRoute>[]); // Uri(path: '/')
codec.decode(Uri(path: '/'));     // []
```

Committed root state is stricter because Flutter asserts that
`Navigator.pages` is non-empty:

- `RoutesState(initial, pipeline)` rejects an empty `initial` list;
- the pipeline may receive an empty requested snapshot;
- the pipeline must normalize it to at least one route;
- an empty final pipeline result fails before root, pending results, listeners,
  observers, or history change;
- fail-fast discard and a fresh recovery drain keep their existing behavior.

This preserves a useful policy hook without allowing invalid UI state:

```dart
final state = RoutesState<AppRoute>(
  const <AppRoute>[DashboardRoute()],
  (requested) => requested.isEmpty
      ? const <AppRoute>[DashboardRoute()]
      : requested,
);
```

A custom `RouteInformationParser<List<AppRoute>>` may similarly submit `[]`
only if that pipeline turns it into a non-empty result. The built-in
`RoutingInformationParser` never returns an empty configuration.

## Built-in codec fallback behavior

The grammar of valid non-empty `TreeUrlCodec` and `Base64RouteCodec` values is
unchanged.

- Direct root decoding still returns the raw empty codec value.
- A malformed non-root Tree URL that produces no node uses
  `RouteRegistry.fallback` with the original URI.
- Malformed Base64, a non-list JSON payload, an encoded empty list, a legacy
  empty token, or a payload containing no valid node uses the registry
  fallback.
- A partially valid Base64 list preserves its valid nodes.
- Base64 decoding keeps the 0.3.0 rule of reading only the first non-empty path
  segment. Extra segments are ignored and disappear on canonical encoding.
- In a mixed Base64 list, registered nodes survive, unknown names become the
  registry fallback, and structurally invalid entries are skipped. In
  particular, an optional `c` field must be `null` or a JSON list; another type
  invalidates the containing entry.

A custom codec used with the built-in parser must return at least one route for
every non-root URL or apply its own application-specific fallback. The parser
rejects any empty non-root decode with a privacy-safe `StateError`.

## Nested navigators

Empty child lists remain valid route data. `NestedNavigatorHost` now renders
`SizedBox.shrink()` while the addressed node is missing or has no children,
because a nested Navigator also cannot have an empty pages list. When a child
appears the host creates the nested Navigator; removing the last child removes
that Navigator again. No fallback page is invented by the package. While the
host is empty, Back bubbles to the parent and `onBackButtonPressed` is not
called because no nested `NavigatorState` exists.

## Upgrade checklist

1. Change the dependency to `rolter: ^0.4.0`.
2. Add `routesForRootPath` to every built-in
   `RoutingInformationParser` construction.
3. Verify the returned routes encode to the intended canonical URL.
4. Ensure every `RoutesState` is created with at least one root route.
5. If custom parsers can return `[]`, normalize it in the pipeline or reject it
   before calling the delegate.
6. If custom codecs accept external non-root URLs, give malformed input an
   application-owned fallback.
7. Test `/`, initial deep links, restoration, browser Back/Forward, and empty
   nested children on the platforms the application supports.

No change is required to guards, results, history, scopes, page composition,
route identities, or valid non-empty URL data.
