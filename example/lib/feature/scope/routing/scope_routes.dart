import 'package:example/feature/scope/routing/scope_route.dart';
import 'package:example/feature/scope/routing/scope_route_name.dart';
import 'package:example/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Scope feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get scopeRoutes => {
  ScopeRouteName.scope.wire: (_, _) => const ScopeRoute(),
};
