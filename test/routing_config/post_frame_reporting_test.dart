import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

import 'support.dart';

void main() {
  group('RoutingConfig post-frame reporting', () {
    testWidgets('a newer platform intent suppresses a prepared app report', (
      tester,
    ) async {
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

      state.setRoot(const [TestRoute('x')]);
      await state.processingCompleted;
      provider.go(RouteInformation(uri: Uri(path: '/b')));
      await tester.pump();

      expect(provider.value.uri.path, '/b');
      expect(provider.reports, isEmpty);

      parser.pending['b']!.complete(const [TestRoute('b')]);
      await tester.pumpAndSettle();

      expect(state.root, const [TestRoute('b')]);
      expect(provider.reports, hasLength(1));
      expect(provider.reports.single.information.uri.path, '/b');
      expect(
        provider.reports.single.type,
        RouteInformationReportingType.none,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    testWidgets('a pending initial deep link does not report the old root', (
      tester,
    ) async {
      final parser = ControlledParser();
      final provider = RecordingProvider('/deep');
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

      expect(state.root, const [TestRoute('home')]);
      expect(provider.value.uri.path, '/deep');
      expect(provider.reports, isEmpty);

      parser.pending['deep']!.complete(const [TestRoute('deep')]);
      await tester.pumpAndSettle();

      expect(state.root, const [TestRoute('deep')]);
      expect(provider.reports, hasLength(1));
      expect(provider.reports.single.information.uri.path, '/deep');
      expect(
        provider.reports.single.type,
        RouteInformationReportingType.none,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    testWidgets('current app navigate and neglect intentions are preserved', (
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

      Router.navigate(tester.element(find.text('home')), () {
        state.setRoot(const [TestRoute('x')]);
      });
      await state.processingCompleted;
      await tester.pumpAndSettle();

      expect(provider.reports, hasLength(1));
      expect(provider.reports.single.information.uri.path, '/x');
      expect(
        provider.reports.single.type,
        RouteInformationReportingType.navigate,
      );

      provider.reports.clear();
      Router.neglect(tester.element(find.text('x')), () {
        state.setRoot(const [TestRoute('y')]);
      });
      await state.processingCompleted;
      await tester.pumpAndSettle();

      expect(provider.reports, hasLength(1));
      expect(provider.reports.single.information.uri.path, '/y');
      expect(
        provider.reports.single.type,
        RouteInformationReportingType.neglect,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    testWidgets('a framework route does not inherit stale app navigate', (
      tester,
    ) async {
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

      Router.navigate(tester.element(find.text('home')), () {
        state.setRoot(const [TestRoute('x')]);
      });
      await state.processingCompleted;
      provider.go(RouteInformation(uri: Uri(path: '/b')));
      parser.pending['b']!.complete(const [TestRoute('b')]);
      await tester.idle();
      await tester.pumpAndSettle();

      expect(state.root, const [TestRoute('b')]);
      expect(provider.reports, hasLength(1));
      expect(provider.reports.single.information.uri.path, '/b');
      expect(
        provider.reports.single.type,
        RouteInformationReportingType.none,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    testWidgets('a correction does not inherit stale app navigate', (
      tester,
    ) async {
      final parser = ControlledParser();
      final provider = RecordingProvider('/home');
      final state = RoutesState<TestRoute>(const [TestRoute('home')], (
        requested,
      ) {
        if (requested.single.name == 'b') {
          return const [TestRoute('x')];
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

      Router.navigate(tester.element(find.text('home')), () {
        state.setRoot(const [TestRoute('x')]);
      });
      await state.processingCompleted;
      provider.go(RouteInformation(uri: Uri(path: '/b')));
      parser.pending['b']!.complete(const [TestRoute('b')]);
      await tester.idle();
      await tester.pumpAndSettle();

      expect(state.root, const [TestRoute('x')]);
      expect(provider.reports, hasLength(1));
      expect(provider.reports.single.information.uri.path, '/x');
      expect(
        provider.reports.single.type,
        RouteInformationReportingType.neglect,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      config.dispose();
      state.dispose();
      provider.dispose();
    });

    test(
      'a mismatched report does not consume a prepared correction',
      () async {
        final provider = RecordingProvider('/home');
        final state = RoutesState<TestRoute>(
          const [TestRoute('home')],
          (requested) => requested.single.name == 'blocked'
              ? const [TestRoute('home')]
              : requested,
        );
        final config = createTestConfig(state, provider: provider);
        final parsed = await config.routeInformationParser
            .parseRouteInformation(
              RouteInformation(uri: Uri(path: '/blocked')),
            );
        await config.routerDelegate.setNewRoutePath(parsed);
        final expected = config.routeInformationParser.restoreRouteInformation(
          config.routerDelegate.currentConfiguration!,
        )!;
        final unrelated = RouteInformation(uri: Uri(path: '/unrelated'));

        config.routeInformationProvider.routerReportsNewRouteInformation(
          unrelated,
          type: RouteInformationReportingType.navigate,
        );
        config.routeInformationProvider.routerReportsNewRouteInformation(
          expected,
        );

        expect(provider.reports, hasLength(2));
        expect(provider.reports.first.information, same(unrelated));
        expect(
          provider.reports.first.type,
          RouteInformationReportingType.navigate,
        );
        expect(provider.reports.last.information, same(expected));
        expect(
          provider.reports.last.type,
          RouteInformationReportingType.neglect,
        );

        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    test(
      'a newer parser transaction suppresses an exact stale report',
      () async {
        final parser = _RecordingParser();
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
        final current = config.routeInformationParser.restoreRouteInformation(
          config.routerDelegate.currentConfiguration!,
        )!;

        final pending = config.routeInformationParser.parseRouteInformation(
          RouteInformation(uri: Uri(path: '/b')),
        );
        config.routeInformationProvider.routerReportsNewRouteInformation(
          current,
          type: RouteInformationReportingType.navigate,
        );

        expect(provider.reports, isEmpty);
        expect((await pending), isNotNull);

        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );

    test(
      'the latest prepared presentation owns the single report slot',
      () async {
        final parser = _RecordingParser();
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
        config.routeInformationParser.restoreRouteInformation(
          config.routerDelegate.currentConfiguration!,
        );
        state.setRoot(const [TestRoute('x')]);
        await state.processingCompleted;
        final latest = config.routeInformationParser.restoreRouteInformation(
          config.routerDelegate.currentConfiguration!,
        )!;

        config.routeInformationProvider.routerReportsNewRouteInformation(
          latest,
        );

        expect(provider.reports, hasLength(1));
        expect(provider.reports.single.information, same(latest));
        expect(provider.reports.single.information.uri.path, '/x');
        expect(
          provider.reports.single.type,
          RouteInformationReportingType.none,
        );

        config.dispose();
        state.dispose();
        provider.dispose();
      },
    );
  });
}

final class _RecordingParser extends RouteInformationParser<List<TestRoute>> {
  @override
  Future<List<TestRoute>> parseRouteInformation(RouteInformation information) =>
      SynchronousFuture<List<TestRoute>>(<TestRoute>[
        TestRoute(information.uri.pathSegments.last),
      ]);

  @override
  RouteInformation restoreRouteInformation(List<TestRoute> configuration) =>
      RouteInformation(uri: Uri(path: '/${configuration.last.name}'));
}
