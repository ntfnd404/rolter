import 'package:example/feature/multitabs/view/mt_detail_screen.dart';
import 'package:example/feature/multitabs/view/mt_list_screen.dart';
import 'package:example/feature/multitabs/view/multitabs_shell.dart';
import 'package:example/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Multi-tab demo with **independent per-tab stacks**.
///
/// A single `RouteNode` holds one `children` list, so each tab is modelled as
/// its own child node ([MtTabRoute]) whose `children` are *that tab's* nested
/// back stack. The shell keeps all tabs alive in an `IndexedStack`, switching
/// which one is active. Because every tab's stack is part of the tree, the whole
/// thing round-trips through one URL, e.g.:
///
///   /multitabs~tab=mt-a/.mt-a/..mt-detail~id=1&tab=mt-a/.mt-b/..mt-detail~id=7&tab=mt-b
///
/// (the engine already supports this via nesting; this feature just shows it).

/// Which tab of the multi-tab shell.
enum MtTab {
  a('mt-a', 'Inbox', Icons.inbox_outlined),
  b('mt-b', 'Archive', Icons.archive_outlined);

  const MtTab(this.wire, this.label, this.icon);

  final String wire;
  final String label;
  final IconData icon;

  static MtTab fromWire(String? wire) =>
      values.firstWhere((t) => t.wire == wire, orElse: () => MtTab.a);
}

/// Decoder contributions for the multi-tab feature.
Map<String, RouteDecoder<AppRoute>> get multiTabsRoutes => {
  'multitabs': (params, children) => MultiTabsRoute(
    activeTab: MtTab.fromWire(params['tab']),
    tabs: children.isEmpty ? null : children.cast<AppRoute>(),
  ),
  MtTab.a.wire: (_, children) =>
      MtTabRoute(MtTab.a, stack: children.cast<AppRoute>()),
  MtTab.b.wire: (_, children) =>
      MtTabRoute(MtTab.b, stack: children.cast<AppRoute>()),
  'mt-list': (params, _) => MtListRoute(MtTab.fromWire(params['tab'])),
  'mt-detail': (params, _) =>
      MtDetailRoute(MtTab.fromWire(params['tab']), int.parse(params['id']!)),
};

/// The shell node: `activeTab` + one child node per tab (each holding its own
/// nested stack). Implements [StrictHierarchy] to declare that its children must
/// be tab containers — a mis-wired child trips a debug assert.
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

/// One tab's container. Its [children] are that tab's nested back stack; it is
/// never rendered as a page itself (the shell hosts its children).
final class MtTabRoute extends AppRoute {
  MtTabRoute(this.tab, {List<AppRoute>? stack})
    : stack = stack ?? [MtListRoute(tab)];

  final MtTab tab;
  final List<AppRoute> stack;

  @override
  List<AppRoute> get children => stack;

  @override
  LocalKey get pageKey => ValueKey('mt-tab:${tab.wire}');

  @override
  String get name => tab.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  AppRoute withChildren(List<RouteNode> children) =>
      MtTabRoute(tab, stack: children.cast<AppRoute>());

  @override
  Page<Object?> buildPage(BuildContext context) =>
      MaterialPage(key: pageKey, child: const SizedBox.shrink());

  @override
  int get hashCode => Object.hash(MtTabRoute, tab, Object.hashAll(stack));

  @override
  bool operator ==(Object other) =>
      other is MtTabRoute && other.tab == tab && listEquals(other.stack, stack);
}

/// The list at the root of a tab's stack.
final class MtListRoute extends AppRoute {
  const MtListRoute(this.tab);

  final MtTab tab;

  @override
  LocalKey get pageKey => ValueKey('mt-list:${tab.wire}');

  @override
  String get name => 'mt-list';

  @override
  Map<String, String> toParams() => {'tab': tab.wire};

  @override
  Page<Object?> buildPage(BuildContext context) =>
      MaterialPage(key: pageKey, child: MtListScreen(tab: tab));
}

/// A detail pushed into a tab's stack.
final class MtDetailRoute extends AppRoute {
  const MtDetailRoute(this.tab, this.id);

  final MtTab tab;
  final int id;

  @override
  LocalKey get pageKey => ValueKey('mt-detail:${tab.wire}:$id');

  @override
  String get name => 'mt-detail';

  @override
  Map<String, String> toParams() => {'tab': tab.wire, 'id': '$id'};

  @override
  Page<Object?> buildPage(BuildContext context) =>
      MaterialPage(key: pageKey, child: MtDetailScreen(tab: tab, id: id));
}
