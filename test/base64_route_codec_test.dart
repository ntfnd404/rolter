import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: SizedBox());

  @override
  int get hashCode => Object.hash(
    name,
    Object.hashAllUnordered(params.entries.map((e) => '${e.key}=${e.value}')),
    Object.hashAll(children),
  );

  @override
  bool operator ==(Object other) =>
      other is _Node &&
      other.name == name &&
      mapEquals(other.params, params) &&
      listEquals(other.children, children);
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
      _Node('shop', children: [_Node('detail', params: {'id': '1'})]),
    ];
    final decoded = codec.decode(codec.encode(tree));

    expect(decoded, tree);
    expect((decoded.single.children.single as _Node).tag, 'shop:');
  });

  test('encodes to a single opaque path segment (no readable names)', () {
    final uri = codec.encode([const _Node('home')]);

    expect(uri.pathSegments.length, 1);
    expect(uri.toString(), isNot(contains('home')));
  });

  test('a malformed or empty token decodes to an empty stack', () {
    expect(codec.decode(Uri.parse('/!!!!')), isEmpty);
    expect(codec.decode(Uri.parse('/')), isEmpty);
  });
}
