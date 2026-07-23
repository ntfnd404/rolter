import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

/// Minimal [RouteNode] for exercising the tree + codec. Has explicit value
/// equality over [name] + [params] + [children] (not relying on `const`
/// canonicalisation).
@immutable
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

  @override
  int get hashCode => Object.hash(name, Object.hashAll(children));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _R &&
          other.name == name &&
          mapEquals(other.params, params) &&
          listEquals(other.children, children);
}

void main() {
  group('RoutesState tree operations', () {
    RoutesState<_R> state(List<_R> initial) =>
        RoutesState<_R>(initial, (requested) => requested);

    test('removeByPageKey removes the matching node', () async {
      final routes = state([const _R('a'), const _R('b')]);
      routes.removeByPageKey(const ValueKey('b'));
      await routes.processingCompleted;
      expect(routes.root.map((route) => route.name), ['a']);
    });

    test('mutateAt copies the spine and transforms the target', () async {
      final routes = state([
        const _R('a', children: [_R('b')]),
      ]);
      routes.mutateAt(
        ['a', 'b'],
        (node) => const _R('b', children: [_R('c')]),
      );
      await routes.processingCompleted;
      expect(routes.root.single.children.single.children.single.name, 'c');
    });

    test('popUntil keeps the topmost match and no-ops without one', () async {
      final routes = state([const _R('a'), const _R('b'), const _R('c')]);
      routes.popUntil((route) => route.name == 'b');
      await routes.processingCompleted;
      expect(routes.root.map((route) => route.name), ['a', 'b']);
      routes.popUntil((route) => route.name == 'z');
      await routes.processingCompleted;
      expect(routes.root.map((route) => route.name), ['a', 'b']);
    });

    test('removeWhere drops every matching node', () async {
      final routes = state([const _R('a'), const _R('b'), const _R('c')]);
      routes.removeWhere((route) => route.name != 'b');
      await routes.processingCompleted;
      expect(routes.root.map((route) => route.name), ['b']);
    });

    test('pushAndResetTo keeps a match or performs a full reset', () async {
      final routes = state([const _R('a'), const _R('b'), const _R('c')]);
      routes.pushAndResetTo(const _R('d'), (route) => route.name == 'a');
      await routes.processingCompleted;
      expect(routes.root.map((route) => route.name), ['a', 'd']);
      routes.pushAndResetTo(const _R('e'), (route) => route.name == 'z');
      await routes.processingCompleted;
      expect(routes.root.map((route) => route.name), ['e']);
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
