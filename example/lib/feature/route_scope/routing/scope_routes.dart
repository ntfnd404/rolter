import 'scope_route.dart';
import 'scope_route_name.dart';
import '../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Scope feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get scopeRoutes => {
  ScopeRouteName.scope.wire: (_, _) => const ScopeRoute(),
};
