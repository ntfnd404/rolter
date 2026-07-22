import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support/test_route.dart';

/// A leaf route that derives equality from [pageKey] via [KeyedRouteEquality].
final class _Leaf with KeyedRouteEquality {
  const _Leaf(this.id);

  final int id;

  @override
  String get name => 'leaf';

  @override
  List<RouteNode> get children => const [];

  @override
  LocalKey get pageKey => ValueKey('leaf:$id');

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;

  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: SizedBox());
}

/// Another leaf with the same key shape but a different runtime type.
final class _OtherLeaf with KeyedRouteEquality {
  const _OtherLeaf(this.id);

  final int id;

  @override
  String get name => 'other';

  @override
  List<RouteNode> get children => const [];

  @override
  LocalKey get pageKey => ValueKey('leaf:$id');

  @override
  Map<String, String> toParams() => {'id': '$id'};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;

  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: SizedBox());
}

/// A shell that only allows children named `ok`.
class _StrictShell implements RouteNode, StrictHierarchy {
  const _StrictShell(this.children);

  @override
  final List<RouteNode> children;

  @override
  String get name => 'strict';

  @override
  LocalKey get pageKey => const ValueKey('strict');

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => _StrictShell(children);

  @override
  Page<Object?> buildPage(BuildContext context) =>
      const MaterialPage(child: SizedBox());

  @override
  bool allowsChild(RouteNode child) => child.name == 'ok';
}

void main() {
  group('KeyedRouteEquality', () {
    test('equal when runtimeType and pageKey match', () {
      expect(const _Leaf(1), const _Leaf(1));
      expect(const _Leaf(1).hashCode, const _Leaf(1).hashCode);
    });

    test('not equal when pageKey differs', () {
      expect(const _Leaf(1), isNot(const _Leaf(2)));
    });

    test('not equal across runtime types even with the same key', () {
      expect(const _Leaf(1), isNot(const _OtherLeaf(1)));
    });
  });

  group('RoutesState contract assertions', () {
    RoutesState<RouteNode> state() => RoutesState<RouteNode>(
          const [TestRoute('initial')],
          (requested) => requested,
        );

    test('accepts unique keys and an allowed hierarchy', () async {
      final routes = state();
      routes.setRoot([
        const TestRoute('a'),
        const _StrictShell([TestRoute('ok')]),
      ]);
      await routes.processingCompleted;
      expect(routes.root, hasLength(2));
    });

    test('rejects a duplicate key across nesting levels', () async {
      final routes = state();
      routes.setRoot([
        const TestRoute('a'),
        const TestRoute('b', children: [TestRoute('a')]),
      ]);
      await expectLater(
        routes.processingCompleted,
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'message',
            contains('duplicate pageKey'),
          ),
        ),
      );
    });

    test('rejects a strict-hierarchy violation', () async {
      final routes = state();
      routes.setRoot([
        const _StrictShell([TestRoute('bad')]),
      ]);
      await expectLater(
        routes.processingCompleted,
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'message',
            contains('does not allow child "bad"'),
          ),
        ),
      );
    });
  });
}
