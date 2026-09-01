import 'dart:convert';

import 'route_node.dart';
import 'route_registry.dart';
import 'route_url_codec.dart';

/// A compact [RouteUrlCodec] that serialises the whole tree to base64url JSON
/// in a single path segment (e.g. `/eyJuIjoiaG9tZSJ9`).
///
/// Use it when the dot-depth URL would be mangled by an intermediary —
/// typically OAuth / Telegram redirects that strip the fragment and rewrite the
/// path: the
/// entire navigation state survives as one compact token. The trade-off is that
/// the URL is no longer human-readable or hand-editable, so keep the default
/// [TreeUrlCodec] unless you specifically need this.
///
/// Decoding via the [RouteRegistry] is identical to [TreeUrlCodec] (same typed
/// nodes, same sub-registry mounts); only the wire format differs. At the raw
/// codec boundary an empty tree round-trips through `/`. A malformed, empty,
/// or wholly invalid non-root token resolves through the registry's app-owned
/// fallback, so external input cannot become an empty root Router stack.
///
/// Base64url is reversible encoding, not encryption, integrity protection, or
/// authentication. Anyone can read and forge a token. Never place secrets,
/// credentials, or personal data in it, and validate decoded route semantics
/// before use. Protected data and operations still require server-side
/// authorization.
class Base64RouteCodec<R extends RouteNode> implements RouteUrlCodec<R> {
  /// Creates a codec that decodes nodes via [_registry].
  const Base64RouteCodec(this._registry);

  final RouteRegistry<R> _registry;

  /// Encodes [roots] as one base64url JSON path segment.
  ///
  /// The raw codec value for an empty tree is `/`. When this codec is used with
  /// `RoutingInformationParser`, that URI is resolved by the parser's
  /// application-owned root callback rather than restored as an empty Router
  /// configuration.
  @override
  Uri encode(List<R> roots) {
    // Keep the empty value aligned with TreeUrlCodec. Encoding `[]` as a
    // non-root token would let external input bypass root-path resolution.
    if (roots.isEmpty) {
      return Uri(path: '/');
    }
    final payload = jsonEncode([for (final node in roots) _toJson(node)]);
    final token = base64Url.encode(utf8.encode(payload));

    return Uri(path: '/$token');
  }

  Map<String, Object?> _toJson(RouteNode node) {
    final params = node.toParams();

    return <String, Object?>{
      'n': node.name,
      if (params.isNotEmpty) 'p': params,
      if (node.children.isNotEmpty)
        'c': [for (final child in node.children) _toJson(child)],
    };
  }

  /// Decodes the first non-empty path segment into typed route nodes.
  ///
  /// Additional path segments are ignored for compatibility with the 0.3.0
  /// decoder; encoding the resulting tree produces the canonical single-segment
  /// URL. In a mixed list, registered nodes are retained, unknown names use the
  /// registry's existing fallback, and structurally invalid entries are
  /// skipped. An optional `c` field must be `null` or a JSON list; another type
  /// makes the containing entry structurally invalid.
  ///
  /// `/` is the raw empty representation. Malformed JSON, a non-list payload,
  /// an empty list token, or a payload with no valid node uses the registry's
  /// fallback for the original URI. Valid nodes in a partially malformed list
  /// are retained.
  @override
  List<R> decode(Uri uri) {
    final token = [
      for (final segment in uri.path.split('/'))
        if (segment.isNotEmpty) segment,
    ].firstOrNull;
    if (token == null) {
      return <R>[];
    }
    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(base64Url.decode(token)));
    } on FormatException {
      return <R>[_registry.fallback(uri)];
    }
    if (decoded is! List) {
      return <R>[_registry.fallback(uri)];
    }

    // Application-owned decoders and fallbacks deliberately run outside the
    // wire-format catch above so their errors retain exact identity and stack.
    final routes = _fromJson(decoded, _registry);
    return routes.isEmpty ? <R>[_registry.fallback(uri)] : routes;
  }

  List<R> _fromJson(List<Object?> data, RouteRegistry<R> registry) {
    final result = <R>[];
    for (final raw in data) {
      if (raw is! Map) {
        continue;
      }
      final name = raw['n'];
      if (name is! String || name.isEmpty) {
        continue;
      }
      final rawParams = raw['p'];
      if (rawParams != null && rawParams is! Map) {
        continue;
      }
      final params = <String, String>{
        for (final entry in (rawParams as Map? ?? const {}).entries)
          '${entry.key}': '${entry.value}',
      };
      final childRegistry = registry.childRegistryOf(name) ?? registry;
      final Object? childData = raw['c'];
      final List<R> children;
      if (childData == null) {
        children = <R>[];
      } else if (childData is List<Object?>) {
        children = _fromJson(childData, childRegistry);
      } else {
        continue;
      }
      result.add(registry.decode(name, params, children));
    }

    return result;
  }
}
