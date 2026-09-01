import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

import '../../common/ui/example_theme.dart';
import 'dependency/scoped_catalog_repository.dart';
import 'dependency/scoped_catalog_repository_scope.dart';
import 'page_composition/scoped_page_builder.dart';
import 'route_data/scoped_registry.dart';
import 'route_data/scoped_routes.dart';

/// Creates the external-builder reference with its explicit demo repository.
ExternalBuilderScopeApp createExternalBuilderScopeExampleApp() =>
    const ExternalBuilderScopeApp(
      repository: StaticScopedCatalogRepository(
        'Dependency from ScopedCatalogRepositoryScope.of',
      ),
    );

/// Application demonstrating external composition with a narrow Scope.of.
final class ExternalBuilderScopeApp extends StatefulWidget {
  const ExternalBuilderScopeApp({
    required this.repository,
    this.routeInformationProvider,
    super.key,
  });

  final ScopedCatalogRepository repository;
  final RouteInformationProvider? routeInformationProvider;

  @override
  State<ExternalBuilderScopeApp> createState() =>
      _ExternalBuilderScopeAppState();
}

final class _ExternalBuilderScopeAppState
    extends State<ExternalBuilderScopeApp> {
  late final RoutesState<ScopedRoute> _state;
  late final NavigationController<ScopedRoute> _navigator;
  late final RoutingDelegate<ScopedRoute> _delegate;
  late final RoutingInformationParser<ScopedRoute> _parser;

  @override
  void initState() {
    super.initState();
    _state = RoutesState<ScopedRoute>(const [
      ScopedHomeRoute(),
    ], (requested) => requested);
    _navigator = NavigationController<ScopedRoute>(_state);
    _delegate = RoutingDelegate<ScopedRoute>(
      _state,
      pageBuilder: buildScopedPage,
    );
    _parser = RoutingInformationParser<ScopedRoute>(
      TreeUrlCodec<ScopedRoute>(scopedRouteRegistry),
      routesForRootPath: (_) => const <ScopedRoute>[ScopedHomeRoute()],
    );
  }

  @override
  void dispose() {
    _delegate.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScopedCatalogRepositoryScope(
    repository: widget.repository,
    child: NavigatorScope(
      navigator: _navigator,
      child: MaterialApp.router(
        title: 'Rolter external builder and Scope example',
        theme: buildExampleTheme(),
        routeInformationProvider: widget.routeInformationProvider,
        routerDelegate: _delegate,
        routeInformationParser: _parser,
      ),
    ),
  );
}
