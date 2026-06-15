import 'package:example/feature/modules/view/module_screens.dart';
import 'package:example/routing/app_route.dart';
import 'package:example/routing/not_found_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Full sub-router demo (E8): each module owns its OWN `RouteRegistry`, so both
/// `shop` and `blog` define a `detail` route without colliding. The modules are
/// mounted into the app registry via `FeatureRouter` (see `app_registry.dart`).
/// (Page keys stay globally unique — prefixed by module — even though the URL
/// *names* are isolated.)
enum DemoModule {
  shop('shop', 'Shop'),
  blog('blog', 'Blog');

  const DemoModule(this.wire, this.label);

  final String wire;
  final String label;

  /// The sibling module (used by the demo's cross-link).
  DemoModule get other => this == shop ? blog : shop;
}

/// Mount shell for a module; hosts the module's nested stack.
final class ModuleShellRoute extends AppRoute {
  ModuleShellRoute(this.module, {List<AppRoute>? stack})
    : stack = (stack == null || stack.isEmpty)
          ? [ModuleHomeRoute(module)]
          : stack;

  final DemoModule module;
  final List<AppRoute> stack;

  @override
  List<AppRoute> get children => stack;

  @override
  LocalKey get pageKey => ValueKey('module:${module.wire}');

  @override
  String get name => module.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  AppRoute withChildren(List<RouteNode> children) =>
      ModuleShellRoute(module, stack: children.cast<AppRoute>());

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: ModuleShell(module: module),
  );

  @override
  int get hashCode =>
      Object.hash(ModuleShellRoute, module, Object.hashAll(stack));

  @override
  bool operator ==(Object other) =>
      other is ModuleShellRoute &&
      other.module == module &&
      listEquals(other.stack, stack);
}

/// A module's home (route name `home`, local to the module's registry).
final class ModuleHomeRoute extends AppRoute {
  const ModuleHomeRoute(this.module);

  final DemoModule module;

  @override
  LocalKey get pageKey => ValueKey('${module.wire}/home');

  @override
  String get name => 'home';

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: ModuleHomeScreen(module: module),
  );
}

/// A module's detail (route name `detail`, local to the module's registry — both
/// modules reuse the name without colliding).
final class ModuleDetailRoute extends AppRoute {
  const ModuleDetailRoute(this.module, this.id);

  final DemoModule module;
  final int id;

  @override
  LocalKey get pageKey => ValueKey('${module.wire}/detail:$id');

  @override
  String get name => 'detail';

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: ModuleDetailScreen(module: module, id: id),
  );
}

RouteRegistry<AppRoute> _moduleRegistry(DemoModule module) => RouteRegistry({
  'home': (_, _) => ModuleHomeRoute(module),
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
