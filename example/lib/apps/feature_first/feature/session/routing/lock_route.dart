import 'session_route_name.dart';
import '../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';

/// Redirect target of the lock guard. Kept out of browser history and rendered
/// without an entrance animation.
final class LockRoute extends AppRoute implements HistoryExcluded {
  const LockRoute();

  @override
  LocalKey get pageKey => const ValueKey('lock');

  @override
  String get name => SessionRouteName.lock.wire;

  @override
  Map<String, String> toParams() => const {};
}
