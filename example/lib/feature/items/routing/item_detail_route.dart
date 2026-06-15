import 'package:example/feature/items/view/item_detail_screen.dart';
import 'package:example/feature/items/routing/items_route_name.dart';
import 'package:example/routing/app_route.dart';
import 'package:flutter/material.dart';

/// Detail pushed inside the Items tab's nested navigator.
final class ItemDetailRoute extends AppRoute {
  const ItemDetailRoute(this.id);

  final int id;

  @override
  LocalKey get pageKey => ValueKey('item:$id');

  @override
  String get name => ItemsRouteName.item.wire;

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: ItemDetailScreen(id: id),
  );
}
