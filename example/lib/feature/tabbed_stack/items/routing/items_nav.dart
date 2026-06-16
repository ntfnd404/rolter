import 'package:example/feature/tabbed_stack/shell/routing/tabs_route.dart';
import 'package:example/feature/tabbed_stack/shell/routing/tabs_route_name.dart';
import 'package:example/feature/tabbed_stack/shell/routing/tabs_tab.dart';
import 'package:example/feature/tabbed_stack/item_detail/routing/item_detail_route.dart';
import 'package:example/core/routing/app_navigator.dart';

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
