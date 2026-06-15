import 'package:rolter/src/model/route_node.dart';

/// Bidirectional projection between the navigation tree (`List<R>`) and a
/// [Uri].
///
/// The engine depends on this interface, not a concrete codec, so an app can
/// swap the URL grammar without touching the parser or delegate. The default
/// implementation is `TreeUrlCodec` (dot-depth grammar); an app may provide
/// its own (e.g. an opaque base64-in-path codec for redirects that strip the
/// fragment) as long as `decode(encode(tree))` round-trips.
abstract interface class RouteUrlCodec<R extends RouteNode> {
  /// Projects the whole [roots] tree to a single [Uri].
  Uri encode(List<R> roots);

  /// Reconstructs the [roots] tree from [uri].
  List<R> decode(Uri uri);
}
