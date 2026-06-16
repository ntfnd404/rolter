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

export 'src/controller/entry_query_store.dart';
export 'src/controller/routing_delegate.dart';
export 'src/controller/routing_information_parser.dart';
export 'src/guard/guarded_pipeline.dart';
export 'src/guard/pending_location.dart';
export 'src/guard/route_guard.dart';
export 'src/guard/stream_listenable.dart';
export 'src/model/base64_route_codec.dart';
export 'src/model/feature_router.dart';
export 'src/model/keyed_route_equality.dart';
export 'src/model/route_node.dart';
export 'src/model/route_registry.dart';
export 'src/model/route_tree.dart';
export 'src/model/route_url_codec.dart';
export 'src/model/tree_url_codec.dart';
export 'src/navigation/navigation_controller.dart';
export 'src/navigation/navigation_service.dart';
export 'src/pages/no_animation_page.dart';
export 'src/pages/transition_page.dart';
export 'src/pages/transparent_page.dart';
export 'src/state/nav_observer.dart';
export 'src/state/navigation_history.dart';
export 'src/state/navigation_queue.dart' show NavigationQueue;
export 'src/state/routes_state.dart';
export 'src/transitions/no_animation_transition_delegate.dart';
export 'src/widgets/navigator_scope.dart';
export 'src/widgets/nested_navigator_host.dart';
export 'src/widgets/route_scope.dart';
export 'src/widgets/scope_access.dart';
