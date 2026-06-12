## 0.0.1

Initial release.

- Declarative, tree-based route state (`RouteNode` + pure tree operations) with
  typed, URL-serializable routes (`RouteRegistry`, `TreeUrlCodec`).
- Navigator 2.0 wiring: `RoutingDelegate`, `RoutingInformationParser`,
  `NavigationService` and `NavigationController`.
- Built-in nested navigation via `NavigatorScope` and `NestedNavigatorHost`
  (path-addressed, with an optional `transitionDelegate` and a single
  back-button override hook).
- Async-safe navigation through `RouteStateQueue` and route guards
  (`RouteGuard`, `GuardedPipeline`).
- Result-returning navigation: `pushForResult` / `popWith` (e.g. pickers and
  dialog-as-route that return a value).
- Per-route dependency scoping via `RouteScope`.
- Custom `Page` types: `TransparentPage`, `NoAnimationPage`, and `TransitionPage`
  (bespoke transitions without a `Route` subclass), plus a
  `NoAnimationTransitionDelegate` for animation-free nested stacks.
- `example/` app demonstrating the engine end to end.
