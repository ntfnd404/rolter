import 'package:flutter/widgets.dart';
import 'package:rolter/rolter.dart';

import '../application/app_destination.dart';
import '../application/app_navigation_controller.dart';
import '../application/app_route_definition.dart';

/// Application infrastructure translating neutral destinations into Rolter.
///
/// The example deliberately supports only a flat root stack and `push`/`pop`.
/// Advanced Rolter capabilities stay in the Rolter-native example instead of
/// being duplicated behind a lowest-common-denominator SPI.
final class RolterAdapter implements AppNavigationController {
  /// Creates the adapter and its owned Rolter objects.
  RolterAdapter({
    required Iterable<AppRouteDefinition<AppDestination>> definitions,
    required AppDestination initialDestination,
    required AppDestination Function() invalidDestination,
    required AppDestination Function(Uri uri) unknownDestination,
  }) : _definitionsByType = _indexByType(definitions),
       _invalidDestination = invalidDestination {
    final definitionsByWire = _indexByWire(_definitionsByType.values);
    _ensureRegistered(initialDestination);
    final initialRoute = _wrap(initialDestination);
    _state = RoutesState<_DestinationRouteNode>(<_DestinationRouteNode>[
      initialRoute,
    ], (requested) => requested);
    _controller = NavigationController<_DestinationRouteNode>(_state);
    _delegate = RoutingDelegate<_DestinationRouteNode>(
      _state,
      pageBuilder: _buildPage,
    );
    final registry = RouteRegistry<_DestinationRouteNode>(
      <String, RouteDecoder<_DestinationRouteNode>>{
        for (final entry in definitionsByWire.entries)
          entry.key: (parameters, children) =>
              _decode(entry.value, parameters, children),
      },
      fallback: (uri) => _wrapRegistered(unknownDestination(uri)),
    );
    _parser = RoutingInformationParser<_DestinationRouteNode>(
      TreeUrlCodec<_DestinationRouteNode>(registry),
      routesForRootPath: (_) => <_DestinationRouteNode>[initialRoute],
    );
  }

  final Map<Type, AppRouteDefinition<AppDestination>> _definitionsByType;
  final AppDestination Function() _invalidDestination;
  late final RoutesState<_DestinationRouteNode> _state;
  late final NavigationController<_DestinationRouteNode> _controller;
  late final RoutingDelegate<_DestinationRouteNode> _delegate;
  late final RoutingInformationParser<_DestinationRouteNode> _parser;

  /// Flutter Router delegate with the private Rolter node erased to `Object`.
  RouterDelegate<Object> get routerDelegate => _delegate;

  /// Flutter route-information parser with private Rolter nodes erased.
  RouteInformationParser<Object> get routeInformationParser => _parser;

  @override
  void push(AppDestination destination) {
    _ensureRegistered(destination);
    _controller.push(_wrap(destination));
  }

  @override
  void pop() => _controller.pop();

  /// Releases every Rolter object owned by this adapter.
  void dispose() {
    _delegate.dispose();
    _state.dispose();
  }

  Page<Object?> _buildPage(BuildContext context, _DestinationRouteNode route) {
    final definition = _definitionsByType[route.destination.runtimeType];
    if (definition == null) {
      throw StateError(
        'No route definition is registered for '
        '${route.destination.runtimeType}.',
      );
    }
    return definition.buildPage(
      context,
      route.destination,
      route.pageKey,
      this,
    );
  }

  _DestinationRouteNode _decode(
    AppRouteDefinition<AppDestination> definition,
    Map<String, String> parameters,
    List<_DestinationRouteNode> children,
  ) {
    if (children.isNotEmpty) {
      return _wrapRegistered(_invalidDestination());
    }
    final destination = definition.decodeDestination(parameters);
    if (destination == null ||
        destination.runtimeType != definition.destinationType ||
        destination.wireName != definition.wireName) {
      return _wrapRegistered(_invalidDestination());
    }
    return _wrap(destination);
  }

  void _ensureRegistered(AppDestination destination) {
    final definition = _definitionsByType[destination.runtimeType];
    if (definition == null) {
      throw StateError(
        'No route definition is registered for ${destination.runtimeType}.',
      );
    }
    if (definition.wireName != destination.wireName) {
      throw StateError(
        'The route definition for ${destination.runtimeType} has an '
        'incompatible wire name.',
      );
    }
  }

  _DestinationRouteNode _wrapRegistered(AppDestination destination) {
    _ensureRegistered(destination);
    return _wrap(destination);
  }

  static _DestinationRouteNode _wrap(AppDestination destination) =>
      _DestinationRouteNode(destination);

  static Map<Type, AppRouteDefinition<AppDestination>> _indexByType(
    Iterable<AppRouteDefinition<AppDestination>> definitions,
  ) {
    final indexed = <Type, AppRouteDefinition<AppDestination>>{};
    for (final definition in definitions) {
      if (indexed.containsKey(definition.destinationType)) {
        throw StateError(
          'More than one route definition is registered for '
          '${definition.destinationType}.',
        );
      }
      indexed[definition.destinationType] = definition;
    }
    return Map<Type, AppRouteDefinition<AppDestination>>.unmodifiable(indexed);
  }

  static Map<String, AppRouteDefinition<AppDestination>> _indexByWire(
    Iterable<AppRouteDefinition<AppDestination>> definitions,
  ) {
    final indexed = <String, AppRouteDefinition<AppDestination>>{};
    for (final definition in definitions) {
      if (indexed.containsKey(definition.wireName)) {
        throw StateError('More than one route definition uses a wire name.');
      }
      indexed[definition.wireName] = definition;
    }
    return Map<String, AppRouteDefinition<AppDestination>>.unmodifiable(
      indexed,
    );
  }
}

@immutable
final class _DestinationRouteNode implements RouteNode {
  const _DestinationRouteNode(this.destination);

  final AppDestination destination;

  @override
  List<RouteNode> get children => const [];

  @override
  String get name => destination.wireName;

  @override
  LocalKey get pageKey =>
      ValueKey<Object>((destination.runtimeType, destination.pageIdentity));

  @override
  Map<String, String> toParams() => destination.toParams();

  @override
  RouteNode withChildren(List<RouteNode> children) {
    if (children.isNotEmpty) {
      throw StateError('The adapter example supports only flat destinations.');
    }
    return this;
  }

  @override
  int get hashCode => Object.hash(_DestinationRouteNode, destination);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DestinationRouteNode && other.destination == destination;
}
