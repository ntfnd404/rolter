import 'package:example/feature/independent_tab_stacks/shell/routing/mt_tab.dart';
import 'package:example/feature/independent_tab_stacks/list/routing/mt_list_route.dart';
import 'package:example/core/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// One tab's container. Its [children] are that tab's nested back stack; it is
/// never rendered as a page itself (the shell hosts its children).
final class MtTabRoute extends AppRoute {
  MtTabRoute(this.tab, {List<AppRoute>? stack})
    : stack = stack ?? [MtListRoute(tab)];

  final MtTab tab;
  final List<AppRoute> stack;

  @override
  List<AppRoute> get children => stack;

  @override
  LocalKey get pageKey => ValueKey('mt-tab:${tab.wire}');

  @override
  String get name => tab.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  AppRoute withChildren(List<RouteNode> children) =>
      MtTabRoute(tab, stack: children.cast<AppRoute>());

  @override
  Page<Object?> buildPage(BuildContext context) =>
      MaterialPage(key: pageKey, child: const SizedBox.shrink());

  @override
  int get hashCode => Object.hash(MtTabRoute, tab, Object.hashAll(stack));

  @override
  bool operator ==(Object other) =>
      other is MtTabRoute && other.tab == tab && listEquals(other.stack, stack);
}
