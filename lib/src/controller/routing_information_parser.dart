import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:rolter/src/model/route_node.dart';
import 'package:rolter/src/model/tree_url_codec.dart';

/// Bridges the platform's [RouteInformation] (URL) and the typed tree config
/// (`List<R>`), delegating the grammar to [TreeUrlCodec].
class RoutingInformationParser<R extends RouteNode>
    extends RouteInformationParser<List<R>> {
  /// Creates a parser that uses [_codec] to convert between URLs and trees.
  const RoutingInformationParser(this._codec);
  final TreeUrlCodec<R> _codec;

  @override
  Future<List<R>> parseRouteInformation(RouteInformation routeInformation) =>
      SynchronousFuture<List<R>>(_codec.decode(routeInformation.uri));

  @override
  RouteInformation? restoreRouteInformation(List<R> configuration) {
    if (configuration.isNotEmpty && configuration.last is HistoryExcluded) {
      return null;
    }

    return RouteInformation(uri: _codec.encode(configuration));
  }
}
