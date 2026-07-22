import 'route_node.dart';

/// Builds a typed [R] node from its decoded URL [params] and already-decoded
/// [children]. One decoder is registered per route name.
typedef RouteDecoder<R extends RouteNode> = R Function(
  Map<String, String> params,
  List<R> children,
);

/// Maps a route name to its decoder (Option B): the engine decodes the tree
/// generically; the app only registers typed routes.
///
/// A name can also be a **mount**: present in both `_decoders` (which builds
/// the shell node) and `children` (a feature-owned sub-registry that decodes
/// the node's subtree). The codec switches to the sub-registry for a mount's
/// children, so a feature owns its own URL-name namespace — two features can
/// each have a `detail` route without colliding. (Page keys remain global, so
/// keep those unique across the whole tree regardless.)
class RouteRegistry<R extends RouteNode> {
  /// Creates a registry from [_decoders], using [fallback] for unknown names.
  /// `children` mounts a sub-registry under a name to decode its subtree.
  const RouteRegistry(
    this._decoders, {
    required this.fallback,
    Map<String, RouteRegistry<R>> children = const {},
    // A named param cannot bind a private field, so assign in the initializer.
  }) : _children = children; // ignore: prefer_initializing_formals

  /// Builds a fallback node (e.g. not-found) for an unknown name.
  final R Function(Uri attempted) fallback;

  final Map<String, RouteDecoder<R>> _decoders;
  final Map<String, RouteRegistry<R>> _children;

  /// Decodes one node by [name], falling back when no decoder is registered.
  R decode(String name, Map<String, String> params, List<R> children) {
    final decoder = _decoders[name];
    if (decoder == null) {
      return fallback(Uri(path: '/$name'));
    }

    return decoder(params, children);
  }

  /// The sub-registry that decodes the children of a mount named [name], or
  /// `null` if [name] is not a mount (its children use this registry).
  RouteRegistry<R>? childRegistryOf(String name) => _children[name];
}
