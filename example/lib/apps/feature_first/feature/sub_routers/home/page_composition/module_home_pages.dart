import '../view/module_home_screen.dart';
import '../../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/module_home_route.dart';

/// Module-home feature page contribution.
final AppRoutePageDefinition moduleHomePageDefinition =
    TypedAppRoutePageDefinition<ModuleHomeRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: ModuleHomeScreen(module: route.module),
      ),
    );
