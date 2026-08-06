import '../../shell/routing/mt_tab.dart';
import '../../../../navigation/app_route.dart';
import 'package:flutter/foundation.dart';

/// A detail pushed into a tab's stack.
final class MtDetailRoute extends AppRoute {
  const MtDetailRoute(this.tab, this.id);

  final MtTab tab;
  final int id;

  @override
  LocalKey get pageKey => ValueKey('mt-detail:${tab.wire}:$id');

  @override
  String get name => 'mt-detail';

  @override
  Map<String, String> toParams() => {'tab': tab.wire, 'id': '$id'};
}
