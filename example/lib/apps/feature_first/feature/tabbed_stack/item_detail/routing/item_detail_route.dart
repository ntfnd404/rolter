import 'item_detail_route_name.dart';
import '../../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

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
}
