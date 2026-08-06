import '../../shell/routing/mt_tab.dart';
import '../../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

/// The list at the root of a tab's stack.
final class MtListRoute extends AppRoute {
  const MtListRoute(this.tab);

  final MtTab tab;

  @override
  LocalKey get pageKey => ValueKey('mt-list:${tab.wire}');

  @override
  String get name => 'mt-list';

  @override
  Map<String, String> toParams() => {'tab': tab.wire};
}
