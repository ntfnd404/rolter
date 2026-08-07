import '../view/home_screen.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/home_route.dart';

/// Home feature page contribution.
final AppRoutePageDefinition homePageDefinition =
    TypedAppRoutePageDefinition<HomeRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: const HomeScreen(),
      ),
    );
