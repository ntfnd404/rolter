import 'package:rolter/src/model/route_node.dart';

/// Builds a typed [R] node from its decoded URL [params] and already-decoded
/// [children]. One decoder is registered per route name.
typedef RouteDecoder<R extends RouteNode> =
    R Function(
      Map<String, String> params,
      List<R> children,
    );

/// Maps a route name to its decoder (Option B): the engine decodes the tree
/// generically; the app only registers typed routes.
class RouteRegistry<R extends RouteNode> {
  /// Creates a registry from [_decoders], using [fallback] for unknown names.
  const RouteRegistry(this._decoders, {required this.fallback});

  /// Builds a fallback node (e.g. not-found) for an unknown name.
  final R Function(Uri attempted) fallback;

  final Map<String, RouteDecoder<R>> _decoders;

  /// Decodes one node by [name], falling back when no decoder is registered.
  R decode(String name, Map<String, String> params, List<R> children) {
    final decoder = _decoders[name];
    if (decoder == null) {
      return fallback(Uri(path: '/$name'));
    }

    return decoder(params, children);
  }
}
