import '../../shell/routing/mt_tab.dart';
import '../view/mt_list_screen.dart';
import '../../../../core/routing/app_route.dart';
import 'package:flutter/material.dart';

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

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
    key: pageKey,
    child: MtListScreen(tab: tab),
  );
}
