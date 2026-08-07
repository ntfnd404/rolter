import '../view/item_detail_screen.dart';
import '../../shared/domain/repositories/item_repository.dart';
import '../../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/item_detail_route.dart';

/// Creates the item-detail page contribution with its narrow dependency.
AppRoutePageDefinition buildItemDetailPageDefinition({
  required ItemRepository repository,
}) => TypedAppRoutePageDefinition<ItemDetailRoute>(
  pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
    key: route.pageKey,
    name: route.name,
    child: ItemDetailScreen(repository: repository, id: route.id),
  ),
);
