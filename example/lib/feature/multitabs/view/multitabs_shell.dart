import 'package:example/feature/multitabs/routing/multitabs_nav.dart';
import 'package:example/feature/multitabs/routing/multitabs_routes.dart';
import 'package:example/routing/app_navigator.dart';
import 'package:example/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// One shared AppBar + a `NavigationBar` over two always-alive tabs. Each tab is
/// its own `NestedNavigatorHost`, so both keep their own back stack at once.
class MultiTabsShell extends StatelessWidget {
  const MultiTabsShell({
    required this.activeTab,
    required this.title,
    required this.activeTabCanPop,
    super.key,
  });

  final MtTab activeTab;
  final String title;
  final bool activeTabCanPop;

  @override
  Widget build(BuildContext context) {
    final nav = context.navigator;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        // Cascading back: pop the active tab's detail if any, else leave.
        leading: BackButton(
          onPressed: () =>
              activeTabCanPop ? nav.popMtItem(activeTab) : nav.pop(),
        ),
      ),
      body: IndexedStack(
        index: activeTab.index,
        children: [
          for (final tab in MtTab.values)
            NestedNavigatorHost<AppRoute>(
              service: nav,
              path: ['multitabs', tab.wire],
              active: tab == activeTab,
              transitionDelegate:
                  const NoAnimationTransitionDelegate<Object?>(),
              onBackButtonPressed: (navigator) {
                if (navigator.canPop()) {
                  return navigator.maybePop();
                }
                nav.pop();

                return SynchronousFuture<bool>(true);
              },
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeTab.index,
        onDestinationSelected: (i) => nav.selectMtTab(MtTab.values[i]),
        destinations: [
          for (final tab in MtTab.values)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label),
        ],
      ),
    );
  }
}
