import 'package:example/feature/items/routing/items_route_name.dart';
import 'package:example/feature/items/view/items_screen.dart';
import 'package:example/routing/app_route.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Base of the Items tab's nested navigator. The whole tab runs with a
/// [NoAnimationTransitionDelegate] (see `TabsRoute`), so pages here are plain
/// [MaterialPage]s — the delegate, not the page, suppresses the transition.
final class ItemsRoute extends AppRoute {
  const ItemsRoute();

  @override
  LocalKey get pageKey => const ValueKey('items');

  @override
  String get name => ItemsRouteName.items.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) =>
      MaterialPage(key: pageKey, child: const ItemsScreen());
}
