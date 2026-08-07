import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

import '../dependency/scoped_catalog_repository_scope.dart';
import '../route_data/scoped_routes.dart';
import '../view/scoped_home_screen.dart';
import '../view/scoped_item_detail_screen.dart';
import '../view/scoped_items_screen.dart';
import '../view/scoped_not_found_screen.dart';

/// External Page composition strategy for the data-only Scope routes.
Page<Object?> buildScopedPage(BuildContext context, ScopedRoute route) {
  final repository = ScopedCatalogRepositoryScope.of(context);
  final navigator = NavigatorScope.of<NavigationController<ScopedRoute>>(
    context,
  );

  return switch (route) {
    ScopedHomeRoute() => MaterialPage<Object?>(
      key: route.pageKey,
      name: route.name,
      child: ScopedHomeScreen(
        repository: repository,
        onOpenItems: () => navigator.push(const ScopedItemsRoute()),
      ),
    ),
    ScopedItemsRoute() => MaterialPage<Object?>(
      key: route.pageKey,
      name: route.name,
      child: ScopedItemsScreen(
        repository: repository,
        onOpenItem: (id) => navigator.push(ScopedItemDetailRoute(id: id)),
      ),
    ),
    ScopedItemDetailRoute(:final id) => MaterialPage<Object?>(
      key: route.pageKey,
      name: route.name,
      child: ScopedItemDetailScreen(
        repository: repository,
        id: id,
        onGoHome: () => navigator.clearAndPush(const ScopedHomeRoute()),
      ),
    ),
    ScopedNotFoundRoute() => MaterialPage<Object?>(
      key: route.pageKey,
      name: route.name,
      child: ScopedNotFoundScreen(
        onGoHome: () => navigator.clearAndPush(const ScopedHomeRoute()),
      ),
    ),
  };
}
