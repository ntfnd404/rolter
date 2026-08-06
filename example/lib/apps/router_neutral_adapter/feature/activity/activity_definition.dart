import 'package:flutter/material.dart';

import '../../application/app_route_definition.dart';
import 'activity_destination.dart';
import 'activity_repository.dart';
import 'activity_screen.dart';

/// Creates the Activity module contribution with one narrow dependency.
AppRouteDefinition<ActivityDestination> buildActivityDefinition({
  required ActivityRepository repository,
}) => AppRouteDefinition<ActivityDestination>(
  wireName: 'activity',
  decode: (parameters) {
    final sequence = int.tryParse(parameters['sequence'] ?? '');
    if (sequence == null || sequence < 1 || parameters.length != 1) {
      return null;
    }
    return ActivityDestination(sequence: sequence);
  },
  pageFactory: (context, destination, pageKey, navigator) =>
      MaterialPage<Object?>(
        key: pageKey,
        name: destination.wireName,
        child: AdapterActivityScreen(
          sequence: destination.sequence,
          repository: repository,
          navigator: navigator,
        ),
      ),
);
