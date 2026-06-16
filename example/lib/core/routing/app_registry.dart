import 'package:example/feature/animated/routing/animated_routes.dart';
import 'package:example/feature/confirm/routing/confirm_routes.dart';
import 'package:example/feature/detail/routing/detail_routes.dart';
import 'package:example/feature/editor/routing/editor_routes.dart';
import 'package:example/feature/home/routing/home_route.dart';
import 'package:example/feature/home/routing/home_routes.dart';
import 'package:example/feature/mailbox/routing/mailbox_routes.dart';
import 'package:example/feature/sub_routers/shell/routing/modules_routes.dart';
import 'package:example/feature/independent_tab_stacks/shell/routing/multitabs_routes.dart';
import 'package:example/feature/independent_tab_stacks/detail/routing/mt_detail_routes.dart';
import 'package:example/feature/independent_tab_stacks/list/routing/mt_list_routes.dart';
import 'package:example/feature/not_found/routing/not_found_route.dart';
import 'package:example/feature/picker/routing/picker_routes.dart';
import 'package:example/feature/route_scope/routing/scope_routes.dart';
import 'package:example/feature/session/routing/session_routes.dart';
import 'package:example/feature/tabbed_stack/shell/routing/tabs_routes.dart';
import 'package:example/feature/tabbed_stack/item_detail/routing/item_detail_routes.dart';
import 'package:example/feature/tabbed_stack/items/routing/items_routes.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// The app's route registry, assembled from each feature's decoder
/// contribution. This is the only place that knows every feature — the
/// composition root. Flat features contribute their `*Routes` decoder maps;
/// the `modules` feature mounts its own sub-registries (namespace isolation)
/// via `composeFeatureRouters`.
final RouteRegistry<AppRoute> appRegistry = composeFeatureRouters<AppRoute>(
  fallback: NotFoundRoute.new,
  decoders: {
    ...homeRoutes,
    ...detailRoutes,
    ...animatedRoutes,
    ...mailboxRoutes,
    ...tabsRoutes,
    ...itemsRoutes,
    ...itemDetailRoutes,
    ...pickerRoutes,
    ...confirmRoutes,
    ...sessionRoutes,
    ...scopeRoutes,
    ...editorRoutes,
    ...multiTabsRoutes,
    ...mtListRoutes,
    ...mtDetailRoutes,
  },
  features: moduleFeatures,
);

/// Ensures Home is always the root, so deep links land beneath it.
List<AppRoute> normalizeAppStack(List<AppRoute> stack) {
  if (stack.isEmpty) {
    return const [HomeRoute()];
  }
  if (stack.first is HomeRoute) {
    return stack;
  }
  return [const HomeRoute(), ...stack];
}
