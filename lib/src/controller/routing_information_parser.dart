import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../model/route_node.dart';
import '../model/route_url_codec.dart';
import 'entry_query_store.dart';

/// Bridges the platform's [RouteInformation] (URL) and the typed tree config
/// (`List<R>`), delegating the grammar to a [RouteUrlCodec].
class RoutingInformationParser<R extends RouteNode>
    extends RouteInformationParser<List<R>> {
  /// Creates a parser that uses [_codec] to convert between URLs and trees.
  ///
  /// Pass [entryQuery] to capture each entry URL's raw `?k=v` query (e.g. for
  /// `utm_*`/`fbclid` pass-through the route tree does not model).
  const RoutingInformationParser(this._codec, {this.entryQuery});
  final RouteUrlCodec<R> _codec;

  /// Optional sink for each entry URL's raw query parameters.
  final EntryQueryStore? entryQuery;

  @override
  Future<List<R>> parseRouteInformation(RouteInformation routeInformation) {
    entryQuery?.capture(routeInformation.uri.queryParameters);

    return SynchronousFuture<List<R>>(_codec.decode(routeInformation.uri));
  }

  @override
  RouteInformation? restoreRouteInformation(List<R> configuration) {
    if (configuration.isNotEmpty && configuration.last is HistoryExcluded) {
      return null;
    }

    return RouteInformation(uri: _codec.encode(configuration));
  }
}
