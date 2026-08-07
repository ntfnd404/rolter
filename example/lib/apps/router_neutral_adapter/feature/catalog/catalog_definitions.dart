import 'package:flutter/material.dart';

import '../../application/app_destination.dart';
import '../../application/app_route_definition.dart';
import 'catalog_repository.dart';
import 'item_detail_destination.dart';
import 'item_detail_screen.dart';
import 'items_destination.dart';
import 'items_screen.dart';

/// Creates the flat Items contribution.
AppRouteDefinition<ItemsDestination> buildItemsDefinition({
  required AdapterCatalogRepository repository,
  required AppDestination Function(int id) itemDestination,
}) => AppRouteDefinition<ItemsDestination>(
  wireName: 'items',
  decode: (parameters) => parameters.isEmpty ? const ItemsDestination() : null,
  pageFactory: (context, destination, pageKey, navigator) =>
      MaterialPage<Object?>(
        key: pageKey,
        name: destination.wireName,
        child: AdapterItemsScreen(
          repository: repository,
          onOpenItem: (id) => navigator.push(itemDestination(id)),
        ),
      ),
);

/// Creates the flat Item-detail contribution.
AppRouteDefinition<ItemDetailDestination> buildItemDetailDefinition({
  required AdapterCatalogRepository repository,
  required AppDestination Function() homeDestination,
}) => AppRouteDefinition<ItemDetailDestination>(
  wireName: 'item',
  decode: (parameters) {
    final id = int.tryParse(parameters['id'] ?? '');
    if (id == null || id < 1 || parameters.length != 1) {
      return null;
    }
    return ItemDetailDestination(id: id);
  },
  pageFactory: (context, destination, pageKey, navigator) =>
      MaterialPage<Object?>(
        key: pageKey,
        name: destination.wireName,
        child: AdapterItemDetailScreen(
          repository: repository,
          id: destination.id,
          onGoHome: () => navigator.push(homeDestination()),
        ),
      ),
);
