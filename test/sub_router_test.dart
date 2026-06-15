import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

/// Test node that records which registry built it via [tag].
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
  LocalKey get pageKey => ValueKey('$tag$name~$params');

  @override
  Map<String, String> toParams() => params;

  @override
  RouteNode withChildren(List<RouteNode> children) =>
      _Node(name, params: params, children: children, tag: tag);

  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: SizedBox());
}

String _tagOf(RouteNode node) => (node as _Node).tag;

void main() {
  // Two feature sub-registries that BOTH define a `detail` route.
  final shopRegistry = RouteRegistry<_Node>(
    {'detail': (p, c) => _Node('detail', params: p, children: c, tag: 'shop:')},
    fallback: (uri) => const _Node('shop-404', tag: 'shop:'),
  );
  final blogRegistry = RouteRegistry<_Node>(
    {'detail': (p, c) => _Node('detail', params: p, children: c, tag: 'blog:')},
    fallback: (uri) => const _Node('blog-404', tag: 'blog:'),
  );

  final root = RouteRegistry<_Node>(
    {
      'shop': (p, c) => _Node('shop', params: p, children: c, tag: 'root:'),
      'blog': (p, c) => _Node('blog', params: p, children: c, tag: 'root:'),
    },
    fallback: (uri) => const _Node('not-found', tag: 'root:'),
    children: {'shop': shopRegistry, 'blog': blogRegistry},
  );
  final codec = TreeUrlCodec<_Node>(root);

  group('sub-router decode', () {
    test('a mount child is decoded by its sub-registry', () {
      final decoded = codec.decode(Uri.parse('/shop/.detail~id=1'));
      final shop = decoded.single;
      expect(shop.name, 'shop');
      expect(_tagOf(shop), 'root:');
      final detail = shop.children.single;
      expect(detail.name, 'detail');
      expect(_tagOf(detail), 'shop:');
      expect(detail.toParams(), {'id': '1'});
    });

    test('same child name resolves per mount (isolation)', () {
      final shopDetail = codec
          .decode(Uri.parse('/shop/.detail'))
          .single
          .children
          .single;
      final blogDetail = codec
          .decode(Uri.parse('/blog/.detail'))
          .single
          .children
          .single;
      expect(shopDetail.name, blogDetail.name); // both literally "detail"
      expect(_tagOf(shopDetail), 'shop:');
      expect(_tagOf(blogDetail), 'blog:');
    });

    test('an unknown child name uses the sub-registry fallback', () {
      final child = codec.decode(Uri.parse('/shop/.zzz')).single.children.single;
      expect(_tagOf(child), 'shop:');
      expect(child.name, 'shop-404');
    });

    test('a mount with no children decodes to just the shell', () {
      final decoded = codec.decode(Uri.parse('/shop'));
      expect(decoded.single.name, 'shop');
      expect(decoded.single.children, isEmpty);
    });

    test('round-trips a mounted subtree through the URL', () {
      final uri = Uri.parse('/shop/.detail~id=1/blog/.detail~id=2');
      expect(codec.encode(codec.decode(uri)).toString(), uri.toString());
    });
  });

  group('RouteRegistry.childRegistryOf', () {
    test('returns the sub-registry for a mount, null otherwise', () {
      expect(root.childRegistryOf('shop'), same(shopRegistry));
      expect(root.childRegistryOf('detail'), isNull);
    });
  });

  group('composeFeatureRouters', () {
    test('mounts each feature under its name and isolates child names', () {
      final composed = composeFeatureRouters<_Node>(
        fallback: (uri) => const _Node('not-found', tag: 'root:'),
        decoders: {
          'home': (p, c) => _Node('home', params: p, children: c, tag: 'root:'),
        },
        features: [
          FeatureRouter<_Node>(
            name: 'shop',
            mountDecoder: (p, c) =>
                _Node('shop', params: p, children: c, tag: 'root:'),
            registry: shopRegistry,
          ),
        ],
      );
      final composedCodec = TreeUrlCodec<_Node>(composed);

      expect(composed.childRegistryOf('shop'), same(shopRegistry));
      final detail = composedCodec
          .decode(Uri.parse('/shop/.detail'))
          .single
          .children
          .single;
      expect(_tagOf(detail), 'shop:');
      // A flat top-level decoder still works alongside the mount.
      expect(composedCodec.decode(Uri.parse('/home')).single.name, 'home');
    });
  });
}
