import '../controller/counter_controller.dart';
import '../view/counter_scope_screen.dart';
import 'scope_route_name.dart';
import '../../../core/routing/app_route.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

/// Per-route DI scope demo: the controller is created/disposed with the page.
final class ScopeRoute extends AppRoute {
  const ScopeRoute();

  @override
  LocalKey get pageKey => const ValueKey('scope');

  @override
  String get name => ScopeRouteName.scope.wire;

  @override
  Map<String, String> toParams() => const {};

  @override
  Page<Object?> buildPage(BuildContext context) => MaterialPage(
        key: pageKey,
        child: RouteScope<CounterController>(
          create: CounterController.new,
          dispose: (controller) => controller.dispose(),
          child: const CounterScopeScreen(),
        ),
      );
}
