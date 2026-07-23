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
/// nodes, same sub-registry mounts); only the wire format differs. A malformed
/// token decodes to an empty stack (the app's `normalize` restores a root).
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

  @override
  Uri encode(List<R> roots) {
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

  @override
  List<R> decode(Uri uri) {
    final token = [
      for (final segment in uri.path.split('/'))
        if (segment.isNotEmpty) segment,
    ].firstOrNull;
    if (token == null) {
      return <R>[];
    }
    try {
      final decoded = jsonDecode(utf8.decode(base64Url.decode(token)));
      if (decoded is! List) {
        return <R>[];
      }

      return _fromJson(decoded, _registry);
    } on FormatException {
      return <R>[];
    }
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
      final childData = raw['c'];
      final children = childData is List
          ? _fromJson(childData, childRegistry)
          : <R>[];
      result.add(registry.decode(name, params, children));
    }

    return result;
  }
}
