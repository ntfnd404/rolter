import 'package:rolter/src/model/route_node.dart';
import 'package:rolter/src/model/route_registry.dart';

/// Encodes the navigation tree to a [Uri] and back, generically, via the
/// [RouteRegistry].
///
/// Grammar (octopus dot-depth scheme): each node becomes one path segment
/// `"{'.' × depth}{name}"`, plus `"~k=v&k2=v2"` (keys sorted, percent-encoded)
/// when it has params. Root nodes are depth 0; each nesting level adds one
/// leading dot. Flat (no dots) and nested (dots) use the same code.
class TreeUrlCodec<R extends RouteNode> {
  /// Creates a codec that decodes nodes via [_registry].
  const TreeUrlCodec(this._registry);
  final RouteRegistry<R> _registry;

  /// Projects the whole [roots] tree to a single [Uri].
  Uri encode(List<R> roots) {
    final segments = <String>[];

    void encodeNode(RouteNode node, int depth) {
      final prefix = '.' * depth;
      final params = node.toParams();
      if (params.isEmpty) {
        segments.add('$prefix${node.name}');
      } else {
        final entries = params.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        final query = entries
            .map((e) {
              final key = Uri.encodeComponent(e.key);
              final value = Uri.encodeComponent(e.value);
              return '$key=$value';
            })
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

  /// Reconstructs the [roots] tree from [uri].
  List<R> decode(Uri uri) =>
      _parseSegments(List<String>.of(uri.pathSegments), 0);

  List<R> _parseSegments(List<String> segments, int depth) {
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
      final tildeIndex = body.indexOf('~');
      final name = tildeIndex == -1 ? body : body.substring(0, tildeIndex);
      final params = tildeIndex == -1
          ? <String, String>{}
          : _parseParams(body.substring(tildeIndex + 1));
      final children = _parseSegments(segments, currentDepth + 1);
      result.add(_registry.decode(name, params, children));
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
