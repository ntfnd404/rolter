import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

/// Minimal node whose identity (key + equality) derives from name + params, so
/// codec round-trips can be asserted by value.
@immutable
class _Node implements RouteNode {
  const _Node(this.name, {this.params = const {}, this.children = const []});

  @override
  final String name;
  final Map<String, String> params;
  @override
  final List<RouteNode> children;

  @override
  LocalKey get pageKey => ValueKey('$name~$params');

  @override
  Map<String, String> toParams() => params;

  @override
  RouteNode withChildren(List<RouteNode> children) =>
      _Node(name, params: params, children: children);

  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: SizedBox());

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

void main() {
  final registry = RouteRegistry<_Node>(
    {
      'a': (p, c) => _Node('a', params: p, children: c),
      'b': (p, c) => _Node('b', params: p, children: c),
      'c': (p, c) => _Node('c', params: p, children: c),
    },
    fallback: (uri) => _Node('not-found', params: {'u': uri.toString()}),
  );
  final codec = TreeUrlCodec<_Node>(registry);

  String roundTrip(String value) {
    final encoded = codec.encode([
      _Node('a', params: {'v': value}),
    ]);
    // Decode the encoded Uri directly...
    final direct = codec.decode(encoded).single.toParams()['v'];
    // ...and after a full platform serialize/reparse cycle.
    final reparsed = codec
        .decode(Uri.parse(encoded.toString()))
        .single
        .toParams()['v'];
    expect(reparsed, direct, reason: 'platform reparse differs from direct');
    return direct ?? '<null>';
  }

  group('TreeUrlCodec value round-trip (regression for double-decode)', () {
    const cases = <String, String>{
      'plain': 'home',
      'space': 'a b',
      'slash': 'a/b',
      'ampersand': 'a&b',
      'equals': 'a=b',
      'percent-literal': '100% off',
      'pre-encoded-looking': 'a%2Fb',
      'tilde': 'a~b',
      'unicode': 'café привет 🚀',
      'dot': '3.14',
      'plus': 'a+b',
      'hash': 'a#b',
      'question': 'a?b',
      'empty': '',
      'leading-dots': '..x',
      'json-ish': '{"id":5,"q":"a&b"}',
    };

    cases.forEach((label, value) {
      test('round-trips "$label"', () {
        expect(roundTrip(value), value);
      });
    });
  });

  group('TreeUrlCodec structure', () {
    test('encodes a flat stack with params (URL contract unchanged)', () {
      final uri = codec.encode([
        const _Node('a'),
        const _Node('b', params: {'id': '2'}),
      ]);
      expect(uri.toString(), '/a/b~id=2');
    });

    test('sorts param keys for a canonical URL', () {
      final uri = codec.encode([
        const _Node('a', params: {'z': '1', 'a': '2'}),
      ]);
      expect(uri.toString(), '/a~a=2&z=1');
    });

    test('round-trips a nested tree', () {
      final uri = Uri.parse('/a/.b~id=2/..c');
      expect(codec.encode(codec.decode(uri)).toString(), uri.toString());
    });

    test('round-trips two parallel nested subtrees (multi-tab shape)', () {
      // One parent with two independent child stacks — the shape behind the
      // multi-tab "each tab keeps its own stack, all in the URL" example.
      const tree = [
        _Node(
          'a',
          children: [
            _Node('b', params: {'t': '1'}, children: [_Node('c')]),
            _Node('b', params: {'t': '2'}),
          ],
        ),
      ];
      expect(codec.decode(codec.encode(tree)), tree);
    });

    test('round-trips deep nesting by value', () {
      const tree = [
        _Node(
          'a',
          params: {'x': 'A B'},
          children: [
            _Node('b', params: {'y': 'c/d'}, children: [_Node('c')]),
          ],
        ),
      ];
      final decoded = codec.decode(codec.encode(tree));
      expect(decoded, tree);
    });
  });

  group('TreeUrlCodec standard ?query interop', () {
    test('merges a query into the top route params', () {
      final decoded = codec.decode(Uri.parse('/a?id=5'));
      expect(decoded.single.toParams(), {'id': '5'});
    });

    test('inline ~params win over query on a key conflict', () {
      final decoded = codec.decode(Uri.parse('/a~id=5?id=9'));
      expect(decoded.single.toParams(), {'id': '5'});
    });

    test('merges only into the last (top) root node', () {
      final decoded = codec.decode(Uri.parse('/a/b?id=5'));
      expect(decoded.map((r) => r.toParams()), [
        <String, String>{},
        {'id': '5'},
      ]);
    });

    test('a query alongside inline params keeps both', () {
      final decoded = codec.decode(Uri.parse('/a~k=v?utm=x'));
      expect(decoded.single.toParams(), {'k': 'v', 'utm': 'x'});
    });
  });

  group('TreeUrlCodec route-name safety', () {
    test('a URL-unsafe name is rejected in every build mode', () {
      expect(
        () => codec.encode([const _Node('bad name')]),
        throwsArgumentError,
      );
    });

    test('a safe name encodes fine', () {
      expect(codec.encode([const _Node('ok-name_1')]).toString(), '/ok-name_1');
    });
  });

  group('TreeUrlCodec lenient/malformed decode', () {
    test('drops trailing and doubled slashes instead of falling back', () {
      expect(codec.decode(Uri.parse('/a/')).map((r) => r.name), ['a']);
      expect(codec.decode(Uri.parse('/a//b')).map((r) => r.name), ['a', 'b']);
    });

    test('empty path decodes to an empty stack', () {
      expect(codec.decode(Uri.parse('/')), isEmpty);
      expect(codec.decode(Uri.parse('')), isEmpty);
    });

    test('unknown name falls back', () {
      final decoded = codec.decode(Uri.parse('/a/zzz'));
      expect(decoded.map((r) => r.name), ['a', 'not-found']);
    });

    test('a dots-only segment is skipped, not a fallback', () {
      expect(codec.decode(Uri.parse('/a/./b')).map((r) => r.name), [
        'a',
        'b',
      ]);
    });

    test('a param part without "=" is skipped', () {
      final decoded = codec.decode(Uri.parse('/a~bogus&id=2'));
      expect(decoded.single.toParams(), {'id': '2'});
    });
  });
}
