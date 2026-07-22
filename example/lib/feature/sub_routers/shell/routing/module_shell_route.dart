import 'demo_module.dart';
import '../view/module_shell.dart';
import '../../home/routing/module_home_route.dart';
import '../../../../core/routing/app_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Mount shell for a module; hosts the module's nested stack.
final class ModuleShellRoute extends AppRoute {
  ModuleShellRoute(this.module, {List<AppRoute>? stack})
      : stack = (stack == null || stack.isEmpty)
            ? [ModuleHomeRoute(module)]
            : stack;

  final DemoModule module;
  final List<AppRoute> stack;

  @override
  List<AppRoute> get children => stack;

  @override
  LocalKey get pageKey => ValueKey('module:${module.wire}');

  @override
  String get name => module.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  AppRoute withChildren(List<RouteNode> children) =>
      ModuleShellRoute(module, stack: children.cast<AppRoute>());

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
        key: pageKey,
        child: ModuleShell(module: module),
      );

  @override
  int get hashCode =>
      Object.hash(ModuleShellRoute, module, Object.hashAll(stack));

  @override
  bool operator ==(Object other) =>
      other is ModuleShellRoute &&
      other.module == module &&
      listEquals(other.stack, stack);
}
