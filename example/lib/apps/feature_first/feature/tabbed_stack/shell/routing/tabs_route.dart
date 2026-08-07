import 'tabs_route_name.dart';
import 'tabs_tab.dart';
import '../../items/routing/items_route.dart';
import '../../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';

/// Tabbed shell with one shared AppBar over both tabs and the Items nested
/// stack. [stack] is the Items tab's nested back stack (the children of `tabs`);
/// [pageKey] is stable so `IndexedStack` keeps each tab's state.
///
/// Lives in the Tabs group's `common/`: it composes the independent `items`,
/// `item_detail`, and `settings` sub-features into one tabbed section.
final class TabsRoute extends AppRoute {
  const TabsRoute({
    this.activeTab = TabsTab.items,
    this.stack = const [ItemsRoute()],
  });

  final TabsTab activeTab;
  final List<AppRoute> stack;

  @override
  List<AppRoute> get children => stack;

  @override
  LocalKey get pageKey => const ValueKey('tabs');

  @override
  String get name => TabsRouteName.tabs.wire;

  @override
  Map<String, String> toParams() => {'tab': activeTab.name};

  @override
  AppRoute withChildren(List<RouteNode> children) =>
      TabsRoute(activeTab: activeTab, stack: children.cast<AppRoute>());

  @override
  int get hashCode => Object.hash(TabsRoute, activeTab, Object.hashAll(stack));

  @override
  bool operator ==(Object other) =>
      other is TabsRoute &&
      other.activeTab == activeTab &&
      listEquals(other.stack, stack);
}
