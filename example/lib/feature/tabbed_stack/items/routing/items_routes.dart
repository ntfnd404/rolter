import 'items_route.dart';
import 'items_route_name.dart';
import '../../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Items (list) decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get itemsRoutes => {
  ItemsRouteName.items.wire: (_, _) => const ItemsRoute(),
};
