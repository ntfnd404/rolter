import 'dart:async';

import 'package:flutter/foundation.dart';
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
  bool allowsChild(RouteNode child) => child.name == 'ok';
}

final class _HostileKey extends LocalKey {
  const _HostileKey(this.identity, this.onToString);

  final String identity;
  final VoidCallback onToString;

  @override
  int get hashCode => identity.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _HostileKey && other.identity == identity;

  @override
  String toString() {
    onToString();
    return 'secret:$identity';
  }
}

@immutable
final class _HostileKeyRoute implements RouteNode {
  const _HostileKeyRoute(this.pageKey);

  @override
  final LocalKey pageKey;

  @override
  String get name => 'hostile-key';

  @override
  List<RouteNode> get children => const [];

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;

  @override
  int get hashCode => pageKey.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _HostileKeyRoute && other.pageKey == pageKey;
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

  group('RoutesState page-key contract', () {
    RoutesState<RouteNode> state() => RoutesState<RouteNode>(const [
      TestRoute('initial'),
    ], (requested) => requested);

    test('rejects an invalid initial tree synchronously', () {
      expect(
        () => RoutesState<RouteNode>(const [
          TestRoute('a'),
          TestRoute('b', children: [TestRoute('a')]),
        ], (requested) => requested),
        throwsStateError,
      );
    });

    test('rejects a duplicate key without changing committed state', () async {
      final routes = state();
      addTearDown(routes.dispose);
      routes.setRoot([
        const TestRoute('a'),
        const TestRoute('b', children: [TestRoute('a')]),
      ]);
      await expectLater(
        routes.processingCompleted,
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('duplicate pageKey'),
          ),
        ),
      );
      expect(routes.root, const [TestRoute('initial')]);

      routes.setRoot(const [TestRoute('recovered')]);
      await routes.processingCompleted;
      expect(routes.root, const [TestRoute('recovered')]);
    });

    test('initial duplicate diagnostic never stringifies the page key', () {
      var toStringCalls = 0;
      final first = _HostileKey('tenant-user-42', () => toStringCalls++);
      final second = _HostileKey('tenant-user-42', () => toStringCalls++);
      late StateError error;

      try {
        RoutesState<RouteNode>([
          _HostileKeyRoute(first),
          _HostileKeyRoute(second),
        ], (requested) => requested);
      } on StateError catch (caught) {
        error = caught;
      }

      expect(error.message, contains('duplicate pageKey'));
      expect(error.message, isNot(contains('tenant-user-42')));
      expect(toStringCalls, 0);
    });

    test(
      'queued duplicate diagnostic never stringifies the page key',
      () async {
        var toStringCalls = 0;
        final first = _HostileKey('tenant-user-42', () => toStringCalls++);
        final second = _HostileKey('tenant-user-42', () => toStringCalls++);
        final routes = state();
        addTearDown(routes.dispose);

        routes.setRoot([_HostileKeyRoute(first), _HostileKeyRoute(second)]);
        late StateError error;
        try {
          await routes.processingCompleted;
        } on StateError catch (caught) {
          error = caught;
        }

        expect(error.message, contains('duplicate pageKey'));
        expect(error.message, isNot(contains('tenant-user-42')));
        expect(toStringCalls, 0);
      },
    );

    test('duplicate pending result never stringifies the page key', () async {
      var toStringCalls = 0;
      final first = _HostileKey('tenant-user-42', () => toStringCalls++);
      final second = _HostileKey('tenant-user-42', () => toStringCalls++);
      final routes = RoutesState<RouteNode>(const [
        TestRoute('home'),
      ], (requested) => requested);

      final result = routes.pushForResult<int>(_HostileKeyRoute(first));
      await routes.processingCompleted;
      late AssertionError error;
      try {
        unawaited(routes.pushForResult<int>(_HostileKeyRoute(second)));
      } on AssertionError catch (caught) {
        error = caught;
      }

      expect('$error', contains('result is already pending'));
      expect('$error', isNot(contains('tenant-user-42')));
      expect(toStringCalls, 0);

      routes.dispose();
      expect(await result, isNull);
    });
  });

  group('StrictHierarchy debug diagnostics', () {
    test('accepts an allowed direct child', () async {
      final routes = RoutesState<RouteNode>(const [
        TestRoute('initial'),
      ], (requested) => requested);
      addTearDown(routes.dispose);

      routes.setRoot([
        const _StrictShell([TestRoute('ok')]),
      ]);
      await routes.processingCompleted;

      expect(routes.root, [
        const _StrictShell([TestRoute('ok')]),
      ]);
    });

    test('reports a disallowed direct child with a debug assertion', () async {
      final routes = RoutesState<RouteNode>(const [
        TestRoute('initial'),
      ], (requested) => requested);
      addTearDown(routes.dispose);

      routes.setRoot([
        const _StrictShell([TestRoute('bad')]),
      ]);
      await expectLater(
        routes.processingCompleted,
        throwsA(
          isA<AssertionError>().having(
            (error) => '$error',
            'message',
            contains('does not allow child "bad"'),
          ),
        ),
      );

      expect(routes.root, const [TestRoute('initial')]);
    });
  });
}
