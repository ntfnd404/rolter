import 'tabs_route.dart';
import 'tabs_route_name.dart';
import 'tabs_tab.dart';
import '../../items/routing/items_route.dart';
import '../../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Tabs shell decoder contribution to the app registry. Decodes the `tabs`
/// shell node; its children (`items`/`item`) are decoded by the sub-features.
Map<String, RouteDecoder<AppRoute>> get tabsRoutes => {
      TabsRouteName.tabs.wire: (params, children) => TabsRoute(
            activeTab:
                TabsTab.values.asNameMap()[params['tab']] ?? TabsTab.items,
            stack: children.isEmpty ? const [ItemsRoute()] : children,
          ),
    };
