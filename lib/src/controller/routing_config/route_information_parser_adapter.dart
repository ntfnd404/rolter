import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../model/route_node.dart';
import 'framework_transaction.dart';
import 'routing_coordinator.dart';

/// Parser adapter that creates transaction identity before asynchronous work.
@internal
final class CoordinatedRouteInformationParser<R extends RouteNode>
    extends RouteInformationParser<Object> {
  /// Wraps an application-owned typed parser without taking ownership of it.
  CoordinatedRouteInformationParser(this._source, this._coordinator);

  final RouteInformationParser<List<R>> _source;
  final RoutingCoordinator<R> _coordinator;

  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) =>
      _parse(
        routeInformation,
        () => _source.parseRouteInformation(routeInformation),
      );

  @override
  Future<Object> parseRouteInformationWithDependencies(
    RouteInformation routeInformation,
    BuildContext context,
  ) => _parse(
    routeInformation,
    () => _source.parseRouteInformationWithDependencies(
      routeInformation,
      context,
    ),
  );

  Future<Object> _parse(
    RouteInformation routeInformation,
    Future<List<R>> Function() parse,
  ) {
    final transaction = _coordinator.begin(routeInformation);
    if (!_coordinator.canCommit(transaction)) {
      return SynchronousFuture<Object>(
        CoordinatedConfiguration<R>.parsed(
          _coordinator.state.root,
          transaction,
        ),
      );
    }
    Future<List<R>> parsed;
    try {
      parsed = parse();
    } on Object catch (error, stackTrace) {
      if (!_coordinator.canCommit(transaction)) {
        return SynchronousFuture<Object>(
          CoordinatedConfiguration<R>.parsed(
            _coordinator.state.root,
            transaction,
          ),
        );
      }
      _coordinator.reportParserFailure(transaction);
      Error.throwWithStackTrace(error, stackTrace);
    }

    return parsed.then<Object>(
      (routes) => CoordinatedConfiguration<R>.parsed(routes, transaction),
      onError: (Object error, StackTrace stackTrace) {
        if (!_coordinator.canCommit(transaction)) {
          return CoordinatedConfiguration<R>.parsed(
            _coordinator.state.root,
            transaction,
          );
        }
        _coordinator.reportParserFailure(transaction);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  @override
  RouteInformation? restoreRouteInformation(Object configuration) {
    if (configuration is! CoordinatedConfiguration<R>) {
      throw StateError(
        'RoutingConfig components must be used together.',
      );
    }
    if (configuration.suppressReport) {
      _coordinator.prepareReport(configuration, null);
      return null;
    }
    final restored = _source.restoreRouteInformation(configuration.routes);
    _coordinator.prepareReport(configuration, restored);

    return restored;
  }
}
