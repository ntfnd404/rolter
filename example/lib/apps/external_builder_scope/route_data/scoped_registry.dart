import 'package:rolter/rolter.dart';

import 'scoped_routes.dart';

ScopedRoute _decodeItem(
  Map<String, String> parameters,
  List<ScopedRoute> children,
) {
  final id = int.tryParse(parameters['id'] ?? '');
  return id == null || id < 1
      ? const ScopedNotFoundRoute()
      : ScopedItemDetailRoute(id: id);
}

/// Decoder catalog for the data-only Scope example routes.
final RouteRegistry<ScopedRoute> scopedRouteRegistry =
    RouteRegistry<ScopedRoute>({
      'home': (parameters, children) => const ScopedHomeRoute(),
      'items': (parameters, children) => const ScopedItemsRoute(),
      'item': _decodeItem,
    }, fallback: (uri) => const ScopedNotFoundRoute());
