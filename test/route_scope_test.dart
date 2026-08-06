import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';

final class _Resource {
  _Resource(this.onDispose);

  final VoidCallback onDispose;

  void dispose() => onDispose();
}

final class _ScopeRoute with KeyedRouteEquality {
  const _ScopeRoute(this.name);

  @override
  final String name;

  @override
  List<RouteNode> get children => const [];

  @override
  LocalKey get pageKey => ValueKey<String>(name);

  @override
  Map<String, String> toParams() => const {};

  @override
  RouteNode withChildren(List<RouteNode> children) => this;
}

void main() {
  testWidgets('RouteScope, not a rebuilding composer, owns disposal', (
    tester,
  ) async {
    var compositionBuilds = 0;
    var resourcesCreated = 0;
    var resourcesDisposed = 0;
    var replacementDisposerCalls = 0;
    var useReplacementDisposer = false;
    late StateSetter rebuild;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          compositionBuilds++;

          return RouteScope<_Resource>(
            create: () {
              resourcesCreated++;
              return _Resource(() => resourcesDisposed++);
            },
            dispose: useReplacementDisposer
                ? (_) => replacementDisposerCalls++
                : (resource) => resource.dispose(),
            child: Builder(
              builder: (context) {
                RouteScope.of<_Resource>(context);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );

    rebuild(() => useReplacementDisposer = true);
    await tester.pump();

    expect(compositionBuilds, 2);
    expect(resourcesCreated, 1);
    expect(resourcesDisposed, 0);

    await tester.pumpWidget(const SizedBox());

    expect(resourcesDisposed, 1);
    expect(replacementDisposerCalls, 0);
  });

  testWidgets('changing the widget key replaces and disposes the resource', (
    tester,
  ) async {
    var identity = 1;
    var created = 0;
    var disposed = 0;
    late StateSetter rebuild;

    await tester.pumpWidget(
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return RouteScope<_Resource>(
            key: ValueKey<int>(identity),
            create: () {
              created++;
              return _Resource(() => disposed++);
            },
            dispose: (resource) => resource.dispose(),
            child: const SizedBox(),
          );
        },
      ),
    );

    rebuild(() => identity = 2);
    await tester.pump();

    expect(created, 2);
    expect(disposed, 1);

    await tester.pumpWidget(const SizedBox());
    expect(disposed, 2);
  });

  testWidgets('failed creation never invokes the disposer', (tester) async {
    var disposerCalls = 0;

    await tester.pumpWidget(
      RouteScope<_Resource>(
        create: () => throw StateError('creation failed'),
        dispose: (_) => disposerCalls++,
        child: const SizedBox(),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
    await tester.pumpWidget(const SizedBox());
    expect(disposerCalls, 0);
  });

  testWidgets('Navigator page removal disposes the resource exactly once', (
    tester,
  ) async {
    var created = 0;
    var disposed = 0;
    final state = RoutesState<_ScopeRoute>(
      const [_ScopeRoute('home')],
      (requested) => requested,
    );
    addTearDown(state.dispose);
    final controller = NavigationController<_ScopeRoute>(state);
    final delegate = RoutingDelegate<_ScopeRoute>(
      state,
      pageBuilder: (context, route) => MaterialPage<Object?>(
        key: route.pageKey,
        child: route.name == 'resource'
            ? RouteScope<_Resource>(
                create: () {
                  created++;
                  return _Resource(() => disposed++);
                },
                dispose: (resource) => resource.dispose(),
                child: const Text('resource-page'),
              )
            : const Text('home-page'),
      ),
    );
    addTearDown(delegate.dispose);

    await tester.pumpWidget(MaterialApp.router(routerDelegate: delegate));
    controller.push(const _ScopeRoute('resource'));
    await state.processingCompleted;
    await tester.pumpAndSettle();

    expect(created, 1);
    expect(disposed, 0);

    controller.pop();
    await state.processingCompleted;
    await tester.pumpAndSettle();

    expect(find.text('resource-page'), findsNothing);
    expect(disposed, 1);
  });
}
