import 'dart:developer';

import 'package:example/core/routing/app_route.dart';
import 'package:rolter/rolter.dart';

/// Logs every committed navigation transition. Telemetry belongs in a
/// [NavObserver], not a [RouteGuard] — observers run read-only after the commit,
/// so they cannot accidentally change navigation.
class NavigationLogObserver implements NavObserver<AppRoute> {
  @override
  void onTransition(NavTransition<AppRoute> transition) {
    log(
      '${_describe(transition.previous)} -> ${_describe(transition.next)} '
      '(+${transition.entered.length} -${transition.left.length})',
      name: 'nav',
    );
  }

  String _describe(List<AppRoute> stack) =>
      stack.isEmpty ? '(empty)' : stack.map((route) => route.name).join('/');
}
