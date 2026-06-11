/// A hand-rolled, declarative Navigator 2.0 routing engine for Flutter with
/// a typed, URL-serializable route tree and built-in nested navigation.
///
/// The engine is screen-agnostic: it never imports application screens. An
/// app builds a catalog of typed routes on top of this barrel (route nodes,
/// a registry, and a navigator facade) and renders them via [NavigatorScope].
library;

export 'src/controller/guarded_pipeline.dart';
export 'src/controller/navigation_controller.dart';
export 'src/controller/navigation_service.dart';
export 'src/controller/route_guard.dart';
export 'src/controller/routing_delegate.dart';
export 'src/controller/routing_information_parser.dart';
export 'src/model/route_node.dart';
export 'src/model/route_registry.dart';
export 'src/model/route_tree.dart';
export 'src/model/tree_url_codec.dart';
export 'src/pages/app_page.dart';
export 'src/pages/no_animation_page.dart';
export 'src/pages/transparent_page.dart';
export 'src/state/route_state_queue.dart';
export 'src/state/routes_state.dart';
export 'src/widgets/navigator_scope.dart';
export 'src/widgets/nested_navigator_host.dart';
export 'src/widgets/route_scope.dart';
