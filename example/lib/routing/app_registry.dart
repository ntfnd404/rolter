import 'package:example/feature/home/routing/home_route.dart';
import 'package:example/feature/home/routing/home_routes.dart';
import 'package:example/feature/items/routing/items_routes.dart';
import 'package:example/feature/mailbox/routing/mailbox_routes.dart';
import 'package:example/feature/overlays/routing/overlays_routes.dart';
import 'package:example/feature/scope/routing/scope_routes.dart';
import 'package:example/feature/session/routing/session_routes.dart';
import 'package:example/routing/app_route.dart';
import 'package:example/routing/not_found_route.dart';
import 'package:rolter/rolter.dart';

/// The app's route registry, assembled from each feature's decoder
/// contribution. This is the only place that knows every feature — the
/// composition root. Adding a feature = adding its `*Routes` map here.
final RouteRegistry<AppRoute> appRegistry = RouteRegistry<AppRoute>({
  ...homeRoutes,
  ...mailboxRoutes,
  ...itemsRoutes,
  ...overlaysRoutes,
  ...sessionRoutes,
  ...scopeRoutes,
}, fallback: NotFoundRoute.new);

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
