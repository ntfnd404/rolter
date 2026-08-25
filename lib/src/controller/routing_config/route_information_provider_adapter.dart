import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../model/route_node.dart';
import 'routing_coordinator.dart';

/// Provider adapter that applies coordinated browser reporting policy.
@internal
final class CoordinatedRouteInformationProvider<R extends RouteNode>
    extends RouteInformationProvider
    with ChangeNotifier {
  /// Wraps an application- or config-owned provider without taking ownership.
  CoordinatedRouteInformationProvider(this._source, this._coordinator);

  final RouteInformationProvider _source;
  final RoutingCoordinator<R> _coordinator;
  bool _attached = false;

  /// Attaches the forwarding listener with rollback on partial registration.
  void attach() {
    try {
      _source.addListener(_handleSourceChanged);
      _attached = true;
    } on Object catch (error, stackTrace) {
      // A custom Listenable may register the callback before throwing. Attempt
      // rollback while preserving the causal constructor error.
      try {
        _source.removeListener(_handleSourceChanged);
      } on Object {
        // The original add-listener failure remains the useful causal error.
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  RouteInformation get value => _source.value;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    _source.routerReportsNewRouteInformation(
      routeInformation,
      type: _coordinator.reportingType(routeInformation, type),
    );
  }

  void _handleSourceChanged() => notifyListeners();

  @override
  void dispose() {
    if (_attached) {
      _attached = false;
      _source.removeListener(_handleSourceChanged);
    }
    super.dispose();
  }
}
