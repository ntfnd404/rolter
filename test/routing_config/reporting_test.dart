import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support.dart';

void main() {
  group('RoutingConfig route reporting', () {
    testWidgets('preserves parser BuildContext dependencies', (tester) async {
      final parser = DependencyParser();
      final provider = RecordingProvider('/home');
      final state = RoutesState<TestRoute>(
        const [TestRoute('home')],
        (requested) => requested,
      );
      final config = createTestConfig(
        state,
        parser: parser,
        provider: provider,
      );

      await tester.pumpWidget(
        ParserDependency(
          value: 'tenant-scope',
          child: MaterialApp.router(routerConfig: config),
        ),
      );
      await tester.pumpAndSettle();

      expect(parser.dependency, 'tenant-scope');

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    test(
      'preserves URI components and opaque RouteInformation.state',
      () async {
        final parser = StatePreservingParser();
        final stateToken = OpaqueRouteState();
        final state = RoutesState<TestRoute>(
          const [TestRoute('home')],
          (requested) => requested,
        );
        final config = createTestConfig(state, parser: parser);
        addTearDown(state.dispose);
        addTearDown(config.dispose);
        final input = RouteInformation(
          uri: Uri.parse('/detail?source=browser#part'),
          state: stateToken,
        );

        final parsed = await config.routeInformationParser
            .parseRouteInformation(input);
        await config.routerDelegate.setNewRoutePath(parsed);
        final restored = config.routeInformationParser.restoreRouteInformation(
          config.routerDelegate.currentConfiguration!,
        );

        expect(parser.lastInput, same(input));
        expect(parser.lastInput!.uri.queryParameters['source'], 'browser');
        expect(parser.lastInput!.uri.fragment, 'part');
        expect(restored!.uri.queryParameters['q'], '1');
        expect(restored.uri.fragment, 'section');
        expect(restored.state, same(stateToken));
        expect(stateToken.toStringCalls, 0);
      },
    );

    testWidgets('guard correction replaces the provider history entry', (
      tester,
    ) async {
      final provider = RecordingProvider('/home');
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) {
        if (requested.single.name == 'blocked') {
          return const [TestRoute('home')];
        }
        return requested;
      });
      final config = createTestConfig(state, provider: provider);

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();
      provider.reports.clear();

      provider.go(RouteInformation(uri: Uri(path: '/blocked')));
      await tester.pumpAndSettle();

      expect(state.root, const [TestRoute('home')]);
      expect(provider.reports, isNotEmpty);
      expect(
        provider.reports.last.type,
        RouteInformationReportingType.neglect,
      );
      expect(provider.reports.last.information.uri.path, '/home');

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    testWidgets(
      'a sealed framework commit cannot suppress a later app report',
      (tester) async {
        final releaseA = Completer<void>();
        final startedA = Completer<void>();
        final provider = RecordingProvider('/home');
        final state = RoutesState<TestRoute>(const [TestRoute('home')], (
          requested,
        ) async {
          if (requested.single.name == 'a') {
            startedA.complete();
            await releaseA.future;
          }
          return requested;
        });
        final config = createTestConfig(state, provider: provider);

        await tester.pumpWidget(MaterialApp.router(routerConfig: config));
        await tester.pumpAndSettle();
        provider.reports.clear();

        provider.go(RouteInformation(uri: Uri(path: '/a')));
        await tester.pump();
        await startedA.future;
        state.setRoot(const [TestRoute('x')]);
        releaseA.complete();
        await tester.pumpAndSettle();

        expect(state.root, const [TestRoute('x')]);
        expect(provider.reports, isNotEmpty);
        expect(provider.reports.last.information.uri.path, '/x');
        expect(
          provider.reports.last.type,
          RouteInformationReportingType.none,
        );

        await tester.pumpWidget(const SizedBox.shrink());
        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    testWidgets(
      'an app no-op replaces a superseded parser-only browser entry',
      (tester) async {
        final parser = ControlledParser();
        final provider = RecordingProvider('/home');
        final state = RoutesState<TestRoute>(
          const [TestRoute('home')],
          (requested) => requested,
        );
        final config = createTestConfig(
          state,
          parser: parser,
          provider: provider,
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: config));
        parser.pending['home']!.complete(const [TestRoute('home')]);
        await tester.pumpAndSettle();
        provider.reports.clear();

        provider.go(RouteInformation(uri: Uri(path: '/b')));
        await tester.pump();
        state.reevaluate();
        await state.processingCompleted;
        await tester.pumpAndSettle();

        expect(state.root, const [TestRoute('home')]);
        expect(provider.reports, isNotEmpty);
        expect(provider.reports.last.information.uri.path, '/home');
        expect(
          provider.reports.last.type,
          RouteInformationReportingType.neglect,
        );

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await tester.pumpAndSettle();

        expect(state.root, const [TestRoute('home')]);
        expect(provider.reports.last.information.uri.path, '/home');

        await tester.pumpWidget(const SizedBox.shrink());
        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    testWidgets(
      'a newer platform intent invalidates an older app correction',
      (tester) async {
        final parser = ControlledParser();
        final provider = RecordingProvider('/home');
        final releaseApp = Completer<void>();
        final appStarted = Completer<void>();
        var blockNextHome = false;
        final state = RoutesState<TestRoute>(const [TestRoute('home')], (
          requested,
        ) async {
          if (blockNextHome && requested.single.name == 'home') {
            blockNextHome = false;
            appStarted.complete();
            await releaseApp.future;
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
        provider.reports.clear();

        provider.go(RouteInformation(uri: Uri(path: '/b')));
        await tester.pump();
        blockNextHome = true;
        state.reevaluate();
        await appStarted.future;

        provider.go(RouteInformation(uri: Uri(path: '/c')));
        await tester.pump();
        releaseApp.complete();
        await state.processingCompleted;
        await tester.pump();

        expect(
          provider.reports.where(
            (report) =>
                report.information.uri.path == '/home' &&
                report.type == RouteInformationReportingType.neglect,
          ),
          isEmpty,
        );

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await tester.pump();
        parser.pending['c']!.complete(const [TestRoute('c')]);
        await tester.pumpAndSettle();

        expect(state.root, const [TestRoute('c')]);
        expect(find.text('c'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    testWidgets(
      'a real app route keeps normal reporting over parser-only work',
      (tester) async {
        final parser = ControlledParser();
        final provider = RecordingProvider('/home');
        final state = RoutesState<TestRoute>(
          const [TestRoute('home')],
          (requested) => requested,
        );
        final config = createTestConfig(
          state,
          parser: parser,
          provider: provider,
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: config));
        parser.pending['home']!.complete(const [TestRoute('home')]);
        await tester.pumpAndSettle();
        provider.reports.clear();

        provider.go(RouteInformation(uri: Uri(path: '/b')));
        await tester.pump();
        state.setRoot(const [TestRoute('x')]);
        await state.processingCompleted;
        await tester.pumpAndSettle();

        expect(state.root, const [TestRoute('x')]);
        expect(provider.reports.last.information.uri.path, '/x');
        expect(
          provider.reports.last.type,
          RouteInformationReportingType.none,
        );

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await tester.pumpAndSettle();
        expect(state.root, const [TestRoute('x')]);

        await tester.pumpWidget(const SizedBox.shrink());
        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    testWidgets(
      'an app failure replaces a superseded parser-only browser entry',
      (tester) async {
        final parser = ControlledParser();
        final provider = RecordingProvider('/home');
        final expected = StateError('app navigation failed');
        var fail = false;
        final state = RoutesState<TestRoute>(const [TestRoute('home')], (
          requested,
        ) {
          if (fail) {
            throw expected;
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
        provider.reports.clear();

        provider.go(RouteInformation(uri: Uri(path: '/b')));
        await tester.pump();
        fail = true;
        state.setRoot(const [TestRoute('x')]);
        await expectLater(state.processingCompleted, throwsA(same(expected)));
        await tester.pumpAndSettle();

        expect(state.root, const [TestRoute('home')]);
        expect(provider.reports.last.information.uri.path, '/home');
        expect(
          provider.reports.last.type,
          RouteInformationReportingType.neglect,
        );

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await tester.pumpAndSettle();
        expect(state.root, const [TestRoute('home')]);

        await tester.pumpWidget(const SizedBox.shrink());
        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    testWidgets(
      'fail-fast discard replaces a browser entry owned by the app entry',
      (tester) async {
        final parser = ControlledParser();
        final provider = RecordingProvider('/home');
        final releaseA = Completer<void>();
        final startedA = Completer<void>();
        final expected = StateError('earlier app navigation failed');
        final state = RoutesState<TestRoute>(const [TestRoute('home')], (
          requested,
        ) async {
          if (requested.single.name == 'a') {
            startedA.complete();
            await releaseA.future;
            throw expected;
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
        provider.reports.clear();

        state.setRoot(const [TestRoute('a')]);
        final drain = state.processingCompleted;
        await startedA.future;
        provider.go(RouteInformation(uri: Uri(path: '/b')));
        await tester.pump();
        state.setRoot(const [TestRoute('x')]);
        releaseA.complete();
        await expectLater(drain, throwsA(same(expected)));
        await tester.pumpAndSettle();

        expect(state.root, const [TestRoute('home')]);
        expect(provider.reports.last.information.uri.path, '/home');
        expect(
          provider.reports.last.type,
          RouteInformationReportingType.neglect,
        );

        parser.pending['b']!.complete(const [TestRoute('b')]);
        await tester.pumpAndSettle();
        expect(state.root, const [TestRoute('home')]);

        await tester.pumpWidget(const SizedBox.shrink());
        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    testWidgets('unhandled root Back replaces its superseded browser entry', (
      tester,
    ) async {
      final release = Completer<void>();
      final started = Completer<void>();
      final provider = RecordingProvider('/home');
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        if (requested.length == 1 && requested.single.name == 'a') {
          started.complete();
          await release.future;
        }
        return requested;
      });
      final config = createTestConfig(state, provider: provider);

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();
      provider.reports.clear();

      provider.go(RouteInformation(uri: Uri(path: '/a')));
      await tester.pump();
      await started.future;
      expect(await config.routerDelegate.popRoute(), isFalse);
      release.complete();
      await tester.pumpAndSettle();

      expect(provider.reports.last.information.uri.path, '/home');
      expect(
        provider.reports.last.type,
        RouteInformationReportingType.neglect,
      );

      expect(state.root, const [TestRoute('home')]);

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    testWidgets('handled root Back keeps normal app reporting semantics', (
      tester,
    ) async {
      final release = Completer<void>();
      final started = Completer<void>();
      final provider = RecordingProvider('/home');
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        if (requested.length == 1 && requested.single.name == 'a') {
          started.complete();
          await release.future;
        }
        return requested;
      });
      final config = createTestConfig(state, provider: provider);

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();
      state.setRoot(const [TestRoute('home'), TestRoute('detail')]);
      await state.processingCompleted;
      await tester.pumpAndSettle();
      provider.reports.clear();

      provider.go(RouteInformation(uri: Uri(path: '/a')));
      await tester.pump();
      await started.future;
      expect(await config.routerDelegate.popRoute(), isTrue);
      release.complete();
      await tester.pumpAndSettle();

      expect(state.root, const [TestRoute('home')]);
      expect(provider.reports.last.information.uri.path, '/home');
      expect(
        provider.reports.last.type,
        RouteInformationReportingType.none,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    testWidgets('latest parser failure resyncs a suppressed committed root', (
      tester,
    ) async {
      final parser = ControlledParser();
      final provider = RecordingProvider('/home');
      final releaseA = Completer<void>();
      final startedA = Completer<void>();
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        if (requested.single.name == 'a') {
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
      var openedB = false;
      final reported = <Object>[];
      final reportedOnce = Completer<void>();
      state.addListener(() {
        if (!openedB && state.top.name == 'a') {
          openedB = true;
          provider.go(RouteInformation(uri: Uri(path: '/b')));
        }
      });

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      parser.pending['home']!.complete(const [TestRoute('home')]);
      await tester.pumpAndSettle();
      provider.reports.clear();

      runZonedGuarded(
        () => provider.go(RouteInformation(uri: Uri(path: '/a'))),
        (error, stackTrace) {
          reported.add(error);
          if (!reportedOnce.isCompleted) {
            reportedOnce.complete();
          }
        },
      );
      await tester.pump();
      parser.pending['a']!.complete(const [TestRoute('a')]);
      await tester.pump();
      await startedA.future;
      releaseA.complete();
      await tester.pump();

      expect(state.root, const [TestRoute('a')]);
      expect(find.text('a'), findsNothing);
      expect(find.text('home'), findsOneWidget);
      expect(parser.pending, contains('b'));

      final expected = StateError('latest parser failed');
      parser.pending['b']!.completeError(expected, StackTrace.current);
      await tester.pump();
      await reportedOnce.future;
      await tester.pumpAndSettle();

      expect(reported, [same(expected)]);
      expect(find.text('a'), findsOneWidget);
      expect(provider.reports.last.information.uri.path, '/a');
      expect(
        provider.reports.last.type,
        RouteInformationReportingType.neglect,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    testWidgets('latest pipeline failure resyncs a suppressed committed root', (
      tester,
    ) async {
      final provider = RecordingProvider('/home');
      final releaseA = Completer<void>();
      final startedA = Completer<void>();
      final expected = StateError('latest pipeline failed');
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) async {
        switch (requested.single.name) {
          case 'a':
            if (!startedA.isCompleted) {
              startedA.complete();
            }
            await releaseA.future;
          case 'b':
            throw expected;
        }
        return requested;
      });
      final config = createTestConfig(state, provider: provider);
      var openedB = false;
      state.addListener(() {
        if (!openedB && state.top.name == 'a') {
          openedB = true;
          provider.go(RouteInformation(uri: Uri(path: '/b')));
        }
      });

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();
      provider.reports.clear();

      final reported = <Object>[];
      runZonedGuarded(
        () => provider.go(RouteInformation(uri: Uri(path: '/a'))),
        (error, stackTrace) => reported.add(error),
      );
      await tester.pump();
      await startedA.future;
      releaseA.complete();
      await tester.pumpAndSettle();

      expect(reported, [same(expected)]);
      expect(state.root, const [TestRoute('a')]);
      expect(find.text('a'), findsOneWidget);
      expect(provider.reports.last.information.uri.path, '/a');
      expect(
        provider.reports.last.type,
        RouteInformationReportingType.neglect,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    test('explicit navigate and neglect intentions pass through unchanged', () {
      final provider = RecordingProvider('/home');
      final state = RoutesState<TestRoute>(
        const [TestRoute('home')],
        (requested) => requested,
      );
      final config = createTestConfig(state, provider: provider);

      config.routeInformationProvider.routerReportsNewRouteInformation(
        RouteInformation(uri: Uri(path: '/a')),
        type: RouteInformationReportingType.navigate,
      );
      config.routeInformationProvider.routerReportsNewRouteInformation(
        RouteInformation(uri: Uri(path: '/b')),
        type: RouteInformationReportingType.neglect,
      );

      expect(provider.reports.map((report) => report.type), [
        RouteInformationReportingType.navigate,
        RouteInformationReportingType.neglect,
      ]);

      config.dispose();
      state.dispose();
      provider.dispose();
    });

    testWidgets('ordinary app navigation keeps default reporting semantics', (
      tester,
    ) async {
      final provider = RecordingProvider('/home');
      final state = RoutesState<TestRoute>(
        const [TestRoute('home')],
        (requested) => requested,
      );
      final config = createTestConfig(state, provider: provider);

      await tester.pumpWidget(MaterialApp.router(routerConfig: config));
      await tester.pumpAndSettle();
      provider.reports.clear();
      state.setRoot(const [TestRoute('detail')]);
      await state.processingCompleted;
      await tester.pumpAndSettle();

      expect(provider.reports.last.information.uri.path, '/detail');
      expect(
        provider.reports.last.type,
        RouteInformationReportingType.none,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });
  });
}
