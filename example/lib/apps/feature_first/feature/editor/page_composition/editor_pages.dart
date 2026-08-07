import '../view/editor_screen.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/editor_route.dart';

/// Editor feature page contribution.
final AppRoutePageDefinition editorPageDefinition =
    TypedAppRoutePageDefinition<EditorRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: const EditorScreen(),
      ),
    );
