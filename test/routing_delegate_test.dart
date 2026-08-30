import 'dart:async';

import 'package:flutter/foundation.dart';
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

Future<({Object error, StackTrace stackTrace})> _captureAsyncError(
  Future<void> future,
) async {
  try {
    await future;
  } on Object catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }
  fail('Expected the Future to fail.');
}

final class _TestRouteInformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  _TestRouteInformationProvider(String initialName)
    : _value = RouteInformation(uri: Uri(path: '/$initialName'));

  RouteInformation _value;

  @override
  RouteInformation get value => _value;

  void go(String name) {
    _value = RouteInformation(uri: Uri(path: '/$name'));
    notifyListeners();
  }
}

final class _TestRouteInformationParser
    extends RouteInformationParser<List<_Route>> {
  const _TestRouteInformationParser();

  @override
  Future<List<_Route>> parseRouteInformation(RouteInformation information) {
    final segments = information.uri.pathSegments;

    return SynchronousFuture<List<_Route>>([
      _Route(segments.isEmpty ? 'home' : segments.last),
    ]);
  }

  @override
  RouteInformation restoreRouteInformation(List<_Route> configuration) =>
      RouteInformation(uri: Uri(path: '/${configuration.single.name}'));
}

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

  test('rejects an empty committed root before a delegate can build it', () {
    expect(
      () => RoutesState<_Route>(const [], (requested) => requested),
      throwsA(isA<ArgumentError>()),
    );
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
    test(
      'new, initial, and restored paths settle after their pipeline',
      () async {
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
          addTearDown(state.dispose);
          addTearDown(delegate.dispose);
          var frameworkCompleted = false;
          var drainCompleted = false;
          List<_Route>? rootSeenByFrameworkCallback;

          final frameworkFuture = entry.value(
            delegate,
            const [_Route('detail')],
          );
          final drain = state.processingCompleted;
          unawaited(
            frameworkFuture.then((_) {
              frameworkCompleted = true;
              rootSeenByFrameworkCallback = state.root;
            }),
          );
          unawaited(
            drain.then((_) {
              drainCompleted = true;
            }),
          );
          await started.future;
          await Future<void>.delayed(Duration.zero);

          expect(frameworkCompleted, isFalse, reason: entry.key);
          expect(drainCompleted, isFalse, reason: entry.key);
          expect(state.root, const [_Route('home')], reason: entry.key);

          release.complete();
          await frameworkFuture;

          expect(frameworkCompleted, isTrue, reason: entry.key);
          expect(state.root, const [_Route('detail')], reason: entry.key);
          expect(
            rootSeenByFrameworkCallback,
            const [_Route('detail')],
            reason: entry.key,
          );
          await drain;
          expect(drainCompleted, isTrue, reason: entry.key);
        }
      },
    );

    test('overlapping paths receive independent request Futures', () async {
      final releaseFirst = Completer<void>();
      final releaseSecond = Completer<void>();
      final firstStarted = Completer<void>();
      final secondStarted = Completer<void>();
      final state = RoutesState<_Route>(const [_Route('home')], (
        requested,
      ) async {
        switch (requested.single.name) {
          case 'first':
            firstStarted.complete();
            await releaseFirst.future;
          case 'second':
            secondStarted.complete();
            await releaseSecond.future;
        }
        return requested;
      });
      final delegate = RoutingDelegate<_Route>(
        state,
        pageBuilder: _buildPage,
      );
      addTearDown(state.dispose);
      addTearDown(delegate.dispose);

      final first = delegate.setNewRoutePath(const [_Route('first')]);
      final second = delegate.setNewRoutePath(const [_Route('second')]);
      final drain = state.processingCompleted;
      var secondCompleted = false;
      unawaited(second.then((_) => secondCompleted = true));

      expect(identical(first, second), isFalse);
      await firstStarted.future;
      releaseFirst.complete();
      await first;

      expect(state.root, const [_Route('first')]);
      await secondStarted.future;
      await Future<void>.delayed(Duration.zero);
      expect(secondCompleted, isFalse);

      releaseSecond.complete();
      await second;
      expect(state.root, const [_Route('second')]);
      await drain;
    });

    test('a later request error cannot infect an earlier Future', () async {
      final releaseSecond = Completer<void>();
      final secondStarted = Completer<void>();
      final expected = StateError('second failed');
      final expectedStack = StackTrace.current;
      final state = RoutesState<_Route>(const [_Route('home')], (
        requested,
      ) async {
        if (requested.single.name == 'second') {
          secondStarted.complete();
          await releaseSecond.future;
          Error.throwWithStackTrace(expected, expectedStack);
        }
        return requested;
      });
      final delegate = RoutingDelegate<_Route>(
        state,
        pageBuilder: _buildPage,
      );
      addTearDown(state.dispose);
      addTearDown(delegate.dispose);

      final first = delegate.setNewRoutePath(const [_Route('first')]);
      final second = delegate.setNewRoutePath(const [_Route('second')]);
      final drain = state.processingCompleted;
      final capturedSecondError = _captureAsyncError(second);
      final drainError = expectLater(drain, throwsA(same(expected)));

      await first;
      expect(state.root, const [_Route('first')]);
      await secondStarted.future;
      releaseSecond.complete();
      final actual = await capturedSecondError;
      await drainError;

      expect(actual.error, same(expected));
      expect(actual.stackTrace.toString(), expectedStack.toString());
      expect(state.root, const [_Route('first')]);
    });

    test('an earlier failure rejects buffered framework requests', () async {
      final releaseFirst = Completer<void>();
      final firstStarted = Completer<void>();
      final expected = StateError('first failed');
      final expectedStack = StackTrace.current;
      final processed = <String>[];
      final state = RoutesState<_Route>(const [_Route('home')], (
        requested,
      ) async {
        final name = requested.single.name;
        processed.add(name);
        if (name == 'first') {
          firstStarted.complete();
          await releaseFirst.future;
          Error.throwWithStackTrace(expected, expectedStack);
        }
        return requested;
      });
      final delegate = RoutingDelegate<_Route>(
        state,
        pageBuilder: _buildPage,
      );
      addTearDown(state.dispose);
      addTearDown(delegate.dispose);

      final first = delegate.setNewRoutePath(const [_Route('first')]);
      final second = delegate.setNewRoutePath(const [_Route('second')]);
      final drain = state.processingCompleted;
      final capturedFirstError = _captureAsyncError(first);
      final capturedSecondError = _captureAsyncError(second);
      final drainError = expectLater(drain, throwsA(same(expected)));

      await firstStarted.future;
      releaseFirst.complete();
      final actualFirst = await capturedFirstError;
      final actualSecond = await capturedSecondError;
      await drainError;

      expect(actualFirst.error, same(expected));
      expect(actualSecond.error, same(expected));
      expect(actualFirst.stackTrace.toString(), expectedStack.toString());
      expect(actualSecond.stackTrace.toString(), expectedStack.toString());
      expect(processed, ['first']);
      expect(state.root, const [_Route('home')]);

      final recovery = delegate.setNewRoutePath(const [_Route('recovery')]);
      await recovery;
      await state.processingCompleted;
      expect(processed, ['first', 'recovery']);
      expect(state.root, const [_Route('recovery')]);
    });

    test('equivalent framework paths keep separate completions', () async {
      final releaseFirst = Completer<void>();
      final firstStarted = Completer<void>();
      var calls = 0;
      final state = RoutesState<_Route>(const [_Route('home')], (
        requested,
      ) async {
        calls++;
        if (calls == 1) {
          firstStarted.complete();
          await releaseFirst.future;
        }
        return requested;
      });
      final delegate = RoutingDelegate<_Route>(
        state,
        pageBuilder: _buildPage,
      );
      addTearDown(state.dispose);
      addTearDown(delegate.dispose);

      final first = delegate.setNewRoutePath(const [_Route('same')]);
      final second = delegate.setNewRoutePath(const [_Route('same')]);
      var secondCompleted = false;
      unawaited(second.then((_) => secondCompleted = true));

      await firstStarted.future;
      releaseFirst.complete();
      await first;
      expect(secondCompleted, isFalse);

      await second;
      await state.processingCompleted;
      expect(calls, 2);
      expect(state.root, const [_Route('same')]);
    });

    test(
      'low-level delegate reports FIFO commits without supersession policy',
      () async {
        final releaseFirst = Completer<void>();
        final releaseSecond = Completer<void>();
        final firstStarted = Completer<void>();
        final secondStarted = Completer<void>();
        final expected = StateError('latest failed');
        final state = RoutesState<_Route>(const [_Route('home')], (
          requested,
        ) async {
          switch (requested.single.name) {
            case 'first':
              firstStarted.complete();
              await releaseFirst.future;
            case 'second':
              secondStarted.complete();
              await releaseSecond.future;
              throw expected;
          }
          return requested;
        });
        final delegate = RoutingDelegate<_Route>(
          state,
          pageBuilder: _buildPage,
        );
        addTearDown(state.dispose);
        addTearDown(delegate.dispose);
        final notifiedRoots = <List<_Route>>[];
        delegate.addListener(() => notifiedRoots.add(state.root));

        final first = delegate.setNewRoutePath(const [_Route('first')]);
        final second = delegate.setNewRoutePath(const [_Route('second')]);
        final drain = state.processingCompleted;
        final secondError = expectLater(second, throwsA(same(expected)));
        final drainError = expectLater(drain, throwsA(same(expected)));

        await firstStarted.future;
        releaseFirst.complete();
        await first;
        await secondStarted.future;
        await Future<void>.delayed(Duration.zero);

        expect(state.root, const [_Route('first')]);
        expect(notifiedRoots, [
          const [_Route('first')],
        ]);

        releaseSecond.complete();
        await secondError;
        await drainError;
        await Future<void>.delayed(Duration.zero);

        expect(notifiedRoots, [
          const [_Route('first')],
        ]);
      },
    );

    test(
      'application navigation remains ordered between framework paths',
      () async {
        final releaseFirst = Completer<void>();
        final firstStarted = Completer<void>();
        final processed = <List<String>>[];
        final state = RoutesState<_Route>(const [_Route('home')], (
          requested,
        ) async {
          processed.add(requested.map((route) => route.name).toList());
          if (requested.length == 1 && requested.single.name == 'first') {
            firstStarted.complete();
            await releaseFirst.future;
          }
          return requested;
        });
        final delegate = RoutingDelegate<_Route>(
          state,
          pageBuilder: _buildPage,
        );
        addTearDown(state.dispose);
        addTearDown(delegate.dispose);
        final notifiedRoots = <List<_Route>>[];
        delegate.addListener(() => notifiedRoots.add(state.root));

        final first = delegate.setNewRoutePath(const [_Route('first')]);
        state.push(const _Route('application'));
        final second = delegate.setNewRoutePath(const [_Route('second')]);
        final drain = state.processingCompleted;

        await firstStarted.future;
        releaseFirst.complete();
        await first;
        await second;
        await drain;
        await Future<void>.delayed(Duration.zero);

        expect(processed, [
          ['first'],
          ['first', 'application'],
          ['second'],
        ]);
        expect(
          notifiedRoots.map(
            (root) => root.map((route) => route.name).toList(),
          ),
          contains(equals(['first', 'application'])),
        );
        expect(notifiedRoots.last, const [_Route('second')]);
        expect(state.root, const [_Route('second')]);
      },
    );

    for (final lateFailure in <bool>[false, true]) {
      test(
        'state-first disposal abandons tracked framework '
        '${lateFailure ? 'error' : 'success'}',
        () async {
          final release = Completer<void>();
          final started = Completer<void>();
          var pipelineCalls = 0;
          final state = RoutesState<_Route>(const [_Route('home')], (
            requested,
          ) async {
            pipelineCalls++;
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
          addTearDown(delegate.dispose);
          var delegateNotifications = 0;
          delegate.addListener(() => delegateNotifications++);

          final active = delegate.setNewRoutePath(
            const [_Route('active')],
          );
          final queued = delegate.setNewRoutePath(
            const [_Route('queued')],
          );
          final drain = state.processingCompleted;
          await started.future;
          state.dispose();
          release.complete();

          await active;
          await queued;
          await drain;
          await Future<void>.delayed(Duration.zero);

          expect(state.root, const [_Route('home')]);
          expect(pipelineCalls, 1);
          expect(delegateNotifications, 0);
        },
      );
    }

    testWidgets(
      'rapid Router provider updates stay ordered and settle on latest path',
      (tester) async {
        final releaseFirst = Completer<void>();
        final releaseSecond = Completer<void>();
        final firstStarted = Completer<void>();
        final secondStarted = Completer<void>();
        final processed = <String>[];
        final state = RoutesState<_Route>(const [_Route('home')], (
          requested,
        ) async {
          final name = requested.single.name;
          if (name != 'home') {
            processed.add(name);
          }
          if (name == 'first') {
            firstStarted.complete();
            await releaseFirst.future;
          } else if (name == 'second') {
            if (!secondStarted.isCompleted) {
              secondStarted.complete();
            }
            await releaseSecond.future;
          }
          return requested;
        });
        final delegate = RoutingDelegate<_Route>(
          state,
          pageBuilder: _buildPage,
        );
        final provider = _TestRouteInformationProvider('home');

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: const _TestRouteInformationParser(),
            routeInformationProvider: provider,
          ),
        );
        await tester.pumpAndSettle();

        provider.go('first');
        await tester.pump();
        await firstStarted.future;
        provider.go('second');
        await tester.pump();

        expect(processed, ['first']);

        releaseFirst.complete();
        await secondStarted.future;
        await tester.pump();

        expect(state.root, const [_Route('first')]);
        expect(find.text('first'), findsNothing);
        expect(find.text('home'), findsOneWidget);

        releaseSecond.complete();
        await tester.pumpAndSettle();

        // Flutter versions may reapply the newest provider value after an
        // earlier asynchronous route update finishes. Every accepted request
        // must still remain FIFO, and all work after `first` must target the
        // latest value.
        expect(processed.first, 'first');
        expect(processed.skip(1), isNotEmpty);
        expect(processed.skip(1), everyElement('second'));
        expect(state.root, const [_Route('second')]);
        expect(find.text('second'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        delegate.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    testWidgets('Router reports one live framework request error', (
      tester,
    ) async {
      final release = Completer<void>();
      final started = Completer<void>();
      final expected = StateError('framework pipeline failed');
      final state = RoutesState<_Route>(const [_Route('home')], (
        requested,
      ) async {
        if (requested.single.name == 'failed') {
          started.complete();
          await release.future;
          throw expected;
        }
        return requested;
      });
      final delegate = RoutingDelegate<_Route>(
        state,
        pageBuilder: _buildPage,
      );
      final provider = _TestRouteInformationProvider('home');
      final reported = <Object>[];
      final reportedOnce = Completer<void>();

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: delegate,
          routeInformationParser: const _TestRouteInformationParser(),
          routeInformationProvider: provider,
        ),
      );
      await tester.pumpAndSettle();

      runZonedGuarded(
        () => provider.go('failed'),
        (error, stackTrace) {
          reported.add(error);
          if (!reportedOnce.isCompleted) {
            reportedOnce.complete();
          }
        },
      );
      await tester.pump();
      await started.future;
      release.complete();
      await tester.pump();
      await reportedOnce.future;

      await tester.pump();
      expect(reported, hasLength(1));
      expect(reported.single, same(expected));
      expect(state.root, const [_Route('home')]);

      await tester.pumpWidget(const SizedBox.shrink());
      delegate.dispose();
      state.dispose();
      provider.dispose();
    });

    for (final lateFailure in <bool>[false, true]) {
      testWidgets(
        'Router unmount abandons pending framework '
        '${lateFailure ? 'error' : 'success'}',
        (tester) async {
          final release = Completer<void>();
          final started = Completer<void>();
          final state = RoutesState<_Route>(const [_Route('home')], (
            requested,
          ) async {
            if (requested.single.name == 'detail') {
              started.complete();
              await release.future;
              if (lateFailure) {
                throw StateError('late failure');
              }
            }
            return requested;
          });
          final delegate = RoutingDelegate<_Route>(
            state,
            pageBuilder: _buildPage,
          );
          final provider = _TestRouteInformationProvider('home');

          await tester.pumpWidget(
            MaterialApp.router(
              routerDelegate: delegate,
              routeInformationParser: const _TestRouteInformationParser(),
              routeInformationProvider: provider,
            ),
          );
          await tester.pumpAndSettle();

          provider.go('detail');
          await tester.pump();
          await started.future;
          await tester.pumpWidget(const SizedBox.shrink());

          delegate.dispose();
          state.dispose();
          release.complete();
          await tester.pump();
          await tester.pump();

          expect(state.root, const [_Route('home')]);
          expect(tester.takeException(), isNull);
          provider.dispose();
        },
      );
    }
  });
}
