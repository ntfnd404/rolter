import 'mt_tab.dart';
import 'mt_tab_route.dart';
import 'multitabs_route.dart';
import '../../../../core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Multi-tab shell decoder contribution: the shell node and its per-tab
/// containers. The tab roots/details are decoded by the `list`/`detail`
/// sub-features.
Map<String, RouteDecoder<AppRoute>> get multiTabsRoutes => {
  'multitabs': (params, children) => MultiTabsRoute(
    activeTab: MtTab.fromWire(params['tab']),
    tabs: children.isEmpty ? null : children.cast<AppRoute>(),
  ),
  MtTab.a.wire: (_, children) =>
      MtTabRoute(MtTab.a, stack: children.cast<AppRoute>()),
  MtTab.b.wire: (_, children) =>
      MtTabRoute(MtTab.b, stack: children.cast<AppRoute>()),
};
