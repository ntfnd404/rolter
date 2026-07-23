import 'tabs_nav.dart';
import 'tabs_route_name.dart';
import 'tabs_tab.dart';
import '../view/tabs_shell.dart';
import '../../item_detail/routing/item_detail_route.dart';
import '../../items/routing/items_route.dart';
import '../../../../core/routing/app_navigator.dart';
import '../../../../core/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  /// Top of the Items nested stack when it holds a pushed detail.
  ItemDetailRoute? get _openItem {
    final top = stack.last;
    return activeTab == TabsTab.items && top is ItemDetailRoute ? top : null;
  }

  String get _title => switch (activeTab) {
    TabsTab.settings => 'Settings',
    TabsTab.items => switch (_openItem) {
      final ItemDetailRoute item => 'Item #${item.id}',
      _ => 'Items',
    },
  };

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: TabsShell(
      title: _title,
      activeTab: activeTab,
      onSelectTab: context.navigator.selectTab,
      // Cascading back: a pushed detail pops the nested stack (back to the
      // list); at the tab root, leave the Tabs section (back to Home beneath).
      onBack: () => _openItem != null
          ? context.navigator.popNestedItem()
          : context.navigator.pop(),
      itemsTab: NestedNavigatorHost<AppRoute>(
        service: context.navigator,
        path: [TabsRouteName.tabs.wire],
        active: activeTab == TabsTab.items,
        // Tab content switches instantly (no slide) — a natural tab UX, and a
        // demo of NestedNavigatorHost.transitionDelegate.
        transitionDelegate: const NoAnimationTransitionDelegate<Object?>(),
        // System back mirrors the shared AppBar's cascade.
        onBackButtonPressed: (navigator) {
          if (navigator.canPop()) {
            return navigator.maybePop();
          }
          context.navigator.pop();
          return SynchronousFuture<bool>(true);
        },
      ),
    ),
  );

  @override
  int get hashCode => Object.hash(TabsRoute, activeTab, Object.hashAll(stack));

  @override
  bool operator ==(Object other) =>
      other is TabsRoute &&
      other.activeTab == activeTab &&
      listEquals(other.stack, stack);
}
