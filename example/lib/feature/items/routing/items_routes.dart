import 'package:example/feature/items/routing/item_detail_route.dart';
import 'package:example/feature/items/routing/items_route.dart';
import 'package:example/feature/items/routing/items_route_name.dart';
import 'package:example/feature/items/routing/tabs_route.dart';
import 'package:example/feature/items/routing/tabs_tab.dart';
import 'package:example/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Items/Tabs feature decoder contribution to the app registry.
Map<String, RouteDecoder<AppRoute>> get itemsRoutes => {
  ItemsRouteName.tabs.wire: (params, children) => TabsRoute(
    activeTab: TabsTab.values.asNameMap()[params['tab']] ?? TabsTab.items,
    stack: children.isEmpty ? const [ItemsRoute()] : children,
  ),
  ItemsRouteName.items.wire: (_, _) => const ItemsRoute(),
  ItemsRouteName.item.wire: (params, _) =>
      ItemDetailRoute(int.tryParse(params['id'] ?? '') ?? 0),
};
