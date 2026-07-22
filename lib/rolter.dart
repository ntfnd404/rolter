/// A hand-rolled, declarative Navigator 2.0 routing engine for Flutter with
/// a typed, URL-serializable route tree and built-in nested navigation.
///
/// The engine is screen-agnostic: it never imports application screens, and it
/// never downcasts to a concrete `Page` type. An app builds a catalog of typed
/// routes on top of this barrel (route nodes, a registry, and a navigator
/// facade) and renders them via [NavigatorScope].
///
/// The `pages/` and `transitions/` exports are **optional batteries**
/// (`TransparentPage`, `NoAnimationPage`, `TransitionPage`,
/// `NoAnimationTransitionDelegate`) — ready-made `Page` / `TransitionDelegate`
/// implementations the engine itself never uses. An app may use all, some, or
/// none of them (returning a bare `MaterialPage`, or its own `Page`).
library;

export 'src/controller/entry_query_store.dart' show EntryQueryStore;
export 'src/controller/routing_delegate.dart' show RoutingDelegate;
export 'src/controller/routing_information_parser.dart'
    show RoutingInformationParser;
export 'src/guard/guard_result.dart' show GuardResult;
export 'src/guard/guarded_pipeline.dart' show GuardedPipeline;
export 'src/guard/nav_decision.dart' show NavDecision;
export 'src/guard/pending_location.dart' show PendingLocation;
export 'src/guard/route_guard.dart' show RouteGuard;
export 'src/guard/stream_listenable.dart' show StreamListenable;
export 'src/model/base64_route_codec.dart' show Base64RouteCodec;
export 'src/model/feature_router.dart'
    show FeatureRouter, composeFeatureRouters;
export 'src/model/keyed_route_equality.dart' show KeyedRouteEquality;
export 'src/model/route_node.dart'
    show HistoryExcluded, RouteNode, StrictHierarchy;
export 'src/model/route_registry.dart' show RouteDecoder, RouteRegistry;
export 'src/model/route_url_codec.dart' show RouteUrlCodec;
export 'src/model/tree_url_codec.dart' show TreeUrlCodec;
export 'src/navigation/navigation_controller.dart' show NavigationController;
export 'src/navigation/navigation_service.dart' show NavigationService;
export 'src/pages/no_animation_page.dart' show NoAnimationPage;
export 'src/pages/transition_page.dart' show TransitionPage;
export 'src/pages/transparent_page.dart' show TransparentPage;
export 'src/state/nav_observer.dart' show NavObserver, NavTransition;
export 'src/state/navigation_history.dart' show NavigationHistory;
export 'src/state/routes_state.dart' show ApplyPipeline, RoutesState;
export 'src/transitions/no_animation_transition_delegate.dart'
    show NoAnimationTransitionDelegate;
export 'src/widgets/navigator_scope.dart' show NavigatorScope;
export 'src/widgets/nested_navigator_host.dart' show NestedNavigatorHost;
export 'src/widgets/route_scope.dart' show RouteScope;
