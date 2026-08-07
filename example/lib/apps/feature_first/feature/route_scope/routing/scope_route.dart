import 'scope_route_name.dart';
import '../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

/// Per-route DI scope demo: the controller is created/disposed with the page.
final class ScopeRoute extends AppRoute {
  const ScopeRoute();

  @override
  LocalKey get pageKey => const ValueKey('scope');

  @override
  String get name => ScopeRouteName.scope.wire;

  @override
  Map<String, String> toParams() => const {};
}
