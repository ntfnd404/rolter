import 'package:flutter/material.dart';

import '../../application/app_destination.dart';
import '../../application/app_route_definition.dart';
import 'home_destination.dart';
import 'home_screen.dart';

/// Creates the Home module contribution without importing another feature.
AppRouteDefinition<HomeDestination> buildHomeDefinition({
  required AppDestination Function() activityDestination,
  required AppDestination Function() itemsDestination,
}) => AppRouteDefinition<HomeDestination>(
  wireName: 'home',
  decode: (parameters) => parameters.isEmpty ? const HomeDestination() : null,
  pageFactory: (context, destination, pageKey, navigator) =>
      MaterialPage<Object?>(
        key: pageKey,
        name: destination.wireName,
        child: AdapterHomeScreen(
          onOpenActivity: () => navigator.push(activityDestination()),
          onOpenItems: () => navigator.push(itemsDestination()),
        ),
      ),
);
