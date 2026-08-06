import '../view/picker_screen.dart';
import '../../../composition/app_route_page_catalog.dart';
import 'package:flutter/material.dart';

import '../routing/picker_route.dart';

/// Picker feature page contribution.
final AppRoutePageDefinition pickerPageDefinition =
    TypedAppRoutePageDefinition<PickerRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<Object?>(
        key: route.pageKey,
        name: route.name,
        child: const PickerScreen(),
      ),
    );
