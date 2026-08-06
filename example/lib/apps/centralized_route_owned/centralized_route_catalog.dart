import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

import '../../common/ui/demo_item_view_data.dart';
import 'view/centralized_detail_screen.dart';
import 'view/centralized_error_screen.dart';
import 'view/centralized_home_screen.dart';
import 'view/centralized_item_detail_screen.dart';
import 'view/centralized_items_screen.dart';

const List<DemoItemViewData> _centralizedItems = [
  DemoItemViewData(
    id: 1,
    title: 'Item #1',
    description: 'The first demo item.',
  ),
  DemoItemViewData(
    id: 2,
    title: 'Item #2',
    description: 'The second demo item.',
  ),
  DemoItemViewData(
    id: 3,
    title: 'Item #3',
    description: 'The third demo item.',
  ),
];

/// Complete route family for the centralized route-owned application.
sealed class CentralizedRoute with KeyedRouteEquality implements PageRouteNode {
  const CentralizedRoute();

  @override
  List<RouteNode> get children => const [];

  @override
  CentralizedRoute withChildren(List<RouteNode> children) => this;

  NavigationController<CentralizedRoute> navigator(BuildContext context) =>
      NavigatorScope.of<NavigationController<CentralizedRoute>>(context);
}

/// Home destination containing the common flow and the original Detail demo.
final class CentralizedHomeRoute extends CentralizedRoute {
  const CentralizedHomeRoute();

  @override
  String get name => 'home';

  @override
  LocalKey get pageKey => const ValueKey<String>('centralized-home');

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage<Object?>(
    key: pageKey,
    name: name,
    child: CentralizedHomeScreen(
      onOpenItems: () => navigator(context).push(const CentralizedItemsRoute()),
      onOpenDetail: () =>
          navigator(context).push(const CentralizedDetailRoute(id: 42)),
    ),
  );
}

/// Item-list destination in the common comparison flow.
final class CentralizedItemsRoute extends CentralizedRoute {
  const CentralizedItemsRoute();

  @override
  String get name => 'items';

  @override
  LocalKey get pageKey => const ValueKey<String>('centralized-items');

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage<Object?>(
    key: pageKey,
    name: name,
    child: CentralizedItemsScreen(
      items: _centralizedItems,
      onOpenItem: (id) =>
          navigator(context).push(CentralizedItemDetailRoute(id: id)),
    ),
  );
}

/// Item-detail destination whose identity is carried by [id].
final class CentralizedItemDetailRoute extends CentralizedRoute {
  const CentralizedItemDetailRoute({required this.id});

  final int id;

  @override
  String get name => 'item';

  @override
  LocalKey get pageKey => ValueKey<String>('centralized-item:$id');

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  Page<Object?> buildPage(BuildContext context) {
    final item = _centralizedItems.where((candidate) => candidate.id == id);
    return MaterialPage<Object?>(
      key: pageKey,
      name: name,
      child: item.isEmpty
          ? CentralizedErrorScreen(
              message: 'The requested demo item does not exist.',
              onGoHome: () =>
                  navigator(context).clearAndPush(const CentralizedHomeRoute()),
            )
          : CentralizedItemDetailScreen(item: item.single),
    );
  }
}

/// Original standalone Detail destination retained for comparison coverage.
final class CentralizedDetailRoute extends CentralizedRoute {
  const CentralizedDetailRoute({required this.id});

  final int id;

  @override
  String get name => 'detail';

  @override
  LocalKey get pageKey => ValueKey<String>('centralized-detail:$id');

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage<Object?>(
    key: pageKey,
    name: name,
    child: CentralizedDetailScreen(id: id),
  );
}

/// Safe destination for a malformed `detail` location.
final class CentralizedInvalidDetailRoute extends CentralizedRoute {
  const CentralizedInvalidDetailRoute();

  @override
  String get name => 'detail';

  @override
  LocalKey get pageKey => const ValueKey<String>('centralized-invalid-detail');

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) => _errorPage(
    context,
    key: pageKey,
    name: name,
    message: 'A positive detail id is required.',
  );
}

/// Safe destination for a malformed `item` location.
final class CentralizedInvalidItemRoute extends CentralizedRoute {
  const CentralizedInvalidItemRoute();

  @override
  String get name => 'item';

  @override
  LocalKey get pageKey => const ValueKey<String>('centralized-invalid-item');

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) => _errorPage(
    context,
    key: pageKey,
    name: name,
    message: 'A positive item id is required.',
  );
}

/// Safe fallback for an unknown URL.
final class CentralizedNotFoundRoute extends CentralizedRoute
    implements HistoryExcluded {
  const CentralizedNotFoundRoute(this.attempted);

  final Uri attempted;

  @override
  String get name => 'not-found';

  @override
  LocalKey get pageKey => ValueKey<String>('centralized-not-found:$attempted');

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) => _errorPage(
    context,
    key: pageKey,
    name: name,
    message: 'No centralized route matches this location.',
  );
}

Page<Object?> _errorPage(
  BuildContext context, {
  required LocalKey key,
  required String name,
  required String message,
}) => MaterialPage<Object?>(
  key: key,
  name: name,
  child: CentralizedErrorScreen(
    message: message,
    onGoHome: () => NavigatorScope.of<NavigationController<CentralizedRoute>>(
      context,
    ).clearAndPush(const CentralizedHomeRoute()),
  ),
);

/// Decodes the original Detail route without substituting another Home route.
CentralizedRoute decodeCentralizedDetail(
  Map<String, String> parameters,
  List<CentralizedRoute> children,
) {
  final id = int.tryParse(parameters['id'] ?? '');
  return id == null || id < 1
      ? const CentralizedInvalidDetailRoute()
      : CentralizedDetailRoute(id: id);
}

CentralizedRoute _decodeCentralizedItem(
  Map<String, String> parameters,
  List<CentralizedRoute> children,
) {
  final id = int.tryParse(parameters['id'] ?? '');
  return id == null || id < 1
      ? const CentralizedInvalidItemRoute()
      : CentralizedItemDetailRoute(id: id);
}

/// Single decoder map for the centralized architecture.
final RouteRegistry<CentralizedRoute> centralizedRouteRegistry =
    RouteRegistry<CentralizedRoute>({
      'home': (parameters, children) => const CentralizedHomeRoute(),
      'items': (parameters, children) => const CentralizedItemsRoute(),
      'item': _decodeCentralizedItem,
      'detail': decodeCentralizedDetail,
    }, fallback: CentralizedNotFoundRoute.new);
