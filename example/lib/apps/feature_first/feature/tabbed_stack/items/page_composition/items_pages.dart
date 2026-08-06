import '../view/items_screen.dart';
import '../../shared/domain/repositories/item_repository.dart';
import '../../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/items_route.dart';

/// Creates the items page contribution with its narrow repository dependency.
AppRoutePageDefinition buildItemsPageDefinition({
  required ItemRepository repository,
}) => TypedAppRoutePageDefinition<ItemsRoute>(
  pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
    key: route.pageKey,
    name: route.name,
    child: ItemsScreen(repository: repository),
  ),
);
