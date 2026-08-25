import 'package:flutter/widgets.dart';

import '../model/route_node.dart';
import '../pages/route_page_builder.dart';
import '../state/routes_state.dart';
import 'routing_config/route_information_parser_adapter.dart';
import 'routing_config/route_information_provider_adapter.dart';
import 'routing_config/routing_coordinator.dart';
import 'routing_config/routing_delegate_adapter.dart';

/// A coordinated Flutter Router integration for asynchronous route pipelines.
///
/// Unlike the low-level `RoutingDelegate`, this bundle observes platform route
/// transactions at parser start. A newer platform request or root Back can
/// supersede an uncommitted older request before it reaches the delegate. App
/// navigation remains deterministic FIFO: every app mutation that is actually
/// enqueued seals committable framework requests already accepted by the queue.
/// An app operation that returns before enqueue (for example, a root-stack
/// `pop`) does not affect a parser-only platform transaction.
///
/// The supplied [RoutesState], parser, provider, and back-button dispatcher are
/// borrowed. When no provider or dispatcher is supplied, this object creates
/// the platform defaults and owns them. Call [dispose] before disposing the
/// backing state. Opaque `RouteInformation.state` is passed to the supplied
/// parser unchanged; coordination retains only the platform request's URI.
/// Use one instance with one simultaneously mounted root Router. A sequential
/// remount is supported after the previous Router has fully unmounted; nested
/// navigators use child dispatchers and route subtrees instead of remounting
/// this root config.
final class RoutingConfig<R extends RouteNode> implements RouterConfig<Object> {
  /// Creates a coordinated configuration for `MaterialApp.router`.
  RoutingConfig({
    required RoutesState<R> state,
    required RouteInformationParser<List<R>> routeInformationParser,
    required RouteNodePageBuilder<R> pageBuilder,
    RouteInformationProvider? routeInformationProvider,
    RouteInformation? initialRouteInformation,
    BackButtonDispatcher? backButtonDispatcher,
    TransitionDelegate<Object?>? transitionDelegate,
  }) : _state = state {
    if (routeInformationProvider != null && initialRouteInformation != null) {
      throw ArgumentError(
        'initialRouteInformation can only be used when '
        'RoutingConfig creates the '
        'PlatformRouteInformationProvider.',
      );
    }

    _coordinator = RoutingCoordinator<R>(state);
    attachRoutesStateCoordinator<R>(state, _coordinator);
    CoordinatedRouteInformationProvider<R>? providerAdapter;
    CoordinatedRoutingDelegate<R>? delegateAdapter;
    try {
      final sourceProvider =
          routeInformationProvider ??
          PlatformRouteInformationProvider(
            initialRouteInformation:
                initialRouteInformation ?? _defaultInitialRouteInformation(),
          );
      _ownedPlatformProvider = routeInformationProvider == null
          ? sourceProvider as PlatformRouteInformationProvider
          : null;
      providerAdapter = CoordinatedRouteInformationProvider<R>(
        sourceProvider,
        _coordinator,
      );
      providerAdapter.attach();
      delegateAdapter = CoordinatedRoutingDelegate<R>(
        state,
        _coordinator,
        pageBuilder: pageBuilder,
        transitionDelegate: transitionDelegate,
      );
      this.routeInformationProvider = providerAdapter;
      this.routeInformationParser = CoordinatedRouteInformationParser<R>(
        routeInformationParser,
        _coordinator,
      );
      routerDelegate = delegateAdapter;
      this.backButtonDispatcher =
          backButtonDispatcher ?? RootBackButtonDispatcher();
    } catch (_) {
      delegateAdapter?.dispose();
      providerAdapter?.dispose();
      _ownedPlatformProvider?.dispose();
      _ownedPlatformProvider = null;
      _coordinator.dispose();
      detachRoutesStateCoordinator<R>(state, _coordinator);
      rethrow;
    }
  }

  final RoutesState<R> _state;
  late final RoutingCoordinator<R> _coordinator;
  PlatformRouteInformationProvider? _ownedPlatformProvider;
  bool _disposed = false;

  @override
  late final RouteInformationProvider routeInformationProvider;

  @override
  late final RouteInformationParser<Object> routeInformationParser;

  @override
  late final RouterDelegate<Object> routerDelegate;

  @override
  late final BackButtonDispatcher backButtonDispatcher;

  /// Detaches this integration without disposing borrowed application objects.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _coordinator.dispose();
    (routerDelegate as CoordinatedRoutingDelegate<R>).dispose();
    (routeInformationProvider as CoordinatedRouteInformationProvider<R>)
        .dispose();
    _ownedPlatformProvider?.dispose();
    _ownedPlatformProvider = null;
    detachRoutesStateCoordinator<R>(_state, _coordinator);
  }

  static RouteInformation _defaultInitialRouteInformation() {
    WidgetsFlutterBinding.ensureInitialized();
    final routeName =
        WidgetsBinding.instance.platformDispatcher.defaultRouteName;

    return RouteInformation(
      uri: routeName.isEmpty ? Uri(path: '/') : Uri.parse(routeName),
    );
  }
}
