import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support.dart';

void main() {
  group('RoutingConfig transactions', () {
    testWidgets(
      'async parser supersession prevents an intermediate root and widget',
      (tester) async {
        final parser = ControlledParser();
        final provider = RecordingProvider('/home');
        final releaseA = Completer<void>();
        final startedA = Completer<void>();
        final processed = <String>[];
        final state = RoutesState<TestRoute>(const [TestRoute('home')], (
          requested,
        ) async {
          final name = requested.single.name;
          processed.add(name);
          if (name == 'a') {
            if (!startedA.isCompleted) {
              startedA.complete();
            }
            await releaseA.future;
          }
          return requested;
        });
        final config = createTestConfig(
          state,
          parser: parser,
          provider: provider,
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: config));
        parser.pending['home']!.complete(const [TestRoute('home')]);
        await tester.pumpAndSettle();
        processed.clear();

        provider.go(RouteInformation(uri: Uri(path: '/a')));
        await tester.pump();
        parser.pending['a']!.complete(const [TestRoute('a')]);
        await tester.pump();
        await startedA.future;

        provider.go(RouteInformation(uri: Uri(path: '/b')));
        await tester.pump();
        releaseA.complete();
        await tester.pump();

        expect(state.root, const [TestRoute('home')]);
        expect(find.text('a'), findsNothing);
        expect(find.text('home'), findsOneWidget);

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await tester.pumpAndSettle();

        expect(processed.first, 'a');
        expect(processed.skip(1), isNotEmpty);
        expect(processed.skip(1), everyElement('b'));
        expect(state.root, const [TestRoute('b')]);
        expect(find.text('b'), findsOneWidget);
        expect(
          provider.reports.where(
            (report) => report.information.uri.path == '/a',
          ),
          isEmpty,
        );
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    test(
      'a newer parser request supersedes an older decoded request',
      () async {
        final parser = ControlledParser();
        final processed = <String>[];
        final state = RoutesState<TestRoute>(const [TestRoute('home')], (
          requested,
        ) {
          processed.add(requested.single.name);
          return requested;
        });
        final config = createTestConfig(state, parser: parser);
        addTearDown(state.dispose);
        addTearDown(config.dispose);

        final parsedA = config.routeInformationParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/a')),
        );
        final parsedB = config.routeInformationParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/b')),
        );
        parser.pending['a']!.complete(const [TestRoute('a')]);
        final staleA = await parsedA;
        await config.routerDelegate.setNewRoutePath(staleA);

        expect(processed, isEmpty);
        expect(state.root, const [TestRoute('home')]);

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await config.routerDelegate.setNewRoutePath(await parsedB);
        await state.processingCompleted;

        expect(processed, ['b']);
        expect(state.root, const [TestRoute('b')]);
      },
    );

    test('a superseded late parser error is abandoned', () async {
      final parser = ControlledParser();
      final state = RoutesState<TestRoute>(
        const [TestRoute('home')],
        (requested) => requested,
      );
      final config = createTestConfig(state, parser: parser);
      addTearDown(state.dispose);
      addTearDown(config.dispose);

      final parsedA = config.routeInformationParser.parseRouteInformation(
        RouteInformation(uri: Uri(path: '/a')),
      );
      unawaited(
        config.routeInformationParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/b')),
        ),
      );
      parser.pending['a']!.completeError(StateError('stale parser failure'));

      final abandoned = await parsedA;
      await config.routerDelegate.setNewRoutePath(abandoned);
      await state.processingCompleted;

      expect(state.root, const [TestRoute('home')]);
    });

    test('a live parser error preserves its object and stack', () async {
      final parser = ControlledParser();
      final state = RoutesState<TestRoute>(
        const [TestRoute('home')],
        (requested) => requested,
      );
      final config = createTestConfig(state, parser: parser);
      addTearDown(state.dispose);
      addTearDown(config.dispose);
      final expected = StateError('parser failed');
      final expectedStack = StackTrace.current;

      final parsed = config.routeInformationParser.parseRouteInformation(
        RouteInformation(uri: Uri(path: '/a')),
      );
      final captured = captureError(parsed);
      parser.pending['a']!.completeError(expected, expectedStack);
      final actual = await captured;

      expect(actual.error, same(expected));
      expect(actual.stackTrace.toString(), expectedStack.toString());
      expect(state.root, const [TestRoute('home')]);
    });

    test('a newer parser request abandons an active older pipeline', () async {
      final parser = ControlledParser();
      final releaseA = Completer<void>();
      final startedA = Completer<void>();
      final processed = <String>[];
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        final name = requested.single.name;
        processed.add(name);
        if (name == 'a') {
          startedA.complete();
          await releaseA.future;
        }
        return requested;
      });
      final config = createTestConfig(state, parser: parser);
      addTearDown(state.dispose);
      addTearDown(config.dispose);

      final parsedA = config.routeInformationParser.parseRouteInformation(
        RouteInformation(uri: Uri(path: '/a')),
      );
      parser.pending['a']!.complete(const [TestRoute('a')]);
      final requestA = config.routerDelegate.setNewRoutePath(await parsedA);
      await startedA.future;

      final parsedB = config.routeInformationParser.parseRouteInformation(
        RouteInformation(uri: Uri(path: '/b')),
      );
      releaseA.complete();
      await requestA;
      expect(state.root, const [TestRoute('home')]);

      parser.pending['b']!.complete(const [TestRoute('b')]);
      await config.routerDelegate.setNewRoutePath(await parsedB);
      await state.processingCompleted;

      expect(processed, ['a', 'b']);
      expect(state.root, const [TestRoute('b')]);
    });

    test('a superseded active pipeline error is abandoned', () async {
      final parser = ControlledParser();
      final releaseA = Completer<void>();
      final startedA = Completer<void>();
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        if (requested.single.name == 'a') {
          startedA.complete();
          await releaseA.future;
          throw StateError('stale pipeline failure');
        }
        return requested;
      });
      final config = createTestConfig(state, parser: parser);
      addTearDown(state.dispose);
      addTearDown(config.dispose);

      final parsedA = config.routeInformationParser.parseRouteInformation(
        RouteInformation(uri: Uri(path: '/a')),
      );
      parser.pending['a']!.complete(const [TestRoute('a')]);
      final requestA = config.routerDelegate.setNewRoutePath(await parsedA);
      await startedA.future;
      unawaited(
        config.routeInformationParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/b')),
        ),
      );
      releaseA.complete();

      await requestA;
      await state.processingCompleted;
      expect(state.root, const [TestRoute('home')]);
    });

    test('root Back supersedes an uncommitted framework request', () async {
      final release = Completer<void>();
      final started = Completer<void>();
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        started.complete();
        await release.future;
        return requested;
      });
      final config = createTestConfig(state);
      addTearDown(state.dispose);
      addTearDown(config.dispose);

      final parsed = await config.routeInformationParser.parseRouteInformation(
        RouteInformation(uri: Uri(path: '/a')),
      );
      final request = config.routerDelegate.setNewRoutePath(parsed);
      await started.future;
      expect(await config.routerDelegate.popRoute(), isFalse);
      release.complete();
      await request;
      await state.processingCompleted;

      expect(state.root, const [TestRoute('home')]);
    });

    testWidgets('nested Back keeps priority over root supersession', (
      tester,
    ) async {
      final release = Completer<void>();
      final started = Completer<void>();
      final provider = RecordingProvider('/home');
      final rootDispatcher = RootBackButtonDispatcher();
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        if (requested.single.name == 'a') {
          if (!started.isCompleted) {
            started.complete();
          }
          await release.future;
        }
        return requested;
      });
      final config = RoutingConfig<TestRoute>(
        state: state,
        routeInformationParser: const TestParser(),
        routeInformationProvider: provider,
        backButtonDispatcher: rootDispatcher,
        pageBuilder: testPage,
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();
      provider.go(RouteInformation(uri: Uri(path: '/a')));
      await tester.pump();
      await started.future;

      final child = rootDispatcher.createChildBackButtonDispatcher();
      Future<bool> handleNestedBack() => SynchronousFuture<bool>(true);
      child.addCallback(handleNestedBack);
      child.takePriority();
      expect(
        await rootDispatcher.invokeCallback(SynchronousFuture<bool>(false)),
        isTrue,
      );
      release.complete();
      await tester.pumpAndSettle();

      expect(state.root, const [TestRoute('a')]);
      expect(find.text('a'), findsOneWidget);

      child.removeCallback(handleNestedBack);
      rootDispatcher.forget(child);
      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    test(
      'app navigation seals an enqueued framework FIFO dependency',
      () async {
        final releaseA = Completer<void>();
        final startedA = Completer<void>();
        final processed = <List<String>>[];
        final state = RoutesState<TestRoute>(const [TestRoute('home')], (
          requested,
        ) async {
          processed.add(requested.map((route) => route.name).toList());
          if (requested.length == 1 && requested.single.name == 'a') {
            startedA.complete();
            await releaseA.future;
          }
          return requested;
        });
        final config = createTestConfig(state);
        addTearDown(state.dispose);
        addTearDown(config.dispose);

        final parsedA = await config.routeInformationParser
            .parseRouteInformation(
              RouteInformation(uri: Uri(path: '/a')),
            );
        final requestA = config.routerDelegate.setNewRoutePath(parsedA);
        await startedA.future;
        state.push(const TestRoute('x'));
        final parsedB = await config.routeInformationParser
            .parseRouteInformation(
              RouteInformation(uri: Uri(path: '/b')),
            );
        final requestB = config.routerDelegate.setNewRoutePath(parsedB);

        releaseA.complete();
        await requestA;
        await requestB;
        await state.processingCompleted;

        expect(processed, [
          ['a'],
          ['a', 'x'],
          ['b'],
        ]);
        expect(state.root, const [TestRoute('b')]);
      },
    );

    test(
      'app navigation invalidates parser-only work and avoids a stale base',
      () async {
        final parser = ControlledParser();
        final processed = <List<String>>[];
        final state = RoutesState<TestRoute>(const [TestRoute('home')], (
          requested,
        ) {
          processed.add(requested.map((route) => route.name).toList());
          return requested;
        });
        final config = createTestConfig(state, parser: parser);
        addTearDown(state.dispose);
        addTearDown(config.dispose);

        final parsedB = config.routeInformationParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/b')),
        );
        state.push(const TestRoute('x'));
        parser.pending['b']!.complete(const [TestRoute('b')]);
        await config.routerDelegate.setNewRoutePath(await parsedB);
        await state.processingCompleted;

        expect(processed, [
          ['home', 'x'],
        ]);
        expect(state.root, const [TestRoute('home'), TestRoute('x')]);
      },
    );

    test(
      'a throwing app transform does not supersede parser-only work',
      () async {
        final parser = ControlledParser();
        final state = RoutesState<TestRoute>(
          const [TestRoute('home')],
          (requested) => requested,
        );
        final config = createTestConfig(state, parser: parser);
        addTearDown(state.dispose);
        addTearDown(config.dispose);
        final expected = StateError('transform failed');

        final parsedB = config.routeInformationParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/b')),
        );

        expect(
          () => state.mutateAt(
            const ['home'],
            (_) => throw expected,
          ),
          throwsA(same(expected)),
        );

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await config.routerDelegate.setNewRoutePath(await parsedB);
        await state.processingCompleted;

        expect(state.root, const [TestRoute('b')]);
      },
    );

    test('throwing app predicates do not supersede parser-only work', () async {
      final mutations = <void Function(RoutesState<TestRoute>, Error)>[
        (state, expected) => state.popUntil((_) => throw expected),
        (state, expected) => state.removeWhere((_) => throw expected),
        (state, expected) => state.pushAndResetTo(
          const TestRoute('x'),
          (_) => throw expected,
        ),
      ];

      for (var index = 0; index < mutations.length; index++) {
        final parser = ControlledParser();
        final state = RoutesState<TestRoute>(
          const [TestRoute('home')],
          (requested) => requested,
        );
        final config = createTestConfig(state, parser: parser);
        final expected = StateError('predicate $index failed');
        final parsedB = config.routeInformationParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/b')),
        );

        expect(
          () => mutations[index](state, expected),
          throwsA(same(expected)),
        );

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await config.routerDelegate.setNewRoutePath(await parsedB);
        await state.processingCompleted;
        expect(state.root, const [TestRoute('b')]);

        config.dispose();
        state.dispose();
      }
    });

    test(
      'throwing app input and pageKey do not supersede parser work',
      () async {
        final operations = <void Function(RoutesState<TestRoute>, Error)>[
          (state, expected) => state.setRoot(ThrowingRouteList(expected)),
          (state, expected) => state.pushForResult<int>(
            TestRoute('result', pageKeyError: expected),
          ),
        ];

        for (var index = 0; index < operations.length; index++) {
          final parser = ControlledParser();
          final state = RoutesState<TestRoute>(
            const [TestRoute('home')],
            (requested) => requested,
          );
          final config = createTestConfig(state, parser: parser);
          final expected = StateError('input $index failed');
          final parsedB = config.routeInformationParser.parseRouteInformation(
            RouteInformation(uri: Uri(path: '/b')),
          );

          expect(
            () => operations[index](state, expected),
            throwsA(same(expected)),
          );

          parser.pending['b']!.complete(const [TestRoute('b')]);
          await config.routerDelegate.setNewRoutePath(await parsedB);
          await state.processingCompleted;
          expect(state.root, const [TestRoute('b')]);

          config.dispose();
          state.dispose();
        }
      },
    );

    test(
      'duplicate result registration does not supersede parser-only work',
      () async {
        final parser = ControlledParser();
        final state = RoutesState<TestRoute>(
          const [TestRoute('home')],
          (requested) => requested,
        );
        final config = createTestConfig(state, parser: parser);
        addTearDown(state.dispose);
        addTearDown(config.dispose);

        final first = state.pushForResult<int>(const TestRoute('picker'));
        await state.processingCompleted;
        final parsedB = config.routeInformationParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/b')),
        );

        expect(
          () => state.pushForResult<int>(const TestRoute('picker')),
          throwsA(isA<AssertionError>()),
        );

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await config.routerDelegate.setNewRoutePath(await parsedB);
        await state.processingCompleted;

        expect(state.root, const [TestRoute('b')]);
        expect(await first, isNull);
      },
    );

    test('root pop no-ops do not supersede parser-only work', () async {
      final parser = ControlledParser();
      final state = RoutesState<TestRoute>(
        const [TestRoute('home')],
        (requested) => requested,
      );
      final config = createTestConfig(state, parser: parser);
      addTearDown(state.dispose);
      addTearDown(config.dispose);

      final parsedB = config.routeInformationParser.parseRouteInformation(
        RouteInformation(uri: Uri(path: '/b')),
      );
      state.pop();
      state.popWith<int>(42);
      parser.pending['b']!.complete(const [TestRoute('b')]);
      await config.routerDelegate.setNewRoutePath(await parsedB);
      await state.processingCompleted;

      expect(state.root, const [TestRoute('b')]);
    });
  });
}
