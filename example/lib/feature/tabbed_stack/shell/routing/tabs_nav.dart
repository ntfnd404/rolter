import 'tabs_route.dart';
import 'tabs_route_name.dart';
import 'tabs_tab.dart';
import '../../../../core/routing/app_navigator.dart';

/// Tabs-shell navigation sugar, added to the shared [AppNavigator]. Owns the
/// shell-level moves (enter the section, switch tab, pop the nested detail);
/// the per-list action (`openItem`) lives with the `items` sub-feature.
extension TabsNav on AppNavigator {
  void toTabs() => push(const TabsRoute());

  void selectTab(TabsTab tab) => mutateAt(
        [TabsRouteName.tabs.wire],
        (node) => switch (node) {
          TabsRoute(:final stack) => TabsRoute(activeTab: tab, stack: stack),
          _ => node,
        },
      );

  void popNestedItem() => mutateAt(
        [TabsRouteName.tabs.wire],
        (node) => switch (node) {
          TabsRoute(:final stack) when stack.length > 1 => TabsRoute(
              activeTab: TabsTab.items,
              stack: stack.sublist(0, stack.length - 1),
            ),
          _ => node,
        },
      );
}
