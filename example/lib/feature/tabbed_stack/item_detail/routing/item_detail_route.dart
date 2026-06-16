import 'package:example/feature/tabbed_stack/item_detail/routing/item_detail_route_name.dart';
import 'package:example/feature/tabbed_stack/item_detail/view/item_detail_screen.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:flutter/material.dart';

/// Detail pushed inside the Items tab's nested navigator.
final class ItemDetailRoute extends AppRoute {
  const ItemDetailRoute(this.id);

  final int id;

  @override
  LocalKey get pageKey => ValueKey('item:$id');

  @override
  String get name => ItemDetailRouteName.item.wire;

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: ItemDetailScreen(id: id),
  );
}
