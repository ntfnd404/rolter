import '../view/mt_detail_screen.dart';
import '../../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/mt_detail_route.dart';

/// Independent-tab detail page contribution.
final AppRoutePageDefinition mtDetailPageDefinition =
    TypedAppRoutePageDefinition<MtDetailRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: MtDetailScreen(tab: route.tab, id: route.id),
      ),
    );
