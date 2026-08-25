import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support.dart';

void main() {
  group('RoutingConfig lifecycle', () {
    test('only one coordinated config may own a state at a time', () {
      final state = RoutesState<TestRoute>(
        const [TestRoute('home')],
        (requested) => requested,
      );
      final first = createTestConfig(state);

      expect(() => createTestConfig(state), throwsStateError);

      first.dispose();
      final second = createTestConfig(state);
      second.dispose();
      state.dispose();
    });

    test('constructor failure detaches the coordinator completely', () {
      final state = RoutesState<TestRoute>(
        const [TestRoute('home')],
        (requested) => requested,
      );
      final expected = StateError('provider listener failed');
      final provider = ThrowingListenerProvider(expected);

      expect(
        () => createTestConfig(
          state,
          provider: provider,
        ),
        throwsA(same(expected)),
      );
      expect(provider.listeners, isEmpty);

      final replacement = createTestConfig(state);
      replacement.dispose();
      state.dispose();
    });

    test('borrowed integration objects remain application-owned', () {
      final state = RoutesState<TestRoute>(
        const [TestRoute('home')],
        (requested) => requested,
      );
      final provider = RecordingProvider('/home');
      final dispatcher = RootBackButtonDispatcher();
      final config = RoutingConfig<TestRoute>(
        state: state,
        routeInformationParser: const TestParser(),
        routeInformationProvider: provider,
        backButtonDispatcher: dispatcher,
        pageBuilder: testPage,
      );

      expect(config.backButtonDispatcher, same(dispatcher));
      config.dispose();
      config.dispose();
      expect(provider.disposed, isFalse);

      provider.dispose();
      state.dispose();
    });
  });

  testWidgets('state-first teardown suppresses all late coordinated effects', (
    tester,
  ) async {
    final release = Completer<void>();
    final started = Completer<void>();
    final provider = RecordingProvider('/home');
    final state = RoutesState<TestRoute>(const [TestRoute('home')], (
      requested,
    ) async {
      if (!started.isCompleted) {
        started.complete();
      }
      await release.future;
      return requested;
    });
    final config = createTestConfig(state, provider: provider);

    await tester.pumpWidget(MaterialApp.router(routerConfig: config));
    await started.future;
    state.dispose();
    release.complete();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(tester.takeException(), isNull);
    config.dispose();
    provider.dispose();
  });

  testWidgets(
    'state-first teardown does not start later parser or Back work',
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

      state.dispose();
      provider.go(RouteInformation(uri: Uri(path: '/late')));
      await tester.pumpAndSettle();

      expect(parser.pending, isNot(contains('late')));
      expect(await config.routerDelegate.popRoute(), isFalse);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      provider.dispose();
    },
  );

  testWidgets('config-first teardown suppresses all late coordinated effects', (
    tester,
  ) async {
    final release = Completer<void>();
    final started = Completer<void>();
    final provider = RecordingProvider('/home');
    final state = RoutesState<TestRoute>(const [TestRoute('home')], (
      requested,
    ) async {
      if (!started.isCompleted) {
        started.complete();
      }
      await release.future;
      return requested;
    });
    final config = createTestConfig(state, provider: provider);

    await tester.pumpWidget(MaterialApp.router(routerConfig: config));
    await started.future;
    await tester.pumpWidget(const SizedBox.shrink());
    config.dispose();
    release.complete();
    await state.processingCompleted;
    await tester.pump();

    expect(state.root, const [TestRoute('home')]);
    expect(tester.takeException(), isNull);
    state.dispose();
    provider.dispose();
  });

  testWidgets('state disposal suppresses an already scheduled route report', (
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

    state.setRoot(const [TestRoute('x')]);
    await state.processingCompleted;
    state.dispose();
    await tester.pump();

    expect(provider.reports, isEmpty);
    expect(provider.disposed, isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    config.dispose();
    provider.dispose();
  });

  test('a disposed config suppresses direct late provider reports', () {
    final provider = RecordingProvider('/home');
    final state = RoutesState<TestRoute>(
      const [TestRoute('home')],
      (requested) => requested,
    );
    final config = createTestConfig(state, provider: provider);
    final adapter = config.routeInformationProvider;

    config.dispose();
    adapter.routerReportsNewRouteInformation(
      RouteInformation(uri: Uri(path: '/late')),
      type: RouteInformationReportingType.navigate,
    );

    expect(provider.reports, isEmpty);
    expect(provider.disposed, isFalse);

    state.dispose();
    provider.dispose();
  });
}
