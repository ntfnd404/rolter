import 'route_node.dart';

/// Bidirectional projection between the navigation tree (`List<R>`) and a
/// [Uri].
///
/// The engine depends on this interface, not a concrete codec, so an app can
/// swap the URL grammar without touching the parser or delegate. The default
/// implementation is `TreeUrlCodec` (dot-depth grammar); an app may provide
/// its own (e.g. an opaque base64-in-path codec for redirects that strip the
/// fragment) as long as `decode(encode(tree))` round-trips by route-tree value
/// equality, including children and identity-bearing parameters. Rolter does
/// not perform an additional runtime round-trip check.
///
/// The codec domain includes the empty tree. The built-in codecs represent it
/// as `/`, but an empty tree is not a valid committed root Router
/// configuration. `RoutingInformationParser` resolves `/` through the
/// application's root-path callback, while `RoutesState` enforces a non-empty
/// committed root. A custom codec used with that parser must therefore decode
/// every non-root location to a non-empty tree or apply its own app-specific
/// fallback.
abstract interface class RouteUrlCodec<R extends RouteNode> {
  /// Projects the whole [roots] tree to a single [Uri].
  Uri encode(List<R> roots);

  /// Reconstructs the [roots] tree from [uri].
  ///
  /// Direct codec calls may return an empty tree for the codec's empty
  /// representation. This does not make an empty root valid for Flutter's
  /// Router integration.
  List<R> decode(Uri uri);
}
