import '../controller/counter_controller.dart';
import '../view/counter_scope_screen.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

import '../routing/scope_route.dart';

/// Route-scope feature page contribution.
final AppRoutePageDefinition scopePageDefinition =
    TypedAppRoutePageDefinition<ScopeRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: RouteScope<CounterController>(
          create: CounterController.new,
          dispose: (controller) => controller.dispose(),
          child: const CounterScopeScreen(),
        ),
      ),
    );
