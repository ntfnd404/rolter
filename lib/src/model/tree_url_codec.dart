import 'route_node.dart';
import 'route_registry.dart';
import 'route_url_codec.dart';

/// Default [RouteUrlCodec]: encodes the navigation tree to a [Uri] and back,
/// generically, via the [RouteRegistry].
///
/// Grammar (depth-prefixed segments): each node becomes one path segment
/// `"{'.' × depth}{name}"`, plus `"~k=v&k2=v2"` (keys sorted, percent-encoded)
/// when it has params. Root nodes are depth 0; each nesting level adds one
/// leading dot, so the whole tree — flat or nested — round-trips through one
/// flat path.
class TreeUrlCodec<R extends RouteNode> implements RouteUrlCodec<R> {
  /// Creates a codec that decodes nodes via [_registry].
  const TreeUrlCodec(this._registry);
  final RouteRegistry<R> _registry;

  // Route names are written to the URL verbatim (not percent-encoded) and act
  // as the depth/param-delimited segment body, so they must be URL-path-safe.
  static final RegExp _safeName = RegExp(r'^[A-Za-z0-9_-]+$');

  /// Projects the whole [roots] tree to a single [Uri].
  @override
  Uri encode(List<R> roots) {
    final segments = <String>[];

    void encodeNode(RouteNode node, int depth) {
      assert(
        _safeName.hasMatch(node.name),
        'rolter: route name "${node.name}" is not URL-safe. Names are written '
        'verbatim and must match [A-Za-z0-9_-]+ (no "/", ".", "~", or spaces).',
      );
      final prefix = '.' * depth;
      final params = node.toParams();
      if (params.isEmpty) {
        segments.add('$prefix${node.name}');
      } else {
        final entries = params.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final query = entries
            .map((e) => '${_encodeParam(e.key)}=${_encodeParam(e.value)}')
            .join('&');
        segments.add('$prefix${node.name}~$query');
      }
      for (final child in node.children) {
        encodeNode(child, depth + 1);
      }
    }

    for (final node in roots) {
      encodeNode(node, 0);
    }

    return Uri(path: '/${segments.join('/')}');
  }

  // Percent-encodes a param key/value. `Uri.encodeComponent` leaves `~`
  // unescaped, but `~` is our name/params separator, so escape it explicitly —
  // the structural delimiters (`/ & =`) are already encoded by `encodeComponent`
  // and `.` only matters as a leading segment marker, never mid-value.
  static String _encodeParam(String s) =>
      Uri.encodeComponent(s).replaceAll('~', '%7E');

  /// Reconstructs the [roots] tree from [uri]. Empty path segments — a trailing
  /// slash (`/home/`), a leading or a doubled slash — are dropped, not treated
  /// as an unknown (not-found) route.
  ///
  /// Splits the **raw** (still percent-encoded) path rather than
  /// [Uri.pathSegments]. `pathSegments` percent-decodes once; combined with the
  /// per-param [Uri.decodeComponent] in [_parseParams] that would double-decode
  /// values (e.g. `a%2Fb → a/b`) and let an encoded `&`/`=` be mis-split
  /// (e.g. `a&b → a`). On the raw path the structural delimiters (`/ & =`,
  /// which `encodeComponent` always encodes) are unambiguous, so each key and
  /// value is decoded exactly once.
  ///
  /// A standard `?k=v` query (e.g. an external `/home?intent=stream`) is merged
  /// into the **top** route's params, so it behaves like the inline form
  /// (`/home~intent=stream`). Inline `~` params win on a key conflict (they are
  /// the canonical, round-trippable form). Params the top route does not model
  /// are dropped from the tree — use `EntryQueryStore` (via the parser) to keep
  /// them.
  @override
  List<R> decode(Uri uri) {
    final segments = <String>[
      for (final segment in uri.path.split('/'))
        if (segment.isNotEmpty) segment,
    ];
    final roots = _parseSegments(segments, 0, _registry);

    final query = uri.queryParameters;
    if (query.isEmpty || roots.isEmpty) {
      return roots;
    }
    final top = roots.last;
    final merged = _registry.decode(
      top.name,
      {
        ...query,
        ...top.toParams(),
      },
      top.children.cast<R>(),
    );

    return <R>[...roots.sublist(0, roots.length - 1), merged];
  }

  // [registry] decodes the nodes at this level; a mount's children are decoded
  // by its sub-registry (see [RouteRegistry.childRegistryOf]), giving a feature
  // its own URL-name namespace.
  List<R> _parseSegments(
    List<String> segments,
    int depth,
    RouteRegistry<R> registry,
  ) {
    final result = <R>[];
    while (segments.isNotEmpty) {
      final raw = segments.first;
      var currentDepth = 0;
      while (currentDepth < raw.length && raw[currentDepth] == '.') {
        currentDepth++;
      }
      if (currentDepth < depth) {
        break;
      }
      segments.removeAt(0);
      final body = raw.substring(currentDepth);
      if (body.isEmpty) {
        // A segment made only of dots — no name. Skip, don't fall back.
        continue;
      }
      final tildeIndex = body.indexOf('~');
      final name = tildeIndex == -1 ? body : body.substring(0, tildeIndex);
      final params = tildeIndex == -1
          ? <String, String>{}
          : _parseParams(body.substring(tildeIndex + 1));
      final childRegistry = registry.childRegistryOf(name) ?? registry;
      final children = _parseSegments(
        segments,
        currentDepth + 1,
        childRegistry,
      );
      result.add(registry.decode(name, params, children));
    }

    return result;
  }

  Map<String, String> _parseParams(String query) {
    final result = <String, String>{};
    for (final part in query.split('&')) {
      final separator = part.indexOf('=');
      if (separator <= 0) {
        continue;
      }
      try {
        final key = Uri.decodeComponent(part.substring(0, separator));
        final value = Uri.decodeComponent(part.substring(separator + 1));
        result[key] = value;
      } on FormatException {
        continue;
      }
    }

    return result;
  }
}
