import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../model/route_node.dart';
import '../model/route_url_codec.dart';
import 'entry_query_store.dart';

/// Bridges the platform's [RouteInformation] and the typed route tree.
///
/// The logical root path is application policy rather than codec policy. It is
/// resolved by the callback supplied to the constructor before [_codec] is
/// consulted, so Rolter never assumes that an application has a `home` route.
/// Other locations delegate their URL grammar to [_codec].
///
/// A parsed Router configuration is always non-empty. Raw codecs may still
/// round-trip an empty tree, and a custom parser may submit an empty request
/// for an application route pipeline to normalize. Flutter's root
/// `Navigator.pages` cannot represent an empty committed configuration.
/// With `RoutingConfig`, a root alias whose encoded result is another URI is
/// also reported as a replace-style Web correction. A low-level manual Router
/// assembly still parses the same route tree but does not provide that
/// coordinated browser-history guarantee.
class RoutingInformationParser<R extends RouteNode>
    extends RouteInformationParser<List<R>> {
  /// Creates a parser that uses [_codec] for non-root locations.
  ///
  /// [routesForRootPath] builds the complete stack for an empty or slash-only
  /// path. It receives the original [RouteInformation], including query,
  /// fragment, and opaque `state`, and must return at least one route. Keep it
  /// synchronous, deterministic, and free of navigation side effects; async
  /// authorization and session policy belong in the route pipeline. Its result
  /// must also round-trip by route-tree value equality through [_codec],
  /// because the codec determines the canonical URL reported after the root
  /// alias is accepted. This is an application contract, not an extra runtime
  /// encode/decode performed by Rolter.
  ///
  /// Pass [entryQuery] to capture each attempted entry URL's decoded,
  /// single-value `?k=v` map (e.g. for `utm_*`/`fbclid` pass-through the route
  /// tree does not model). Capture happens before route resolution and is not
  /// rolled back on a later parsing failure. The opaque input `state` is
  /// available to [routesForRootPath] but is not automatically copied to
  /// restored route information.
  const RoutingInformationParser(
    this._codec, {
    required List<R> Function(RouteInformation information) routesForRootPath,
    this.entryQuery,
  }) : _routesForRootPath = routesForRootPath;

  final RouteUrlCodec<R> _codec;
  final List<R> Function(RouteInformation information) _routesForRootPath;

  /// Optional sink for each attempted entry URL's decoded query parameters.
  final EntryQueryStore? entryQuery;

  /// Parses a platform location into a non-empty Router configuration.
  ///
  /// Entry query parameters are captured before root resolution or codec
  /// decoding. Empty and slash-only paths use the application callback;
  /// non-root locations use the codec. The returned top-level list is an
  /// immutable copy; route nodes and their children are not deep-cloned.
  /// A successful synchronous callback or codec remains synchronous, while a
  /// thrown error is returned through a failed Future with its original stack.
  @override
  Future<List<R>> parseRouteInformation(RouteInformation routeInformation) {
    try {
      entryQuery?.capture(routeInformation.uri.queryParameters);

      // Resolve the alias before decoding. In particular, decoding `/` to an
      // empty codec tree must never become an empty root Navigator.
      final decoded = _isRootPath(routeInformation.uri)
          ? _routesForRootPath(routeInformation)
          : _codec.decode(routeInformation.uri);
      final routes = List<R>.unmodifiable(decoded);
      if (routes.isEmpty) {
        throw StateError(
          'rolter: route parsing produced an empty root stack. '
          'A root Router requires at least one route.',
        );
      }

      // Keep successful structural parsing in the current frame. Failures use
      // a Future below so both low-level and coordinated Flutter Router paths
      // observe them through the parser's declared asynchronous contract.
      return SynchronousFuture<List<R>>(routes);
    } on Object catch (error, stackTrace) {
      return Future<List<R>>.error(error, stackTrace);
    }
  }

  /// Restores a non-empty route tree through the configured URL codec.
  ///
  /// An empty configuration is rejected instead of being encoded as `/`:
  /// parsing `/` is application-defined and may produce a completely different
  /// non-empty tree, so treating the codec's empty value as Router state would
  /// break parse/restore equivalence.
  /// A non-empty configuration whose last route is [HistoryExcluded] is valid
  /// but returns `null`, including when it originated from the root callback;
  /// coordinated canonical URL reporting is intentionally suppressed then.
  @override
  RouteInformation? restoreRouteInformation(List<R> configuration) {
    // `/` is an app-defined alias on the parsing side, so restoring `[]` to it
    // would violate Flutter's parse/restore equivalence requirement.
    if (configuration.isEmpty) {
      throw StateError(
        'rolter: an empty root stack cannot be restored to route information.',
      );
    }
    if (configuration.last is HistoryExcluded) {
      return null;
    }

    return RouteInformation(uri: _codec.encode(configuration));
  }

  bool _isRootPath(Uri uri) =>
      uri.pathSegments.isEmpty ||
      uri.pathSegments.every((segment) => segment.isEmpty);
}
