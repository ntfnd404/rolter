import 'route_name.dart';
import 'route_node.dart';

/// Builds a typed [R] node from its decoded URL [params] and already-decoded
/// [children]. One decoder is registered per route name.
typedef RouteDecoder<R extends RouteNode> =
    R Function(
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
  /// Creates an immutable registry from [decoders].
  ///
  /// Decoder and child-registry maps are copied, so later mutations of the
  /// supplied maps do not reconfigure this registry. Every registered name and
  /// child-registry key must match `[A-Za-z0-9_-]+`. A conventional mount has
  /// both a shell decoder and a child registry, but fallback-based
  /// configurations are not prohibited. [fallback] handles unknown names.
  RouteRegistry(
    Map<String, RouteDecoder<R>> decoders, {
    required this.fallback,
    Map<String, RouteRegistry<R>> children = const {},
  }) : _decoders = Map<String, RouteDecoder<R>>.unmodifiable(
         Map<String, RouteDecoder<R>>.of(decoders),
       ),
       _children = Map<String, RouteRegistry<R>>.unmodifiable(
         Map<String, RouteRegistry<R>>.of(children),
       ) {
    for (final name in _decoders.keys) {
      validateRouteName(name, argumentName: 'decoders');
    }
    for (final name in _children.keys) {
      validateRouteName(name, argumentName: 'children');
    }
  }

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
