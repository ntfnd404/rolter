import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

/// Minimal [RouteNode] for exercising the tree + codec.
class _R implements RouteNode {
  const _R(this.name, {this.params = const {}, this.children = const []});

  @override
  final String name;

  final Map<String, String> params;

  @override
  final List<RouteNode> children;

  @override
  LocalKey get pageKey => ValueKey(name);

  @override
  Map<String, String> toParams() => params;

  @override
  RouteNode withChildren(List<RouteNode> children) =>
      _R(name, params: params, children: children);

  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: SizedBox());
}

void main() {
  group('route_tree', () {
    test('removeNodeByKey removes the matching node', () {
      final roots = [const _R('a'), const _R('b')];
      final result = removeNodeByKey(roots, const ValueKey('b'));
      expect(result.map((r) => r.name), ['a']);
    });

    test('nodeAtPath descends by name', () {
      final tree = [
        const _R(
          'a',
          children: [
            _R('b', children: [_R('c')]),
          ],
        ),
      ];
      expect(nodeAtPath(tree, ['a', 'b', 'c'])?.name, 'c');
      expect(nodeAtPath(tree, ['a', 'x']), isNull);
    });

    test('mutateNodeAt copies the spine and transforms the target', () {
      final tree = [
        const _R('a', children: [_R('b')]),
      ];
      final result = mutateNodeAt<_R>(
        tree,
        ['a', 'b'],
        (node) => const _R('b', children: [_R('c')]),
      );
      expect(nodeAtPath(result, ['a', 'b', 'c'])?.name, 'c');
      // Original is untouched (immutable).
      expect(nodeAtPath(tree, ['a', 'b', 'c']), isNull);
    });

    test('collectPageKeys gathers the whole tree', () {
      final tree = [
        const _R('a', children: [_R('b')]),
        const _R('c'),
      ];
      expect(collectPageKeys(tree), {
        const ValueKey('a'),
        const ValueKey('b'),
        const ValueKey('c'),
      });
    });
  });

  group('TreeUrlCodec', () {
    final registry = RouteRegistry<_R>(
      {
        'a': (params, children) => _R('a', params: params, children: children),
        'b': (params, children) => _R('b', params: params, children: children),
        'c': (params, children) => _R('c', params: params, children: children),
      },
      fallback: (uri) => const _R('not-found'),
    );
    final codec = TreeUrlCodec<_R>(registry);

    test('encodes a flat stack with params', () {
      final uri = codec.encode([
        const _R('a'),
        const _R('b', params: {'id': '2'}),
      ]);
      expect(uri.toString(), '/a/b~id=2');
    });

    test('round-trips a nested tree through the URL', () {
      final uri = Uri.parse('/a/.b~id=2/..c');
      expect(codec.encode(codec.decode(uri)).toString(), uri.toString());
    });

    test('drops empty path segments instead of falling back', () {
      // Trailing slash (`/a/`) and a doubled slash must not yield not-found.
      expect(codec.decode(Uri.parse('/a/')).map((r) => r.name), ['a']);
      expect(codec.decode(Uri.parse('/a//b')).map((r) => r.name), ['a', 'b']);
    });
  });
}
