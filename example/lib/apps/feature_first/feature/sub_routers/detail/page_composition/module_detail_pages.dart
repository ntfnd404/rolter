import '../view/module_detail_screen.dart';
import '../../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/module_detail_route.dart';

/// Module-detail feature page contribution.
final AppRoutePageDefinition moduleDetailPageDefinition =
    TypedAppRoutePageDefinition<ModuleDetailRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: ModuleDetailScreen(module: route.module, id: route.id),
      ),
    );
