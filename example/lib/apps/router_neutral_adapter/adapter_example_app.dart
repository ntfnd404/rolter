import 'package:flutter/material.dart';

import '../../common/ui/example_theme.dart';
import 'application/app_destination.dart';
import 'application/app_route_definition.dart';
import 'application/not_found_destination.dart';
import 'feature/activity/activity_definition.dart';
import 'feature/activity/activity_destination.dart';
import 'feature/activity/activity_repository.dart';
import 'feature/catalog/catalog_definitions.dart';
import 'feature/catalog/catalog_repository.dart';
import 'feature/catalog/item_detail_destination.dart';
import 'feature/catalog/items_destination.dart';
import 'feature/home/home_definition.dart';
import 'feature/home/home_destination.dart';
import 'infrastructure/rolter_adapter.dart';
import 'view/adapter_not_found_screen.dart';

/// Creates the router-neutral reference with its explicit demo repositories.
AdapterExampleApp createRouterNeutralAdapterExampleApp() =>
    const AdapterExampleApp(
      activityRepository: StaticActivityRepository('Adapter repository'),
      catalogRepository: StaticAdapterCatalogRepository(),
    );

/// Runnable flat modular application with a router-neutral feature boundary.
final class AdapterExampleApp extends StatefulWidget {
  /// Creates the adapter example with one explicit feature dependency.
  const AdapterExampleApp({
    required this.activityRepository,
    required this.catalogRepository,
    this.routeInformationProvider,
    super.key,
  });

  /// Narrow dependency captured by the Activity route definition.
  final ActivityRepository activityRepository;

  /// Narrow dependency captured by the Catalog route definitions.
  final AdapterCatalogRepository catalogRepository;

  /// Optional provider used by deep-link widget tests.
  final RouteInformationProvider? routeInformationProvider;

  @override
  State<AdapterExampleApp> createState() => _AdapterExampleAppState();
}

final class _AdapterExampleAppState extends State<AdapterExampleApp> {
  late final RolterAdapter _adapter;

  @override
  void initState() {
    super.initState();
    _adapter = RolterAdapter(
      definitions: <AppRouteDefinition<AppDestination>>[
        buildHomeDefinition(
          activityDestination: () => const ActivityDestination(sequence: 42),
          itemsDestination: ItemsDestination.new,
        ),
        buildActivityDefinition(repository: widget.activityRepository),
        buildItemsDefinition(
          repository: widget.catalogRepository,
          itemDestination: (id) => ItemDetailDestination(id: id),
        ),
        buildItemDetailDefinition(
          repository: widget.catalogRepository,
          homeDestination: HomeDestination.new,
        ),
        _buildNotFoundDefinition(),
      ],
      initialDestination: const HomeDestination(),
      invalidDestination: NotFoundDestination.new,
      unknownDestination: (_) => const NotFoundDestination(),
    );
  }

  @override
  void dispose() {
    _adapter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Rolter adapter example',
    theme: buildExampleTheme(),
    routeInformationProvider: widget.routeInformationProvider,
    routeInformationParser: _adapter.routeInformationParser,
    routerDelegate: _adapter.routerDelegate,
  );
}

AppRouteDefinition<NotFoundDestination> _buildNotFoundDefinition() =>
    AppRouteDefinition<NotFoundDestination>(
      wireName: 'not-found',
      decode: (parameters) =>
          parameters.isEmpty ? const NotFoundDestination() : null,
      pageFactory: (context, destination, pageKey, navigator) =>
          MaterialPage<Object?>(
            key: pageKey,
            name: destination.wireName,
            child: AdapterNotFoundScreen(
              onGoHome: () => navigator.push(const HomeDestination()),
            ),
          ),
    );
