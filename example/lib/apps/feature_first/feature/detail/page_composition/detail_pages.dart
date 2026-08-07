import '../view/detail_screen.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/detail_route.dart';

/// Detail feature page contribution.
final AppRoutePageDefinition detailPageDefinition =
    TypedAppRoutePageDefinition<DetailRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: DetailScreen(id: route.id),
      ),
    );
