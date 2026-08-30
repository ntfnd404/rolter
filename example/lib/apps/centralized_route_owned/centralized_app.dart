import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';

import '../../common/ui/example_theme.dart';
import 'centralized_route_catalog.dart';

/// Creates the centralized route-owned reference application.
CentralizedRouteOwnedApp createCentralizedRouteOwnedExampleApp() =>
    const CentralizedRouteOwnedApp();

/// A compact application whose complete routing catalog lives in one file.
final class CentralizedRouteOwnedApp extends StatefulWidget {
  /// Creates the centralized example.
  const CentralizedRouteOwnedApp({this.routeInformationProvider, super.key});

  /// Optional provider used by deep-link tests and embedding applications.
  final RouteInformationProvider? routeInformationProvider;

  @override
  State<CentralizedRouteOwnedApp> createState() =>
      _CentralizedRouteOwnedAppState();
}

final class _CentralizedRouteOwnedAppState
    extends State<CentralizedRouteOwnedApp> {
  late final RoutesState<CentralizedRoute> _state;
  late final NavigationController<CentralizedRoute> _navigator;
  late final RoutingDelegate<CentralizedRoute> _delegate;
  late final RoutingInformationParser<CentralizedRoute> _parser;

  @override
  void initState() {
    super.initState();
    _state = RoutesState<CentralizedRoute>(const [
      CentralizedHomeRoute(),
    ], (requested) => requested);
    _navigator = NavigationController<CentralizedRoute>(_state);
    _delegate = RoutingDelegate<CentralizedRoute>(
      _state,
      pageBuilder: buildPageFromRouteNode<CentralizedRoute>,
    );
    _parser = RoutingInformationParser<CentralizedRoute>(
      TreeUrlCodec<CentralizedRoute>(centralizedRouteRegistry),
      routesForRootPath: (_) => const <CentralizedRoute>[
        CentralizedHomeRoute(),
      ],
    );
  }

  @override
  void dispose() {
    _delegate.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => NavigatorScope(
    navigator: _navigator,
    child: MaterialApp.router(
      title: 'Rolter centralized route-owned example',
      theme: buildExampleTheme(),
      routeInformationProvider: widget.routeInformationProvider,
      routerDelegate: _delegate,
      routeInformationParser: _parser,
    ),
  );
}
