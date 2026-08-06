import '../routing/multitabs_route.dart';
import '../view/mt_tab_presentation.dart';
import '../view/multitabs_shell.dart';
import '../../detail/routing/mt_detail_route.dart';
import '../../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/mt_tab_route.dart';

extension _MultiTabsRoutePresentation on MultiTabsRoute {
  MtTabRoute get _activeTab =>
      tabs.cast<MtTabRoute>().firstWhere((tab) => tab.tab == activeTab);

  String get _title {
    final top = _activeTab.stack.last;

    return top is MtDetailRoute ? 'Item #${top.id}' : activeTab.label;
  }
}

/// Page contribution for the shell with independent per-tab stacks.
final AppRoutePageDefinition multiTabsPageDefinition =
    TypedAppRoutePageDefinition<MultiTabsRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: MultiTabsShell(
          activeTab: route.activeTab,
          title: route._title,
          activeTabCanPop: route._activeTab.stack.length > 1,
          pageBuilder: nestedPageBuilder,
        ),
      ),
    );
