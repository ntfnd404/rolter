import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';

/// Data-only route family for external Page composition.
sealed class ScopedRoute with KeyedRouteEquality implements RouteNode {
  const ScopedRoute();

  @override
  List<RouteNode> get children => const [];

  @override
  ScopedRoute withChildren(List<RouteNode> children) => this;
}

final class ScopedHomeRoute extends ScopedRoute {
  const ScopedHomeRoute();

  @override
  String get name => 'home';

  @override
  LocalKey get pageKey => const ValueKey<String>('scoped-home');

  @override
  Map<String, String> toParams() => const {};
}

final class ScopedItemsRoute extends ScopedRoute {
  const ScopedItemsRoute();

  @override
  String get name => 'items';

  @override
  LocalKey get pageKey => const ValueKey<String>('scoped-items');

  @override
  Map<String, String> toParams() => const {};
}

final class ScopedItemDetailRoute extends ScopedRoute {
  const ScopedItemDetailRoute({required this.id});

  final int id;

  @override
  String get name => 'item';

  @override
  LocalKey get pageKey => ValueKey<String>('scoped-item:$id');

  @override
  Map<String, String> toParams() => {'id': '$id'};
}

final class ScopedNotFoundRoute extends ScopedRoute implements HistoryExcluded {
  const ScopedNotFoundRoute();

  @override
  String get name => 'not-found';

  @override
  LocalKey get pageKey => const ValueKey<String>('scoped-not-found');

  @override
  Map<String, String> toParams() => const {};
}
