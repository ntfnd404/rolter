import 'items_route_name.dart';
import '../../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

/// Base of the Items tab's nested navigator. The whole tab runs with a
/// no-animation transition delegate (see `TabsRoute`).
final class ItemsRoute extends AppRoute {
  const ItemsRoute();

  @override
  LocalKey get pageKey => const ValueKey('items');

  @override
  String get name => ItemsRouteName.items.wire;

  @override
  Map<String, String> toParams() => const {};
}
