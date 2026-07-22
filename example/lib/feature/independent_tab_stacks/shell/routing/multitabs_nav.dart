import 'mt_tab.dart';
import 'multitabs_route.dart';
import '../../detail/routing/mt_detail_route.dart';
import '../../../../core/routing/app_navigator.dart';

/// Multi-tab feature navigation sugar, added to the shared [AppNavigator].
extension MultiTabsNav on AppNavigator {
  /// Opens the multi-tab section.
  void toMultiTabs() => push(MultiTabsRoute());

  /// Switches the active tab, preserving every tab's nested stack.
  void selectMtTab(MtTab tab) => mutateAt(['multitabs'], (node) {
        final shell = node as MultiTabsRoute;

        return MultiTabsRoute(activeTab: tab, tabs: shell.tabs);
      });

  /// Pushes a detail into [tab]'s own nested stack.
  void openMtItem(MtTab tab, int id) => mutateAt(
        ['multitabs', tab.wire],
        (node) => node.withChildren([...node.children, MtDetailRoute(tab, id)]),
      );

  /// Pops the top of [tab]'s nested stack (if it has more than the root list).
  void popMtItem(MtTab tab) => mutateAt(['multitabs', tab.wire], (node) {
        final children = node.children;

        return children.length > 1
            ? node.withChildren(children.sublist(0, children.length - 1))
            : node;
      });
}
