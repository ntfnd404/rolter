import 'package:example/feature/independent_tab_stacks/shell/routing/mt_tab.dart';
import 'package:example/feature/independent_tab_stacks/detail/view/mt_detail_screen.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:flutter/material.dart';

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

  @override
  Page<Object?> buildPage(BuildContext context) =>
      MaterialPage(key: pageKey, child: MtDetailScreen(tab: tab, id: id));
}
