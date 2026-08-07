import '../view/not_found_screen.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/not_found_route.dart';

/// Not-found feature page contribution.
final AppRoutePageDefinition notFoundPageDefinition =
    TypedAppRoutePageDefinition<NotFoundRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: NotFoundScreen(attempted: route.attempted),
      ),
    );
