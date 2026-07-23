import 'mt_tab.dart';
import 'mt_tab_route.dart';
import '../view/mt_tab_presentation.dart';
import '../view/multitabs_shell.dart';
import '../../detail/routing/mt_detail_route.dart';
import '../../../../core/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Multi-tab demo with **independent per-tab stacks**.
///
/// A single `RouteNode` holds one `children` list, so each tab is modelled as
/// its own child node ([MtTabRoute]) whose `children` are *that tab's* nested
/// back stack. The shell keeps all tabs alive in an `IndexedStack`. Because
/// every tab's stack is part of the tree, the whole thing round-trips through
/// one URL. Implements [StrictHierarchy] so a mis-wired child is rejected
/// before commit.
///
/// Lives in the multitabs group's `common/`: it composes the per-tab `list`
/// and `detail` sub-features into one tabbed section.
final class MultiTabsRoute extends AppRoute implements StrictHierarchy {
  MultiTabsRoute({this.activeTab = MtTab.a, List<AppRoute>? tabs})
    : tabs = tabs ?? [MtTabRoute(MtTab.a), MtTabRoute(MtTab.b)];

  final MtTab activeTab;
  final List<AppRoute> tabs;

  @override
  List<AppRoute> get children => tabs;

  @override
  bool allowsChild(RouteNode child) => child is MtTabRoute;

  @override
  LocalKey get pageKey => const ValueKey('multitabs');

  @override
  String get name => 'multitabs';

  @override
  Map<String, String> toParams() => {'tab': activeTab.wire};

  @override
  AppRoute withChildren(List<RouteNode> children) =>
      MultiTabsRoute(activeTab: activeTab, tabs: children.cast<AppRoute>());

  /// The active tab's container (used to compute the title/back affordance).
  MtTabRoute get _activeTab =>
      tabs.cast<MtTabRoute>().firstWhere((t) => t.tab == activeTab);

  String get _title {
    final top = _activeTab.stack.last;

    return top is MtDetailRoute ? 'Item #${top.id}' : activeTab.label;
  }

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: MultiTabsShell(
      activeTab: activeTab,
      title: _title,
      // Back leaves the section unless the active tab has a pushed detail.
      activeTabCanPop: _activeTab.stack.length > 1,
    ),
  );

  @override
  int get hashCode =>
      Object.hash(MultiTabsRoute, activeTab, Object.hashAll(tabs));

  @override
  bool operator ==(Object other) =>
      other is MultiTabsRoute &&
      other.activeTab == activeTab &&
      listEquals(other.tabs, tabs);
}
