import 'demo_module.dart';
import 'module_shell_route.dart';
import '../../detail/routing/module_detail_route.dart';
import '../../home/routing/module_home_route.dart';
import '../../../not_found/routing/not_found_route.dart';
import '../../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Per-module sub-registry: each module decodes its OWN `home`/`detail` names,
/// composing the `home` and `detail` sub-features in an isolated namespace.
RouteRegistry<AppRoute> _moduleRegistry(DemoModule module) => RouteRegistry({
      'home': (_, unusedChildren) => ModuleHomeRoute(module),
      'detail': (params, _) =>
          ModuleDetailRoute(module, int.parse(params['id'] ?? '0')),
    }, fallback: NotFoundRoute.new);

/// Feature routers to mount in the app registry — one isolated namespace each.
final List<FeatureRouter<AppRoute>> moduleFeatures = [
  for (final module in DemoModule.values)
    FeatureRouter<AppRoute>(
      name: module.wire,
      mountDecoder: (_, children) =>
          ModuleShellRoute(module, stack: children.cast<AppRoute>()),
      registry: _moduleRegistry(module),
    ),
];
