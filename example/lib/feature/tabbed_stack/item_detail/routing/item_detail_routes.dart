import 'package:example/feature/tabbed_stack/item_detail/routing/item_detail_route.dart';
import 'package:example/feature/tabbed_stack/item_detail/routing/item_detail_route_name.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Item-detail decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get itemDetailRoutes => {
  ItemDetailRouteName.item.wire: (params, _) =>
      ItemDetailRoute(int.tryParse(params['id'] ?? '') ?? 0),
};
