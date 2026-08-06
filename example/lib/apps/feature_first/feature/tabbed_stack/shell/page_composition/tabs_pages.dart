import '../routing/tabs_nav.dart';
import '../routing/tabs_route.dart';
import '../routing/tabs_route_name.dart';
import '../routing/tabs_tab.dart';
import '../view/tabs_shell.dart';
import '../../item_detail/routing/item_detail_route.dart';
import '../../../../navigation/app_navigator.dart';
import '../../../../navigation/app_route.dart';
import '../../../../composition/app_route_page_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

extension _TabsRoutePresentation on TabsRoute {
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
}

/// Page contribution for the shared tab shell and its nested items navigator.
final AppRoutePageDefinition
tabsPageDefinition = TypedAppRoutePageDefinition<TabsRoute>(
  pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
    key: route.pageKey,
    name: route.name,
    child: TabsShell(
      title: route._title,
      activeTab: route.activeTab,
      onSelectTab: context.navigator.selectTab,
      // Cascading back: a pushed detail pops the nested stack (back to the
      // list); at the tab root, leave the Tabs section (back to Home beneath).
      onBack: () => route._openItem != null
          ? context.navigator.popNestedItem()
          : context.navigator.pop(),
      itemsTab: NestedNavigatorHost<AppRoute>(
        service: context.navigator,
        path: [TabsRouteName.tabs.wire],
        active: route.activeTab == TabsTab.items,
        pageBuilder: nestedPageBuilder,
        transitionDelegate: const NoAnimationTransitionDelegate<Object?>(),
        onBackButtonPressed: (navigator) {
          if (navigator.canPop()) {
            return navigator.maybePop();
          }
          context.navigator.pop();
          return SynchronousFuture<bool>(true);
        },
      ),
    ),
  ),
);
