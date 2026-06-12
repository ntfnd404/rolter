import 'dart:developer';

import 'package:example/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';

/// A guard that demonstrates the two `RouteGuard.call` parameters most guards
/// ignore: `history` and `context`.
///
/// It never changes navigation (always proceeds). It reads `history` — the
/// list of previously committed stacks — to classify each transition relative
/// to the last one (push / pop / replace), logs it, and writes the result into
/// the shared `context` map so any later guard in the same pipeline run can
/// read `context['navDirection']` instead of recomputing it.
///
/// This is why `GuardedPipeline` keeps a bounded `history`: a guard can look at
/// where navigation came from, not just where it is going.
class NavigationLogGuard with ChangeNotifier implements RouteGuard<AppRoute> {
  /// Key under which the classified direction is shared in `context`.
  static const String directionKey = 'navDirection';

  @override
  GuardResult<AppRoute> call(
    List<List<AppRoute>> history,
    List<AppRoute> requested,
    Map<String, Object?> context,
  ) {
    final previous = history.isEmpty ? const <AppRoute>[] : history.last;
    final direction = _classify(previous, requested);
    context[directionKey] = direction;

    log(
      '${_describe(previous)} -> ${_describe(requested)} ($direction)',
      name: 'nav',
    );

    return GuardResult.proceed(requested);
  }

  String _classify(List<AppRoute> previous, List<AppRoute> next) {
    if (next.length > previous.length) {
      return 'push';
    }
    if (next.length < previous.length) {
      return 'pop';
    }
    return 'replace';
  }

  String _describe(List<AppRoute> stack) =>
      stack.isEmpty ? '(empty)' : stack.map((route) => route.name).join('/');
}
