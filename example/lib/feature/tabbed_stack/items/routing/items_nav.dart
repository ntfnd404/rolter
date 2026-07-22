import '../../shell/routing/tabs_route.dart';
import '../../shell/routing/tabs_route_name.dart';
import '../../shell/routing/tabs_tab.dart';
import '../../item_detail/routing/item_detail_route.dart';
import '../../../../core/routing/app_navigator.dart';

/// Items-list navigation sugar: open an item, pushing its detail onto the Tabs
/// shell's Items nested stack.
extension ItemsNav on AppNavigator {
  void openItem(int id) => mutateAt(
        [TabsRouteName.tabs.wire],
        (node) => switch (node) {
          TabsRoute(:final stack) => TabsRoute(
              activeTab: TabsTab.items,
              stack: [...stack, ItemDetailRoute(id)],
            ),
          _ => node,
        },
      );
}
