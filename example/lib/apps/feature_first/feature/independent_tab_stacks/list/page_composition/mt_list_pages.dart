import '../view/mt_list_screen.dart';
import '../../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/mt_list_route.dart';

/// Independent-tab list page contribution.
final AppRoutePageDefinition mtListPageDefinition =
    TypedAppRoutePageDefinition<MtListRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: MtListScreen(tab: route.tab),
      ),
    );
