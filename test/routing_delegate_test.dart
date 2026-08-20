import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

@immutable
final class _Route implements RouteNode {
  const _Route(this.name);

  @override
  final String name;

  @override
  List<RouteNode> get children => const [];

  @override
  LocalKey get pageKey => ValueKey(name);

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is _Route && other.name == name;
}

final class _Dependency {
  const _Dependency([this.label = 'dependency']);

  final String label;
}

final class _DependencyView extends StatelessWidget {
  const _DependencyView(this.dependency);

  final _Dependency dependency;

  @override
  Widget build(BuildContext context) => const SizedBox();
}

final class _DependencyScope extends InheritedWidget {
  const _DependencyScope({required this.dependency, required super.child});

  final _Dependency dependency;

  static _Dependency of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_DependencyScope>();
    if (scope == null) {
      throw StateError('Dependency scope is unavailable.');
    }

    return scope.dependency;
  }

  @override
  bool updateShouldNotify(_DependencyScope oldWidget) =>
      !identical(dependency, oldWidget.dependency);
}

Page<Object?> _buildPage(BuildContext context, _Route route) =>
    MaterialPage<Object?>(key: route.pageKey, child: Text(route.name));

void main() {
  testWidgets('builds root pages in order from exact route instances', (
    tester,
  ) async {
    const home = _Route('home');
    const detail = _Route('detail');
    final built = <_Route>[];
    final state = RoutesState<_Route>(const [
      home,
      detail,
    ], (requested) => requested);
    addTearDown(state.dispose);
    final delegate = RoutingDelegate<_Route>(
      state,
      pageBuilder: (context, route) {
        built.add(route);

        return MaterialPage<Object?>(
          key: route.pageKey,
          child: Text(route.name),
        );
      },
    );
    addTearDown(delegate.dispose);

    await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));

    expect(built, [same(home), same(detail)]);
    expect(find.text('detail'), findsOneWidget);

    built.clear();
    state.setRoot(const [home]);
    await state.processingCompleted;
    await tester.pumpAndSettle();

    expect(built, [same(home)]);
    expect(find.text('detail'), findsNothing);
  });

  testWidgets('does not call the builder for an empty root stack', (
    tester,
  ) async {
    var calls = 0;
    final state = RoutesState<_Route>(const [], (requested) => requested);
    addTearDown(state.dispose);
    final delegate = RoutingDelegate<_Route>(
      state,
      pageBuilder: (context, route) {
        calls++;

        return MaterialPage<Object?>(
          key: route.pageKey,
          child: const Text('x'),
        );
      },
    );
    addTearDown(delegate.dispose);

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          final navigator = delegate.build(context) as Navigator;
          expect(navigator.pages, isEmpty);

          return const SizedBox();
        },
      ),
    );

    expect(calls, 0);
  });

  testWidgets('preserves constructor-captured dependency identity', (
    tester,
  ) async {
    const dependency = _Dependency();
    final state = RoutesState<_Route>(const [
      _Route('home'),
    ], (requested) => requested);
    addTearDown(state.dispose);
    final delegate = RoutingDelegate<_Route>(
      state,
      pageBuilder: (context, route) => MaterialPage<Object?>(
        key: route.pageKey,
        child: const _DependencyView(dependency),
      ),
    );
    addTearDown(delegate.dispose);

    await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));

    final view = tester.widget<_DependencyView>(find.byType(_DependencyView));
    expect(view.dependency, same(dependency));
  });

  testWidgets('builder can read a scope placed above MaterialApp.router', (
    tester,
  ) async {
    const dependency = _Dependency();
    final state = RoutesState<_Route>(const [
      _Route('home'),
    ], (requested) => requested);
    addTearDown(state.dispose);
    final delegate = RoutingDelegate<_Route>(
      state,
      pageBuilder: (context, route) => MaterialPage<Object?>(
        key: route.pageKey,
        child: _DependencyView(_DependencyScope.of(context)),
      ),
    );
    addTearDown(delegate.dispose);

    await tester.pumpWidget(
      _DependencyScope(
        dependency: dependency,
        child: MaterialApp.router(routerDelegate: delegate),
      ),
    );

    final view = tester.widget<_DependencyView>(find.byType(_DependencyView));
    expect(view.dependency, same(dependency));
  });

  testWidgets('scope replacement rebuilds composition without route changes', (
    tester,
  ) async {
    const first = _Dependency('first');
    const second = _Dependency('second');
    var builderCalls = 0;
    final state = RoutesState<_Route>(const [
      _Route('home'),
    ], (requested) => requested);
    addTearDown(state.dispose);
    final delegate = RoutingDelegate<_Route>(
      state,
      pageBuilder: (context, route) {
        builderCalls++;
        return MaterialPage<Object?>(
          key: route.pageKey,
          child: _DependencyView(_DependencyScope.of(context)),
        );
      },
    );
    addTearDown(delegate.dispose);

    Widget app(_Dependency dependency) => _DependencyScope(
      dependency: dependency,
      child: MaterialApp.router(routerDelegate: delegate),
    );

    await tester.pumpWidget(app(first));
    expect(
      tester.widget<_DependencyView>(find.byType(_DependencyView)).dependency,
      same(first),
    );
    final callsBeforeReplacement = builderCalls;

    await tester.pumpWidget(app(second));

    expect(builderCalls, greaterThan(callsBeforeReplacement));
    expect(
      tester.widget<_DependencyView>(find.byType(_DependencyView)).dependency,
      same(second),
    );
    expect(state.root, const [_Route('home')]);
  });

  testWidgets('app builder scope is visible to page builder and page child', (
    tester,
  ) async {
    const dependency = _Dependency();
    late _Dependency builderDependency;
    final state = RoutesState<_Route>(const [
      _Route('home'),
    ], (requested) => requested);
    addTearDown(state.dispose);
    final delegate = RoutingDelegate<_Route>(
      state,
      pageBuilder: (context, route) {
        builderDependency = _DependencyScope.of(context);
        return MaterialPage<Object?>(
          key: route.pageKey,
          child: Builder(
            builder: (context) => _DependencyView(_DependencyScope.of(context)),
          ),
        );
      },
    );
    addTearDown(delegate.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerDelegate: delegate,
        builder: (context, child) =>
            _DependencyScope(dependency: dependency, child: child!),
      ),
    );

    final view = tester.widget<_DependencyView>(find.byType(_DependencyView));
    expect(builderDependency, same(dependency));
    expect(view.dependency, same(dependency));
  });

  testWidgets('accepts a distinct page key that compares equal', (
    tester,
  ) async {
    final state = RoutesState<_Route>(const [
      _Route('home'),
    ], (requested) => requested);
    addTearDown(state.dispose);
    final delegate = RoutingDelegate<_Route>(
      state,
      pageBuilder: (context, route) => MaterialPage<Object?>(
        key: ValueKey<String>(route.name),
        child: const SizedBox(),
      ),
    );
    addTearDown(delegate.dispose);

    await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));

    expect(tester.takeException(), isNull);
  });

  testWidgets('rejects a missing or mismatched page key without route data', (
    tester,
  ) async {
    final state = RoutesState<_Route>(const [
      _Route('private-id'),
    ], (requested) => requested);
    addTearDown(state.dispose);

    for (final key in <LocalKey?>[null, const ValueKey('wrong')]) {
      final delegate = RoutingDelegate<_Route>(
        state,
        pageBuilder: (context, route) =>
            MaterialPage<Object?>(key: key, child: const SizedBox()),
      );
      addTearDown(delegate.dispose);
      late StateError error;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            try {
              delegate.build(context);
            } on StateError catch (caught) {
              error = caught;
            }

            return const SizedBox();
          },
        ),
      );

      expect(error.message, contains('does not match RouteNode.pageKey'));
      expect(error.message, isNot(contains('private-id')));
      expect(error.message, isNot(contains('wrong')));
    }
  });

  testWidgets('does not wrap builder exceptions', (tester) async {
    final expected = StateError('builder failure');
    final expectedStack = StackTrace.current;
    final state = RoutesState<_Route>(const [
      _Route('home'),
    ], (requested) => requested);
    addTearDown(state.dispose);
    final delegate = RoutingDelegate<_Route>(
      state,
      pageBuilder: (context, route) =>
          Error.throwWithStackTrace(expected, expectedStack),
    );
    addTearDown(delegate.dispose);
    late Object actual;
    late StackTrace actualStack;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          try {
            delegate.build(context);
          } on Object catch (caught, stack) {
            actual = caught;
            actualStack = stack;
          }

          return const SizedBox();
        },
      ),
    );

    expect(actual, same(expected));
    expect(actualStack.toString(), expectedStack.toString());
  });

  group('Router Future contract', () {
    test('new, initial, and restored paths wait for their pipeline', () async {
      for (final entry
          in <
                String,
                Future<void> Function(RoutingDelegate<_Route>, List<_Route>)
              >{
                'new': (delegate, routes) => delegate.setNewRoutePath(routes),
                'initial': (delegate, routes) =>
                    delegate.setInitialRoutePath(routes),
                'restored': (delegate, routes) =>
                    delegate.setRestoredRoutePath(routes),
              }
              .entries) {
        final release = Completer<void>();
        final started = Completer<void>();
        final state = RoutesState<_Route>(const [_Route('home')], (
          requested,
        ) async {
          started.complete();
          await release.future;
          return requested;
        });
        final delegate = RoutingDelegate<_Route>(
          state,
          pageBuilder: _buildPage,
        );
        var completed = false;

        final future = entry.value(delegate, const [_Route('detail')]);
        unawaited(
          future.then((_) {
            completed = true;
          }),
        );
        await started.future;
        await Future<void>.delayed(Duration.zero);

        expect(completed, isFalse, reason: entry.key);
        expect(state.root, const [_Route('home')], reason: entry.key);

        release.complete();
        await future;

        expect(completed, isTrue, reason: entry.key);
        expect(state.root, const [_Route('detail')], reason: entry.key);
        delegate.dispose();
        state.dispose();
      }
    });

    test('multiple calls share one FIFO drain', () async {
      final releaseFirst = Completer<void>();
      final firstStarted = Completer<void>();
      final processed = <String>[];
      final state = RoutesState<_Route>(const [_Route('home')], (
        requested,
      ) async {
        processed.add(requested.single.name);
        if (processed.length == 1) {
          firstStarted.complete();
          await releaseFirst.future;
        }
        return requested;
      });
      addTearDown(state.dispose);
      final delegate = RoutingDelegate<_Route>(state, pageBuilder: _buildPage);
      addTearDown(delegate.dispose);

      final first = delegate.setNewRoutePath(const [_Route('first')]);
      final second = delegate.setNewRoutePath(const [_Route('second')]);

      expect(identical(first, second), isTrue);
      await firstStarted.future;
      expect(processed, ['first']);

      releaseFirst.complete();
      await Future.wait([first, second]);

      expect(processed, ['first', 'second']);
      expect(state.root, const [_Route('second')]);
    });

    test('propagates live failure identity and stack, then recovers', () async {
      final release = Completer<void>();
      final started = Completer<void>();
      final expected = StateError('route policy failed');
      final expectedStack = StackTrace.current;
      var shouldFail = true;
      final state = RoutesState<_Route>(const [_Route('home')], (
        requested,
      ) async {
        if (shouldFail) {
          started.complete();
          await release.future;
          Error.throwWithStackTrace(expected, expectedStack);
        }
        return requested;
      });
      addTearDown(state.dispose);
      final delegate = RoutingDelegate<_Route>(state, pageBuilder: _buildPage);
      addTearDown(delegate.dispose);

      final failed = delegate.setNewRoutePath(const [_Route('rejected')]);
      final discarded = delegate.setNewRoutePath(const [_Route('dependent')]);
      expect(identical(failed, discarded), isTrue);
      await started.future;
      release.complete();

      late Object actual;
      late StackTrace actualStack;
      try {
        await failed;
      } on Object catch (error, stack) {
        actual = error;
        actualStack = stack;
      }

      expect(actual, same(expected));
      expect(actualStack.toString(), expectedStack.toString());
      expect(state.root, const [_Route('home')]);

      shouldFail = false;
      await delegate.setNewRoutePath(const [_Route('recovered')]);
      expect(state.root, const [_Route('recovered')]);
    });

    for (final lateFailure in <bool>[false, true]) {
      testWidgets(
        'Router unmount abandons pending ${lateFailure ? 'error' : 'success'}',
        (tester) async {
          final release = Completer<void>();
          final started = Completer<void>();
          final state = RoutesState<_Route>(const [_Route('home')], (
            requested,
          ) async {
            started.complete();
            await release.future;
            if (lateFailure) {
              throw StateError('late failure');
            }
            return requested;
          });
          final delegate = RoutingDelegate<_Route>(
            state,
            pageBuilder: _buildPage,
          );

          await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));
          final future = delegate.setNewRoutePath(const [_Route('detail')]);
          await started.future;
          await tester.pumpWidget(const SizedBox.shrink());

          delegate.dispose();
          state.dispose();
          release.complete();
          await future;
          await tester.pump();

          expect(state.root, const [_Route('home')]);
          expect(tester.takeException(), isNull);
        },
      );
    }
  });
}
