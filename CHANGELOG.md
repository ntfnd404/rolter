## 0.0.1

Initial release.

- Declarative, tree-based route state (`RouteNode`, `RouteTree`) with typed,
  URL-serializable routes (`RouteRegistry`, `TreeUrlCodec`).
- Navigator 2.0 wiring: `RoutingDelegate`, `RoutingInformationParser`,
  `NavigationService` and `NavigationController`.
- Built-in nested navigation via `NavigatorScope` and `NestedNavigatorHost`.
- Async-safe navigation through `RouteStateQueue` and route guards
  (`RouteGuard`, `GuardedPipeline`).
- Per-route dependency scoping via `RouteScope`.
- Custom `Page` types: `AppPage`, `TransparentPage`, `NoAnimationPage`.
- `example/` app demonstrating the engine end to end.
