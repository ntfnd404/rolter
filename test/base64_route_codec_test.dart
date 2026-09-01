import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

/// Value-equal node (equality over name + params + children; [tag] records the
/// registry that built it but does not affect equality).
@immutable
class _Node implements RouteNode {
  const _Node(
    this.name, {
    this.params = const {},
    this.children = const [],
    this.tag = '',
  });

  @override
  final String name;
  final Map<String, String> params;
  final String tag;
  @override
  final List<RouteNode> children;

  @override
  LocalKey get pageKey => ValueKey('$name~$params');

  @override
  Map<String, String> toParams() => params;

  @override
  RouteNode withChildren(List<RouteNode> children) =>
      _Node(name, params: params, children: children, tag: tag);

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAllUnordered(
      params.entries.map((e) => '${e.key}=${e.value}'),
    ),
    Object.hashAll(children),
  );

  @override
  bool operator ==(Object other) =>
      other is _Node &&
      other.name == name &&
      mapEquals(other.params, params) &&
      listEquals(other.children, children);
}

({Object error, StackTrace stackTrace}) _captureSyncError(
  Object? Function() action,
) {
  try {
    action();
  } on Object catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }
  fail('Expected the action to throw.');
}

void main() {
  final shopRegistry = RouteRegistry<_Node>(
    {'detail': (p, c) => _Node('detail', params: p, children: c, tag: 'shop:')},
    fallback: (uri) => const _Node('not-found'),
  );
  final registry = RouteRegistry<_Node>(
    {
      'home': (p, c) => _Node('home', params: p, children: c),
      'shop': (p, c) => _Node('shop', params: p, children: c),
    },
    fallback: (uri) => const _Node('not-found'),
    children: {'shop': shopRegistry},
  );
  final codec = Base64RouteCodec<_Node>(registry);

  test('round-trips a flat stack with tricky params (JSON-wrapped)', () {
    const tree = [
      _Node('home', params: {'q': 'a&b/c %x ~ё'}),
    ];
    expect(codec.decode(codec.encode(tree)), tree);
  });

  test('round-trips a mounted subtree, resolved via sub-registry', () {
    const tree = [
      _Node(
        'shop',
        children: [
          _Node('detail', params: {'id': '1'}),
        ],
      ),
    ];
    final decoded = codec.decode(codec.encode(tree));

    expect(decoded, tree);
    expect((decoded.single.children.single as _Node).tag, 'shop:');
  });

  test('encodes to a single compact path segment (no readable names)', () {
    final uri = codec.encode([const _Node('home')]);

    expect(uri.pathSegments.length, 1);
    expect(uri.toString(), isNot(contains('home')));
  });

  test('round-trips the raw empty tree through the root path', () {
    expect(codec.encode(const <_Node>[]), Uri(path: '/'));
    expect(codec.decode(Uri.parse('/')), isEmpty);
  });

  test('malformed and empty-list tokens use the registry fallback', () {
    final emptyToken = base64Url.encode(utf8.encode('[]'));
    final nonListToken = base64Url.encode(utf8.encode('{}'));
    final invalidEntriesToken = base64Url.encode(utf8.encode('[null, 1]'));
    final invalidUtf8Token = base64Url.encode(const <int>[0xff]);
    final invalidJsonToken = base64Url.encode(utf8.encode('{'));
    Uri? attempted;
    final fallbackCodec = Base64RouteCodec<_Node>(
      RouteRegistry<_Node>(
        const <String, RouteDecoder<_Node>>{},
        fallback: (uri) {
          attempted = uri;
          return const _Node('not-found');
        },
      ),
    );

    for (final uri in <Uri>[
      Uri.parse('/!!!!?source=base64#malformed'),
      Uri(path: '/$invalidUtf8Token'),
      Uri(path: '/$invalidJsonToken'),
      Uri(path: '/$emptyToken'),
      Uri(path: '/$nonListToken'),
      Uri(path: '/$invalidEntriesToken'),
    ]) {
      attempted = null;
      expect(fallbackCodec.decode(uri), const <_Node>[_Node('not-found')]);
      expect(attempted, same(uri));
    }
  });

  test('preserves a registered decoder FormatException and stack', () {
    const expected = FormatException('decoder failed');
    final expectedStack = StackTrace.current;
    var fallbackCalls = 0;
    final throwingCodec = Base64RouteCodec<_Node>(
      RouteRegistry<_Node>(
        {
          'throwing': (params, children) => Error.throwWithStackTrace(
            expected,
            expectedStack,
          ),
        },
        fallback: (uri) {
          fallbackCalls++;
          return const _Node('not-found');
        },
      ),
    );
    final token = base64Url.encode(
      utf8.encode(
        jsonEncode([
          {'n': 'throwing'},
        ]),
      ),
    );

    final failure = _captureSyncError(
      () => throwingCodec.decode(Uri(path: '/$token')),
    );

    expect(failure.error, same(expected));
    expect(failure.stackTrace, same(expectedStack));
    expect(fallbackCalls, 0);
  });

  test('calls a throwing whole-payload fallback exactly once', () {
    const expected = FormatException('fallback failed');
    final expectedStack = StackTrace.current;
    var fallbackCalls = 0;
    final throwingCodec = Base64RouteCodec<_Node>(
      RouteRegistry<_Node>(
        const <String, RouteDecoder<_Node>>{},
        fallback: (uri) {
          fallbackCalls++;
          Error.throwWithStackTrace(expected, expectedStack);
        },
      ),
    );
    final nonListToken = base64Url.encode(utf8.encode('{}'));
    final invalidJsonToken = base64Url.encode(utf8.encode('{'));

    for (final token in <String>[nonListToken, invalidJsonToken]) {
      fallbackCalls = 0;
      final failure = _captureSyncError(
        () => throwingCodec.decode(Uri(path: '/$token')),
      );

      expect(failure.error, same(expected));
      expect(failure.stackTrace, same(expectedStack));
      expect(fallbackCalls, 1);
    }
  });

  test('preserves an unknown-node fallback error inside a mixed payload', () {
    const expected = FormatException('unknown route failed');
    final expectedStack = StackTrace.current;
    var fallbackCalls = 0;
    final throwingCodec = Base64RouteCodec<_Node>(
      RouteRegistry<_Node>(
        {'home': (params, children) => const _Node('home')},
        fallback: (uri) {
          fallbackCalls++;
          Error.throwWithStackTrace(expected, expectedStack);
        },
      ),
    );
    final token = base64Url.encode(
      utf8.encode(
        jsonEncode([
          {'n': 'home'},
          {'n': 'unknown'},
        ]),
      ),
    );

    final failure = _captureSyncError(
      () => throwingCodec.decode(Uri(path: '/$token')),
    );

    expect(failure.error, same(expected));
    expect(failure.stackTrace, same(expectedStack));
    expect(fallbackCalls, 1);
  });

  test('skips a node whose params are not a JSON object', () {
    final payload = jsonEncode([
      {'n': 'home', 'p': <Object?>[]},
      {
        'n': 'home',
        'p': {'safe': 'value'},
      },
    ]);
    final token = base64Url.encode(utf8.encode(payload));

    expect(codec.decode(Uri(path: '/$token')), [
      const _Node('home', params: {'safe': 'value'}),
    ]);
  });

  test('keeps legacy string coercion for JSON parameter values', () {
    final payload = jsonEncode([
      {
        'n': 'home',
        'p': {'number': 42, 'enabled': true},
        'ignored': 'extra-field',
      },
    ]);
    final token = base64Url.encode(utf8.encode(payload));

    expect(codec.decode(Uri(path: '/$token')), const <_Node>[
      _Node('home', params: {'number': '42', 'enabled': 'true'}),
    ]);
  });

  test('keeps valid nodes, falls back unknown names, and skips malformed', () {
    final payload = jsonEncode([
      {
        'n': 'home',
        'p': {'safe': 'value'},
      },
      {'n': 'unknown'},
      {'n': 'home', 'p': <Object?>[]},
      null,
    ]);
    final token = base64Url.encode(utf8.encode(payload));

    expect(codec.decode(Uri(path: '/$token')), const <_Node>[
      _Node('home', params: {'safe': 'value'}),
      _Node('not-found'),
    ]);
  });

  test('skips a node whose children field is not a JSON list', () {
    final payload = jsonEncode([
      {'n': 'home'},
      {'n': 'home', 'c': 42},
      {'n': 'unknown'},
    ]);
    final token = base64Url.encode(utf8.encode(payload));

    expect(codec.decode(Uri(path: '/$token')), const <_Node>[
      _Node('home'),
      _Node('not-found'),
    ]);
  });

  test('all-invalid children fields use the original-uri fallback', () {
    Uri? attempted;
    final fallbackCodec = Base64RouteCodec<_Node>(
      RouteRegistry<_Node>(
        {'home': (params, children) => const _Node('home')},
        fallback: (uri) {
          attempted = uri;
          return const _Node('not-found');
        },
      ),
    );
    final token = base64Url.encode(
      utf8.encode(
        jsonEncode([
          {'n': 'home', 'c': 42},
        ]),
      ),
    );
    final uri = Uri.parse('/$token?source=invalid-children#fragment');

    expect(fallbackCodec.decode(uri), const <_Node>[_Node('not-found')]);
    expect(attempted, same(uri));
  });

  test('accepts absent, null, and list-valued children fields', () {
    final payload = jsonEncode([
      {'n': 'home'},
      {'n': 'home', 'c': null},
      {
        'n': 'shop',
        'c': [
          {'n': 'detail'},
        ],
      },
    ]);
    final token = base64Url.encode(utf8.encode(payload));

    final decoded = codec.decode(Uri(path: '/$token'));

    expect(decoded, const <_Node>[
      _Node('home'),
      _Node('home'),
      _Node('shop', children: <RouteNode>[_Node('detail')]),
    ]);
    expect((decoded.last.children.single as _Node).tag, 'shop:');
  });

  test('decodes only the first non-empty path segment', () {
    const roots = <_Node>[_Node('home')];
    final token = codec.encode(roots).pathSegments.single;

    final decoded = codec.decode(Uri(path: '/$token/ignored'));

    expect(decoded, roots);
    expect(codec.encode(decoded).pathSegments, <String>[token]);
  });
}
