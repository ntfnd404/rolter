import 'package:example/feature/items/routing/item_detail_route.dart';
import 'package:example/feature/items/routing/items_route_name.dart';
import 'package:example/feature/items/routing/tabs_route.dart';
import 'package:example/feature/items/routing/tabs_tab.dart';
import 'package:example/routing/app_navigator.dart';

/// Items/Tabs feature navigation sugar, added to the shared [AppNavigator].
extension ItemsNav on AppNavigator {
  void toTabs() => push(const TabsRoute());

  void selectTab(TabsTab tab) => mutateAt(
    [ItemsRouteName.tabs.wire],
    (node) => switch (node) {
      TabsRoute(:final stack) => TabsRoute(activeTab: tab, stack: stack),
      _ => node,
    },
  );

  void openItem(int id) => mutateAt(
    [ItemsRouteName.tabs.wire],
    (node) => switch (node) {
      TabsRoute(:final stack) => TabsRoute(
        activeTab: TabsTab.items,
        stack: [...stack, ItemDetailRoute(id)],
      ),
      _ => node,
    },
  );

  void popNestedItem() => mutateAt(
    [ItemsRouteName.tabs.wire],
    (node) => switch (node) {
      TabsRoute(:final stack) when stack.length > 1 => TabsRoute(
        activeTab: TabsTab.items,
        stack: stack.sublist(0, stack.length - 1),
      ),
      _ => node,
    },
  );
}
